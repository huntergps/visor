class PresentationPrice {
  final String label;
  final double price;
  final double discountPercent;
  final double discountAmount;

  const PresentationPrice({
    required this.label,
    required this.price,
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
  });
}
