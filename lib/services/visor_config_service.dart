import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/visor_config.dart';
import 'app_config_service.dart';
import 'http_client_service.dart';
import 'image_cache_service.dart';

/// Result record from fetchAndSaveConfig with diagnostic info
typedef FetchConfigResult = ({VisorConfig config, int totalSlots, int validImages});

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

  // Image groups: 4 groups of 3 images each (1-3, 4-6, 7-9, 10-12)
  static const int _totalGroups = 4;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Fetch config from server in batches, pre-cache images, and save.
  /// [onProgress] is called with (currentGroup, totalGroups) for UI updates.
  Future<FetchConfigResult> fetchAndSaveConfig({
    void Function(int currentGroup, int totalGroups)? onProgress,
  }) async {
    final appConfig = AppConfigService();

    final protocol = appConfig.protocol;
    final host = appConfig.host;
    final apiKey = appConfig.apiKey;

    if (host.isEmpty) {
      debugPrint('VisorConfigService: Host no configurado. Configure el servidor en ajustes.');
      final c = getConfig();
      return (config: c, totalSlots: 0, validImages: c.rawImages.length);
    }

    final url = '$protocol://$host/api/erp_dat/v1/_process/visor_conf';

    // Fetch groups sequentially to avoid timeouts with large base64 images
    VisorConfig? baseConfig;
    final allImages = <String>[];
    int totalSlots = 0;

    for (int grupo = 1; grupo <= _totalGroups; grupo++) {
      onProgress?.call(grupo, _totalGroups);
      debugPrint('VisorConfigService: Fetching grupo $grupo/$_totalGroups...');

      final response = await HttpClientService().client.get(
        url,
        queryParameters: {
          'api_key': apiKey,
          'param[grupo]': grupo,
        },
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load config grupo $grupo: ${response.statusCode}');
      }

      final responseStr = response.data?.toString() ?? '';
      final trimmed = responseStr.trim();
      if (trimmed.isEmpty || !trimmed.startsWith('{')) {
        throw Exception('Respuesta no válida del servidor (grupo $grupo)');
      }

      final Map<String, dynamic> jsonMap = Map<String, dynamic>.from(
          const JsonDecoder().convert(trimmed) as Map);

      // Log keys only on first group for diagnostics
      if (grupo == 1) {
        debugPrint('VisorConfigService: JSON keys: ${jsonMap.keys.toList()}');
      }

      // Parse this group's config
      final groupConfig = VisorConfig.fromJson(jsonMap);

      // Use first group as base for non-image settings
      baseConfig ??= groupConfig;

      // Collect images and slot count from this group
      allImages.addAll(groupConfig.rawImages);
      totalSlots += groupConfig.totalSlotCount;

      // Log this group's images
      for (int i = 1; i <= 12; i++) {
        final key = 'img$i';
        if (jsonMap.containsKey(key)) {
          final val = jsonMap[key];
          debugPrint('VisorConfigService: $key = ${val is String ? "${val.length} chars" : val.runtimeType}');
        }
      }

      debugPrint('VisorConfigService: Grupo $grupo: ${groupConfig.rawImages.length} images');
    }

    if (baseConfig == null) {
      throw Exception('No config received from server');
    }

    // Validate 'ok' flag
    if (!baseConfig.ok) {
      throw Exception('API returned ok=false');
    }

    // Build merged config with all images
    final config = VisorConfig(
      ok: baseConfig.ok,
      esLink: baseConfig.esLink,
      tiempoEspera: baseConfig.tiempoEspera,
      tiempoAds: baseConfig.tiempoAds,
      imageList: allImages,
      totalSlotCount: totalSlots,
    );

    debugPrint('VisorConfigService: Total parsed ${config.rawImages.length}/$totalSlots images');

    // Save metadata (without heavy base64 data) to SharedPreferences
    final metaJson = const JsonEncoder().convert(config.toJsonWithoutImages());
    await _prefs.setString(_keyConfigMeta, metaJson);

    // Sync timing settings to AppConfigService
    await AppConfigService().setAdsDuration(config.tiempoAds);
    if (config.tiempoEspera > 0) {
      await AppConfigService().setIdleTimeout(config.tiempoEspera);
    }

    final validImages = config.rawImages.length;

    // Pre-cache images and save references
    if (config.hasCustomImages) {
      onProgress?.call(_totalGroups, _totalGroups); // Signal caching phase
      final cachedRefs = await _preCacheAndSaveRefs(config.rawImages);

      // Create config with cached references
      final cachedConfig = config.copyWithCachedPaths(cachedRefs);
      _cachedConfig = cachedConfig;

      return (config: cachedConfig, totalSlots: totalSlots, validImages: validImages);
    }

    _cachedConfig = config;
    return (config: config, totalSlots: totalSlots, validImages: validImages);
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
