class VisorConfig {
  final bool ok;
  final int esLink; // 1 = URLs, 0 = Base64
  final int tiempoEspera;
  final int tiempoAds;
  final List<String> _imageList;
  final int totalSlotCount; // Total slots found in server JSON (empty or not)

  // Default fallback images
  static const List<String> defaultImages = [
    'assets/promo1.png',
    'assets/promo2.png',
    'assets/promo3.png',
  ];

  VisorConfig({
    required this.ok,
    required this.esLink,
    required this.tiempoEspera,
    required this.tiempoAds,
    List<String>? imageList,
    this.totalSlotCount = 0,
  }) : _imageList = imageList ?? [];

  factory VisorConfig.fromJson(Map<String, dynamic> json) {
    // Extract images from img1, img2, img3, etc. (backward compatible)
    final imageList = <String>[];
    int totalSlots = 0;

    // Support both numbered fields (img1, img2, img3...) and array
    if (json['images'] is List) {
      final list = json['images'] as List;
      totalSlots = list.length;
      for (final img in list) {
        if (img is String && img.isNotEmpty) {
          imageList.add(img);
        }
      }
    } else {
      // Legacy format: img1, img2, img3...
      for (int i = 1; i <= 12; i++) {
        final imgKey = 'img$i';
        if (json.containsKey(imgKey)) {
          totalSlots = i; // Track highest slot found
          final img = json[imgKey] as String?;
          if (img != null && img.isNotEmpty) {
            imageList.add(img);
          }
        }
      }
    }

    return VisorConfig(
      ok: json['ok'] ?? false,
      esLink: json['es_link'] ?? 0,
      tiempoEspera: json['tiempo_espera'] ?? 60,
      tiempoAds: json['tiempo_ads'] ?? 5,
      imageList: imageList,
      totalSlotCount: totalSlots,
    );
  }

  /// Returns only non-empty images, or defaults if none
  List<String> get images {
    if (_imageList.isEmpty) {
      return defaultImages;
    }
    return _imageList;
  }

  /// Returns true if images are URLs (esLink=1), false if Base64
  bool get imagesAreUrls => esLink == 1;

  /// Check if using default images
  bool get hasCustomImages => _imageList.isNotEmpty;

  /// Get only the raw image data (URLs or Base64) without fallbacks
  List<String> get rawImages => _imageList;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'ok': ok,
      'es_link': esLink,
      'tiempo_espera': tiempoEspera,
      'tiempo_ads': tiempoAds,
    };

    // Store as array for efficiency
    if (_imageList.isNotEmpty) {
      json['images'] = _imageList;
    }

    return json;
  }

  /// Create config with only metadata (images stored separately)
  Map<String, dynamic> toJsonWithoutImages() {
    return {
      'ok': ok,
      'es_link': esLink,
      'tiempo_espera': tiempoEspera,
      'tiempo_ads': tiempoAds,
      'image_count': _imageList.length,
    };
  }

  /// Create a copy with cached image paths
  VisorConfig copyWithCachedPaths(List<String> cachedPaths) {
    return VisorConfig(
      ok: ok,
      esLink: 1, // Cached paths are always "links" to local files
      tiempoEspera: tiempoEspera,
      tiempoAds: tiempoAds,
      imageList: cachedPaths,
      totalSlotCount: totalSlotCount,
    );
  }
}
