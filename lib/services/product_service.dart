import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/discount.dart';
import 'app_config_service.dart';
import 'http_client_service.dart';
import 'image_cache_service.dart';
import '../models/product.dart';
import '../models/presentation_price.dart';

/// Result of fetching a product: contains the product data immediately
/// and an optional pending Future for background image caching.
class ProductResult {
  final Product product;
  final Future<String?>? pendingImage;

  ProductResult(this.product, {this.pendingImage});
}

class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  // Pre-compiled RegExp patterns for JSON cleanup
  static final RegExp _trailingCommaInObject = RegExp(r',\s*}');
  static final RegExp _trailingCommaInArray = RegExp(r',\s*]');

  // Prefix for product image cache keys
  static const String _imageKeyPrefix = 'product_';

  // In-flight request deduplication
  final Map<String, Future<ProductResult?>> _inFlightRequests = {};

  // Reference to image cache service
  final ImageCacheService _imageCache = ImageCacheService();

  /// Fetches product data by barcode.
  /// Returns product data immediately; image loads in background if not cached.
  /// Deduplicates concurrent requests for the same barcode.
  /// Returns null if not found or error.
  Future<ProductResult?> getProductByBarcode(String barcode) async {
    final normalizedBarcode = barcode.toUpperCase().trim();

    // Deduplicate: if already fetching this barcode, reuse the Future
    final inFlight = _inFlightRequests[normalizedBarcode];
    if (inFlight != null) {
      return inFlight;
    }

    final future = _fetchProduct(normalizedBarcode);
    _inFlightRequests[normalizedBarcode] = future;
    try {
      return await future;
    } finally {
      _inFlightRequests.remove(normalizedBarcode);
    }
  }

  /// Internal fetch logic for a single product.
  /// Always requests with dar_imagen=0 (fast, no image payload).
  /// Image resolution happens in background via pendingImage.
  Future<ProductResult?> _fetchProduct(String normalizedBarcode) async {
    final config = AppConfigService();
    final url = '${config.protocol}://${config.host}/api/erp_dat/v1/_process/visor_datos';
    final apiKey = config.apiKey;
    final imageKey = '$_imageKeyPrefix$normalizedBarcode';

    try {
      // Always dar_imagen=0: fast response with data only, no image payload
      debugPrint('ProductService: Fetching $normalizedBarcode');

      final response = await HttpClientService().client.get(
        url,
        queryParameters: {
          'param[codbar]': normalizedBarcode,
          'param[dar_imagen]': '0',
          'api_key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = _parseResponseData(response.data);

        if (data['ok'] == true) {
          // Build product immediately from data
          final preciosList = data['precios'] as List? ?? [];
          final parseResult = _parsePricesList(preciosList);
          final regularPrice = parseResult.mainPrice + parseResult.discountAmount;

          // Resolve image in background (cache check + fetch if needed)
          final pendingImage = _resolveImage(
            imageKey,
            data['fecha_mod_imagen']?.toString(),
            url,
            normalizedBarcode,
            apiKey,
          );

          final product = Product(
            name: data['name'] ?? 'Desconocido',
            barcode: data['codigo'] ?? '',
            family: data['familia'] ?? '',
            stock: 0,
            regularPrice: regularPrice,
            finalPrice: parseResult.mainPrice,
            unitLabel: parseResult.unitLabel,
            taxPercent: 0.0,
            discounts: parseResult.discounts,
            imageUrl: null, // Will be resolved by pendingImage
            imageBase64: null,
            presentations: parseResult.presentations,
          );

          return ProductResult(product, pendingImage: pendingImage);
        }
      }
    } catch (e) {
      debugPrint('Error fetching product: $e');
    }
    return null;
  }

  /// Resolves image: returns cached reference if valid, or fetches in background
  Future<String?> _resolveImage(
    String imageKey,
    String? serverVersion,
    String url,
    String barcode,
    String apiKey,
  ) async {
    // Check if image is already cached
    final hasImageCached = await _imageCache.isCachedByKey(imageKey);

    if (hasImageCached) {
      final imageStillValid = await _imageCache.isVersionValid(imageKey, serverVersion);
      if (imageStillValid) {
        return 'cached:$imageKey';
      }
      debugPrint('ProductService: Image version changed for $barcode, re-fetching');
    }

    // Need to fetch image — second request with dar_imagen=1
    return _fetchAndCacheImage(url, barcode, imageKey, apiKey);
  }

  /// Fetches product with image data and caches the image
  Future<String?> _fetchAndCacheImage(
    String url, String barcode, String imageKey, String apiKey,
  ) async {
    try {
      final response = await HttpClientService().client.get(
        url,
        queryParameters: {
          'param[codbar]': barcode,
          'param[dar_imagen]': '1',
          'api_key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = _parseResponseData(response.data);
        if (data['ok'] == true) {
          final imageUrl = _extractNonEmpty(data['imagen']);
          final imageBase64 = _extractNonEmpty(data['imagen64']);
          final imageVersion = data['fecha_mod_imagen']?.toString();

          return _cacheImageData(imageKey, imageUrl, imageBase64, imageVersion);
        }
      }
    } catch (e) {
      debugPrint('Error fetching image for $barcode: $e');
    }
    return null;
  }

  /// Caches image bytes from URL or base64, returns cached image source
  Future<String?> _cacheImageData(
    String imageKey, String? imageUrl, String? imageBase64, String? imageVersion,
  ) async {
    try {
      if (imageUrl != null && imageUrl.isNotEmpty) {
        final bytes = await _imageCache.fetchAndCache(imageUrl);
        if (bytes != null) {
          await _imageCache.cacheImage(imageKey, bytes);
          if (imageVersion != null && imageVersion.isNotEmpty) {
            await _imageCache.saveVersion(imageKey, imageVersion);
          }
          debugPrint('ProductService: Cached image from URL');
          return 'cached:$imageKey';
        }
        return imageUrl;
      } else if (imageBase64 != null && imageBase64.isNotEmpty) {
        final bytes = await _imageCache.cacheBase64(imageBase64);
        if (bytes != null) {
          await _imageCache.cacheImage(imageKey, bytes);
          if (imageVersion != null && imageVersion.isNotEmpty) {
            await _imageCache.saveVersion(imageKey, imageVersion);
          }
          debugPrint('ProductService: Cached image from Base64');
          return 'cached:$imageKey';
        }
      }
    } catch (e) {
      debugPrint('Error caching image: $e');
    }
    return null;
  }

  /// Parses response data (String or Map) into a Map, cleaning trailing commas
  Map<String, dynamic> _parseResponseData(dynamic responseData) {
    if (responseData is String) {
      final cleanBody = responseData
          .replaceAll(_trailingCommaInObject, '}')
          .replaceAll(_trailingCommaInArray, ']');
      return Map<String, dynamic>.from(
        const JsonDecoder().convert(cleanBody) as Map,
      );
    }
    return Map<String, dynamic>.from(responseData as Map);
  }

  /// Extracts value if non-null and non-empty string
  String? _extractNonEmpty(dynamic value) {
    if (value == null) return null;
    final str = value.toString();
    return str.isNotEmpty ? str : null;
  }

  /// Parse prices list in a single pass
  _PricesParseResult _parsePricesList(List<dynamic> preciosList) {
    double mainPrice = 0.0;
    double discountAmount = 0.0;
    String unitLabel = '';
    List<PresentationPrice> presentations = [];
    List<Discount> discounts = [];
    bool foundMainPrice = false;

    for (var p in preciosList) {
      if (p is! Map) continue;

      final pvp = _parseDouble(p['PVP']);
      final name = p['name']?.toString() ?? '';
      final factor = _parseDouble(p['factor']);
      final discountPercent = _parseDouble(p['descuento']);
      final itemDiscountAmount = _parseDouble(p['descuento_monto']);

      final isMainUnit = _isMainUnit(factor, name);

      if (isMainUnit && !foundMainPrice) {
        // First main unit found - extract main price info
        mainPrice = pvp;
        discountAmount = itemDiscountAmount;
        unitLabel = _cleanUnitLabel(name);
        foundMainPrice = true;

        if (discountPercent > 0) {
          discounts.add(Discount(
            percent: discountPercent,
            amount: itemDiscountAmount,
            conditionsText: 'Descuento directo',
          ));
        }
      } else if (!isMainUnit) {
        // Not a main unit - add as presentation
        presentations.add(PresentationPrice(
          label: name,
          price: pvp,
          discountPercent: discountPercent,
          discountAmount: itemDiscountAmount,
        ));
      }
    }

    // Fallback: if mainPrice is still 0, take the first item
    if (!foundMainPrice && preciosList.isNotEmpty && preciosList[0] is Map) {
      mainPrice = _parseDouble(preciosList[0]['PVP']);
    }

    return _PricesParseResult(
      mainPrice: mainPrice,
      discountAmount: discountAmount,
      unitLabel: unitLabel,
      presentations: presentations,
      discounts: discounts,
    );
  }

  /// Check if this price entry represents the main unit
  bool _isMainUnit(double factor, String name) {
    return (factor - 1.0).abs() < 0.001 || name.toUpperCase().contains('UNIDAD');
  }

  /// Clean unit label: "UNIDAD X 1" -> "UNIDAD"
  String _cleanUnitLabel(String name) {
    final rawName = name.toUpperCase();
    if (rawName.contains(' X 1')) {
      return rawName.replaceAll(' X 1', '').trim();
    }
    return name;
  }

  /// Safely parse a number to double
  double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return 0.0;
  }
}

/// Result of parsing prices list
class _PricesParseResult {
  final double mainPrice;
  final double discountAmount;
  final String unitLabel;
  final List<PresentationPrice> presentations;
  final List<Discount> discounts;

  const _PricesParseResult({
    required this.mainPrice,
    required this.discountAmount,
    required this.unitLabel,
    required this.presentations,
    required this.discounts,
  });
}
