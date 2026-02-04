import 'discount.dart';
import 'presentation_price.dart';

class Product {
  final int? id;
  final String name;
  final String barcode;
  final String family;
  final int stock;
  final String? imageUrl;
  final String? imageBase64;
  final double regularPrice;
  final double finalPrice;
  final String unitLabel;
  final double taxPercent; // e.g. 15
  final List<Discount> discounts;
  final List<PresentationPrice> presentations;

  // Cached best discount (computed once)
  final Discount? _cachedBestDiscount;

  Product({
    this.id,
    required this.name,
    required this.barcode,
    this.family = '',
    required this.stock,
    this.imageUrl,
    this.imageBase64,
    required this.regularPrice,
    required this.finalPrice,
    this.unitLabel = '',
    this.taxPercent = 0.0,
    this.discounts = const [],
    this.presentations = const [],
  }) : _cachedBestDiscount = discounts.isEmpty
            ? null
            : discounts.reduce((a, b) => a.percent > b.percent ? a : b);

  /// Returns the highest discount (by percent), or null if none
  /// Cached on construction to avoid O(n) on every access
  Discount? get bestDiscount => _cachedBestDiscount;

  /// Check if has any discount
  bool get hasDiscount => discounts.isNotEmpty;

  /// Create a copy with a different imageUrl
  Product copyWithImageUrl(String? imageUrl) {
    return Product(
      id: id,
      name: name,
      barcode: barcode,
      family: family,
      stock: stock,
      imageUrl: imageUrl,
      imageBase64: imageBase64,
      regularPrice: regularPrice,
      finalPrice: finalPrice,
      unitLabel: unitLabel,
      taxPercent: taxPercent,
      discounts: discounts,
      presentations: presentations,
    );
  }
}
