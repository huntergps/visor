class Discount {
  final double percent;
  final double amount;
  final String conditionsText;

  const Discount({
    required this.percent,
    this.amount = 0.0,
    required this.conditionsText,
  });
}
