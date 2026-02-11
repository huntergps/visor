class PresentationPrice {
  final String id;
  final String label;
  final double price;
  final double discountPercent;
  final double discountAmount;

  const PresentationPrice({
    this.id = '',
    required this.label,
    required this.price,
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
  });
}
