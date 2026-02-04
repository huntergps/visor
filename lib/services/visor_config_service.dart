import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/visor_config.dart';
import 'app_config_service.dart';
import 'http_client_service.dart';
import 'image_cache_service.dart';

class VisorConfigService {
  static final VisorConfigService _instance = VisorConfigService._internal();
  factory VisorConfigService() => _instance;
  VisorConfigService._internal();

  late SharedPreferences _prefs;

  // Keys - store config metadata separately from image references
  static const String _keyConfigMeta = 'visor_config_meta';
  static const String _keyCachedImageRefs = 'visor_cached_image_refs';

  // In-memory cache for quick access
  VisorConfig? _cachedConfig;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Fetch config from server, pre-cache images, and save
  Future<VisorConfig> fetchAndSaveConfig() async {
    final appConfig = AppConfigService();

    final protocol = appConfig.protocol;
    final host = appConfig.host;
    final apiKey = appConfig.apiKey;

    final url = '$protocol://$host/api/erp_dat/v1/_process/visor_conf';

    final response = await HttpClientService().client.get(
      url,
      queryParameters: {'api_key': apiKey},
      options: Options(responseType: ResponseType.plain),
    );

    if (response.statusCode == 200) {
      final responseStr = response.data?.toString() ?? '';

      // Validate response is JSON before parsing
      final trimmed = responseStr.trim();
      if (trimmed.isEmpty || !trimmed.startsWith('{')) {
        throw Exception('Respuesta no válida del servidor: ${trimmed.length > 100 ? '${trimmed.substring(0, 100)}...' : trimmed}');
      }

      final Map<String, dynamic> jsonMap = Map<String, dynamic>.from(
          const JsonDecoder().convert(trimmed) as Map);
      final config = VisorConfig.fromJson(jsonMap);

      // Validate 'ok' flag
      if (!config.ok) {
        throw Exception('API returned ok=false');
      }

      // Save metadata (without heavy base64 data) to SharedPreferences
      final metaJson = const JsonEncoder().convert(config.toJsonWithoutImages());
      await _prefs.setString(_keyConfigMeta, metaJson);

      // Sync timing settings to AppConfigService
      await AppConfigService().setAdsDuration(config.tiempoAds);
      if (config.tiempoEspera > 0) {
        await AppConfigService().setIdleTimeout(config.tiempoEspera);
      }

      // Pre-cache images in background and save references
      if (config.hasCustomImages) {
        final cachedRefs = await _preCacheAndSaveRefs(config.rawImages);

        // Create config with cached references
        final cachedConfig = config.copyWithCachedPaths(cachedRefs);
        _cachedConfig = cachedConfig;

        return cachedConfig;
      }

      _cachedConfig = config;
      return config;
    } else {
      throw Exception('Failed to load config: ${response.statusCode}');
    }
  }

  /// Pre-cache images and save source references for later retrieval
  Future<List<String>> _preCacheAndSaveRefs(List<String> imageSources) async {
    final imageService = ImageCacheService();

    // Pre-cache all images
    final cachedSources = await imageService.preCacheImages(imageSources);

    // For base64 images, we can't store them in SharedPreferences (too large)
    // Instead, store a marker that indicates cached images exist
    // CachedImage will retrieve them by regenerating the cache key from source

    // For URLs: store the URLs directly (small)
    // For base64: store placeholder that CachedImage can use to find cached file
    final refsToStore = <String>[];
    for (final source in cachedSources) {
      if (source.startsWith('assets/')) {
        refsToStore.add(source);
      } else if (source.startsWith('http')) {
        // URLs are small, store directly
        refsToStore.add(source);
      } else {
        // Base64 - store cache key prefixed with marker
        final key = imageService.generateKey(source);
        refsToStore.add('cached:$key');
      }
    }

    await _prefs.setStringList(_keyCachedImageRefs, refsToStore);
    debugPrint('VisorConfigService: Saved ${refsToStore.length} image references');

    return cachedSources;
  }

  /// Get cached config (fast, from memory or SharedPreferences)
  VisorConfig getConfig() {
    // Return memory cache if available
    if (_cachedConfig != null) {
      return _cachedConfig!;
    }

    // Try to load from SharedPreferences
    final metaJson = _prefs.getString(_keyConfigMeta);
    final imageRefs = _prefs.getStringList(_keyCachedImageRefs);

    if (metaJson != null && metaJson.isNotEmpty) {
      try {
        final Map<String, dynamic> jsonMap = json.decode(metaJson);

        // Reconstruct config with cached image references
        final config = VisorConfig(
          ok: jsonMap['ok'] ?? false,
          esLink: 1, // Cached images are always "links"
          tiempoEspera: jsonMap['tiempo_espera'] ?? AppConfigService().idleTimeout,
          tiempoAds: jsonMap['tiempo_ads'] ?? 5,
          imageList: imageRefs,
        );

        _cachedConfig = config;
        return config;
      } catch (e) {
        debugPrint('VisorConfigService: Error loading cached config: $e');
      }
    }

    // Return default config if nothing cached
    return VisorConfig(
      ok: false,
      esLink: 0,
      tiempoEspera: AppConfigService().idleTimeout,
      tiempoAds: 5,
    );
  }

  /// Clear cached config (force reload on next getConfig)
  void clearCache() {
    _cachedConfig = null;
  }

  /// Check if images are pre-cached and ready (parallel checks)
  Future<bool> areImagesCached() async {
    final imageRefs = _prefs.getStringList(_keyCachedImageRefs);
    if (imageRefs == null || imageRefs.isEmpty) {
      return false;
    }

    final imageService = ImageCacheService();
    final futures = imageRefs
        .where((ref) => !ref.startsWith('assets/'))
        .map((ref) => imageService.isCached(ref));

    final results = await Future.wait(futures);
    return results.every((cached) => cached);
  }
}
