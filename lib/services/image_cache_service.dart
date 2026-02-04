import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'http_client_service.dart';

/// Service for caching images locally to avoid repeated downloads.
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  String? _cacheDir;

  // Cache configuration
  static const int _maxCacheFiles = 50;
  static const Duration _cacheTTL = Duration(hours: 24);

  // In-flight request deduplication
  final Map<String, Future<Uint8List?>> _inFlightFetches = {};
  final Map<String, Future<Uint8List?>> _inFlightBase64 = {};

  /// Initialize cache directory
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _cacheDir = '${dir.path}/image_cache';
    final cacheFolder = Directory(_cacheDir!);
    if (!await cacheFolder.exists()) {
      await cacheFolder.create(recursive: true);
    }
    // Run cleanup in background
    _cleanupOldFiles();
  }

  /// Remove expired files and enforce size limit (single-pass)
  Future<void> _cleanupOldFiles() async {
    if (_cacheDir == null) return;

    try {
      final cacheFolder = Directory(_cacheDir!);
      if (!await cacheFolder.exists()) return;

      final files = await cacheFolder.list().toList();
      final now = DateTime.now();
      final surviving = <_FileWithTime>[];

      // Single pass: delete expired, collect survivors with stat
      for (final entity in files) {
        if (entity is File) {
          final stat = await entity.stat();
          final age = now.difference(stat.modified);

          if (age > _cacheTTL) {
            await entity.delete();
          } else {
            surviving.add(_FileWithTime(entity, stat.modified));
          }
        }
      }

      // LRU eviction if still over limit
      if (surviving.length > _maxCacheFiles) {
        surviving.sort((a, b) => a.modified.compareTo(b.modified));
        final toRemove = surviving.length - _maxCacheFiles;
        for (var i = 0; i < toRemove; i++) {
          await surviving[i].file.delete();
        }
      }
    } catch (e) {
      debugPrint('Cache cleanup error: $e');
    }
  }

  /// Generate MD5 hash key from source string (URL or base64)
  String generateKey(String source) {
    final bytes = utf8.encode(source);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Get cached image bytes by key, respecting TTL
  Future<Uint8List?> getCachedImage(String key, {bool ignoreTTL = false}) async {
    if (_cacheDir == null) await init();

    final file = File('$_cacheDir/$key');
    if (await file.exists()) {
      // Check TTL unless ignored (for pre-cached ads that should persist)
      if (!ignoreTTL) {
        final stat = await file.stat();
        final age = DateTime.now().difference(stat.modified);
        if (age > _cacheTTL) {
          // Expired, delete and return null
          await file.delete();
          return null;
        }
      }
      // Update modification time to mark as recently used (LRU)
      await file.setLastModified(DateTime.now());
      return await file.readAsBytes();
    }
    return null;
  }

  /// Save image bytes to cache
  Future<void> cacheImage(String key, Uint8List bytes) async {
    if (_cacheDir == null) await init();

    final file = File('$_cacheDir/$key');
    await file.writeAsBytes(bytes);
  }

  /// Fetch image from URL, cache it, and return bytes.
  /// Deduplicates concurrent requests for the same URL.
  Future<Uint8List?> fetchAndCache(String url) async {
    final inFlight = _inFlightFetches[url];
    if (inFlight != null) return inFlight;

    final future = _downloadAndCache(url);
    _inFlightFetches[url] = future;
    try {
      return await future;
    } finally {
      _inFlightFetches.remove(url);
    }
  }

  /// Internal download logic
  Future<Uint8List?> _downloadAndCache(String url) async {
    final key = generateKey(url);

    // Check cache first
    final cached = await getCachedImage(key);
    if (cached != null) {
      return cached;
    }

    // Download and cache using Dio
    try {
      final response = await HttpClientService().client.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode == 200 && response.data != null) {
        final bytes = Uint8List.fromList(response.data!);
        await cacheImage(key, bytes);
        return bytes;
      }
    } catch (e) {
      // Silent failure, return null
    }
    return null;
  }

  /// Cache and retrieve base64 image (useful to avoid repeated decoding).
  /// Deduplicates concurrent decoding of the same base64 string.
  Future<Uint8List?> cacheBase64(String base64String) async {
    String cleanBase64 = base64String;
    if (cleanBase64.contains(',')) {
      cleanBase64 = cleanBase64.split(',').last;
    }

    if (cleanBase64.isEmpty) return null;

    final key = generateKey(cleanBase64);

    final inFlight = _inFlightBase64[key];
    if (inFlight != null) return inFlight;

    final future = _decodeAndCache(cleanBase64, key);
    _inFlightBase64[key] = future;
    try {
      return await future;
    } finally {
      _inFlightBase64.remove(key);
    }
  }

  /// Internal base64 decode logic — decodes in a separate isolate
  Future<Uint8List?> _decodeAndCache(String cleanBase64, String key) async {
    // Check cache first
    final cached = await getCachedImage(key);
    if (cached != null) {
      return cached;
    }

    // Decode in separate isolate to avoid blocking UI thread
    try {
      final bytes = await compute(_decodeBase64Isolate, cleanBase64);
      await cacheImage(key, bytes);
      return bytes;
    } catch (e) {
      return null;
    }
  }

  /// Clear all cached images
  Future<void> clearCache() async {
    if (_cacheDir == null) return;

    final cacheFolder = Directory(_cacheDir!);
    if (await cacheFolder.exists()) {
      await cacheFolder.delete(recursive: true);
      await cacheFolder.create(recursive: true);
    }
  }

  /// Pre-cache multiple images in parallel (for ads)
  /// Returns list of successfully cached sources
  Future<List<String>> preCacheImages(List<String> sources) async {
    if (_cacheDir == null) await init();

    final results = <String>[];

    // Process in parallel with limit
    final futures = <Future<String?>>[];

    for (final source in sources) {
      if (source.isEmpty || source.startsWith('assets/')) {
        // Skip empty or asset paths
        results.add(source);
        continue;
      }

      futures.add(_preCacheSingle(source));
    }

    final cached = await Future.wait(futures);
    for (final result in cached) {
      if (result != null) {
        results.add(result);
      }
    }

    debugPrint('ImageCacheService: Pre-cached ${results.length}/${sources.length} images');
    return results;
  }

  /// Pre-cache a single image, returns source if successful
  Future<String?> _preCacheSingle(String source) async {
    try {
      if (source.startsWith('http')) {
        final bytes = await fetchAndCache(source);
        return bytes != null ? source : null;
      } else if (source.length > 100 || source.startsWith('data:image')) {
        final bytes = await cacheBase64(source);
        return bytes != null ? source : null;
      }
      return null;
    } catch (e) {
      debugPrint('Failed to pre-cache: $source');
      return null;
    }
  }

  /// Check if an image is already cached (by hashed source)
  Future<bool> isCached(String source) async {
    if (_cacheDir == null) await init();
    if (source.isEmpty || source.startsWith('assets/')) return true;

    final key = generateKey(source);
    final file = File('$_cacheDir/$key');
    return await file.exists();
  }

  /// Check if an image is cached by direct key (without hashing).
  /// Used for product images that are stored with product_BARCODE keys.
  Future<bool> isCachedByKey(String key) async {
    if (_cacheDir == null) await init();
    if (key.isEmpty) return false;

    final file = File('$_cacheDir/$key');
    if (!await file.exists()) return false;

    // Verify TTL
    final stat = await file.stat();
    final age = DateTime.now().difference(stat.modified);
    return age <= _cacheTTL;
  }

  /// Get stored version/timestamp for a cached image
  Future<String?> getCachedVersion(String key) async {
    if (_cacheDir == null) await init();
    if (key.isEmpty) return null;

    final metaFile = File('$_cacheDir/$key.meta');
    if (await metaFile.exists()) {
      return await metaFile.readAsString();
    }
    return null;
  }

  /// Save version/timestamp metadata for a cached image
  Future<void> saveVersion(String key, String version) async {
    if (_cacheDir == null) await init();
    if (key.isEmpty || version.isEmpty) return;

    final metaFile = File('$_cacheDir/$key.meta');
    await metaFile.writeAsString(version);
  }

  /// Check if cached image version matches the provided version.
  /// Returns true if image is cached AND version matches (no re-download needed).
  /// Returns false if not cached or version differs (need to download).
  Future<bool> isVersionValid(String key, String? serverVersion) async {
    if (_cacheDir == null) await init();
    if (key.isEmpty) return false;

    // Check if image file exists
    final file = File('$_cacheDir/$key');
    if (!await file.exists()) return false;

    // If server doesn't send version, fall back to TTL check
    if (serverVersion == null || serverVersion.isEmpty) {
      final stat = await file.stat();
      final age = DateTime.now().difference(stat.modified);
      return age <= _cacheTTL;
    }

    // Compare versions
    final cachedVersion = await getCachedVersion(key);
    return cachedVersion == serverVersion;
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    if (_cacheDir == null) await init();

    final cacheFolder = Directory(_cacheDir!);
    if (!await cacheFolder.exists()) {
      return {'files': 0, 'sizeBytes': 0};
    }

    int fileCount = 0;
    int totalSize = 0;

    await for (final entity in cacheFolder.list()) {
      if (entity is File) {
        fileCount++;
        final stat = await entity.stat();
        totalSize += stat.size;
      }
    }

    return {
      'files': fileCount,
      'sizeBytes': totalSize,
      'sizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
    };
  }
}

/// Top-level function for isolate-based base64 decoding
Uint8List _decodeBase64Isolate(String base64String) {
  return base64Decode(base64String);
}

/// Helper class for LRU sorting
class _FileWithTime {
  final File file;
  final DateTime modified;

  _FileWithTime(this.file, this.modified);
}
