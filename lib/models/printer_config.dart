enum PrinterType { wifi, bluetooth }

class PrinterConfig {
  final String name;
  final PrinterType type;
  final String address;
  final int port;

  const PrinterConfig({
    required this.name,
    required this.type,
    required this.address,
    this.port = 6101,
  });

  bool get isValid => name.isNotEmpty && address.isNotEmpty;
}
