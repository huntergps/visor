import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:bluetooth_classic/models/device.dart';

import '../models/printer_config.dart';
import '../models/product.dart';
import '../models/presentation_price.dart';
import 'app_config_service.dart';

/// Standard Bluetooth SPP UUID for serial port communication
const _sppUuid = '00001101-0000-1000-8000-00805f9b34fb';

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  final BluetoothClassic _bluetooth = BluetoothClassic();

  /// Whether Bluetooth is available on this platform (Android only)
  bool get isBluetoothSupported => Platform.isAndroid;

  /// Loads printer config from SharedPreferences
  PrinterConfig? getConfig() {
    final config = AppConfigService();
    if (!config.hasPrinterConfigured) return null;

    return PrinterConfig(
      name: config.printerName,
      type: config.printerType == 'bluetooth'
          ? PrinterType.bluetooth
          : PrinterType.wifi,
      address: config.printerAddress,
      port: config.printerPort,
    );
  }

  /// Saves printer config to SharedPreferences
  Future<void> saveConfig(PrinterConfig printerConfig) async {
    final config = AppConfigService();
    await config.setPrinterType(
        printerConfig.type == PrinterType.bluetooth ? 'bluetooth' : 'wifi');
    await config.setPrinterAddress(printerConfig.address);
    await config.setPrinterPort(printerConfig.port);
    await config.setPrinterName(printerConfig.name);
  }

  /// Generate ZPL label for a product with optional presentation
  String generateZpl(Product product, PresentationPrice? presentation) {
    // Split name into two lines of max 30 chars
    final fullName = product.name;
    String name1, name2;
    if (fullName.length <= 30) {
      name1 = fullName;
      name2 = '';
    } else {
      // Try to break at a space near position 30
      int breakIdx = fullName.lastIndexOf(' ', 30);
      if (breakIdx <= 0) breakIdx = 30;
      name1 = fullName.substring(0, breakIdx).trim();
      name2 = fullName.substring(breakIdx).trim();
      if (name2.length > 30) name2 = name2.substring(0, 30);
    }

    // Price
    final price = presentation?.price ?? product.finalPrice;
    final priceStr = price.toStringAsFixed(2);

    // Barcode ID
    final barcodeId = presentation?.id.isNotEmpty == true
        ? presentation!.id
        : product.barcode;

    // IVA text
    final ivaText = product.taxPercent > 0
        ? 'INCLUYE ${product.taxPercent.toStringAsFixed(0)}% IVA'
        : '';

    // Presentation name
    final presentationName = presentation?.label ?? product.unitLabel;

    // Product code
    final productCode = product.barcode;

    return '^XA\n'
        '^PW609\n'
        '^LL0200\n'
        '^LS0\n'
        '^FT32,32^A0N,38,38^FH\\^FD$name1^FS\n'
        '^FT32,66^A0N,38,38^FH\\^FD$name2^FS\n'
        '^FT405,144^A0N,68,67^FH\\^FD\$$priceStr^FS\n'
        '^BY2,3,54^FT35,151^BCN,,Y,N\n'
        '^FD>:$barcodeId^FS\n'
        '^FT469,164^A0N,17,16^FH\\^FD$ivaText^FS\n'
        '^FT499,88^A0N,20,19^FH\\^FD$presentationName^FS\n'
        '^FT280,92^A0N,28,28^FH\\^FD$productCode^FS\n'
        '^PQ1,0,1,Y^XZ\n';
  }

  /// Generate a test label ZPL
  String _generateTestZpl() {
    return '^XA\n'
        '^PW609\n'
        '^LL0200\n'
        '^LS0\n'
        '^FT32,32^A0N,38,38^FH\\^FDTEST ETIQUETA^FS\n'
        '^FT32,66^A0N,38,38^FH\\^FDTheosVisor^FS\n'
        '^FT405,144^A0N,68,67^FH\\^FD\$9.99^FS\n'
        '^BY2,3,54^FT35,151^BCN,,Y,N\n'
        '^FD>:1234567890^FS\n'
        '^FT469,164^A0N,17,16^FH\\^FDINCLUYE 15% IVA^FS\n'
        '^FT499,88^A0N,20,19^FH\\^FDUNIDAD^FS\n'
        '^FT280,92^A0N,28,28^FH\\^FD1234567890^FS\n'
        '^PQ1,0,1,Y^XZ\n';
  }

  /// Print a product label
  Future<String?> printLabel(
      Product product, PresentationPrice? presentation) async {
    final config = getConfig();
    if (config == null) return 'Impresora no configurada';

    final zpl = generateZpl(product, presentation);
    return _sendZpl(zpl, config);
  }

  /// Print a test label
  Future<String?> printTestLabel() async {
    final config = getConfig();
    if (config == null) return 'Impresora no configurada';

    final zpl = _generateTestZpl();
    return _sendZpl(zpl, config);
  }

  /// Send ZPL to printer via configured connection type
  Future<String?> _sendZpl(String zpl, PrinterConfig config) async {
    try {
      if (config.type == PrinterType.wifi) {
        return _sendViaWifi(zpl, config.address, config.port);
      } else {
        return _sendViaBluetooth(zpl, config.address);
      }
    } catch (e) {
      debugPrint('PrinterService: Error sending ZPL: $e');
      return 'Error: $e';
    }
  }

  /// Send ZPL via WiFi TCP socket
  Future<String?> _sendViaWifi(String zpl, String ip, int port) async {
    Socket? socket;
    try {
      socket = await Socket.connect(ip, port,
          timeout: const Duration(seconds: 5));
      socket.add(utf8.encode(zpl));
      await socket.flush();
      return null; // success
    } on SocketException catch (e) {
      return 'Error de conexión WiFi: ${e.message}';
    } finally {
      await socket?.close();
    }
  }

  /// Send ZPL via Bluetooth Classic (Android only)
  Future<String?> _sendViaBluetooth(String zpl, String address) async {
    if (!isBluetoothSupported) {
      return 'Bluetooth no soportado en esta plataforma';
    }
    try {
      await _bluetooth.initPermissions();
      final connected = await _bluetooth.connect(address, _sppUuid);
      if (!connected) {
        return 'No se pudo conectar por Bluetooth';
      }
      await _bluetooth.write(zpl);
      await _bluetooth.disconnect();
      return null; // success
    } catch (e) {
      try {
        await _bluetooth.disconnect();
      } catch (_) {}
      return 'Error Bluetooth: $e';
    }
  }

  /// Get list of paired Bluetooth devices (Android only)
  Future<List<Device>> getPairedDevices() async {
    if (!isBluetoothSupported) return [];
    try {
      await _bluetooth.initPermissions();
      return await _bluetooth.getPairedDevices();
    } catch (e) {
      debugPrint('PrinterService: Error getting paired devices: $e');
      return [];
    }
  }
}
