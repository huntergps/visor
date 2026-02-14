import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/printer_config.dart';
import '../models/product.dart';
import '../models/presentation_price.dart';
import 'app_config_service.dart';

/// Simple representation of a Bluetooth device
class BtDevice {
  final String name;
  final String address;
  BtDevice({required this.name, required this.address});
}

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  /// Native Bluetooth channel (Android SPP only)
  static const _btChannel = MethodChannel(
    'tech.galapagos.theosvisor/bluetooth',
  );

  /// Whether Bluetooth is available on this platform
  bool get isBluetoothSupported => Platform.isAndroid || Platform.isIOS;

  // ── BLE state for iOS (flutter_blue_plus) ──
  BluetoothDevice? _bleDevice;
  BluetoothCharacteristic? _bleWriteChar;
  List<ScanResult> _bleScanResults = [];

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
      printerConfig.type == PrinterType.bluetooth ? 'bluetooth' : 'wifi',
    );
    await config.setPrinterAddress(printerConfig.address);
    await config.setPrinterPort(printerConfig.port);
    await config.setPrinterName(printerConfig.name);
  }

  /// Generate ZPL label matching Velneo template with configurable coordinates
  String generateZpl(Product product, PresentationPrice? presentation) {
    final cfg = AppConfigService();

    // Split name into two lines (~30 chars fit per line with font 38)
    final fullName = product.name;
    String name1, name2;
    if (fullName.length <= 30) {
      name1 = fullName;
      name2 = '';
    } else {
      int breakIdx = fullName.lastIndexOf(' ', 30);
      if (breakIdx <= 0) breakIdx = 30;
      name1 = fullName.substring(0, breakIdx).trim();
      name2 = fullName.substring(breakIdx).trim();
      if (name2.length > 30) name2 = name2.substring(0, 30);
    }

    final price = presentation?.price ?? product.finalPrice;
    final priceStr = price.toStringAsFixed(2);

    // Use codbar (EAN/UPC) for barcode; fall back to product code
    final barcodeId = presentation?.codbar.isNotEmpty == true
        ? presentation!.codbar
        : product.codbar.isNotEmpty
            ? product.codbar
            : product.barcode;

    final ivaText = product.taxPercent > 0
        ? 'INCLUYE ${product.taxPercent.toStringAsFixed(0)}% IVA'
        : '';

    final presentationName = presentation?.label ?? product.unitLabel;
    final productCode = product.barcode;

    // Configurable coordinates (defaults match Velneo ZPL)
    final lt = cfg.getLabelCoord('lt');
    final ltCmd = lt != 0 ? '^LT$lt' : '';

    return '^XA\n'
        '^CI28\n' // UTF-8 encoding (Ñ, tildes, etc.)
        '^PW609\n'
        '^LL0200\n'
        '^LS0\n'
        '${ltCmd.isNotEmpty ? '$ltCmd\n' : ''}'
        '^FT${cfg.getLabelCoord('name1_x')},${cfg.getLabelCoord('name1_y')}^A0N,38,38^FH\\^FD$name1^FS\n'
        '^FT${cfg.getLabelCoord('name2_x')},${cfg.getLabelCoord('name2_y')}^A0N,38,38^FH\\^FD$name2^FS\n'
        '^FT${cfg.getLabelCoord('price_x')},${cfg.getLabelCoord('price_y')}^A0N,68,67^FH\\^FD\$$priceStr^FS\n'
        '^BY2,3,54^FT${cfg.getLabelCoord('barcode_x')},${cfg.getLabelCoord('barcode_y')}^BCN,,Y,N\n'
        '^FD>:$barcodeId^FS\n'
        '^FT${cfg.getLabelCoord('iva_x')},${cfg.getLabelCoord('iva_y')}^A0N,17,16^FH\\^FD$ivaText^FS\n'
        '^FT${cfg.getLabelCoord('presentation_x')},${cfg.getLabelCoord('presentation_y')}^A0N,20,19^FH\\^FD$presentationName^FS\n'
        '^FT${cfg.getLabelCoord('code_x')},${cfg.getLabelCoord('code_y')}^A0N,28,28^FH\\^FD$productCode^FS\n'
        '^PQ1,0,1,Y^XZ\n';
  }

  /// Generate a test label ZPL matching Velneo template
  String _generateTestZpl() {
    final cfg = AppConfigService();
    final lt = cfg.getLabelCoord('lt');
    final ltCmd = lt != 0 ? '^LT$lt' : '';

    return '^XA\n'
        '^CI28\n' // UTF-8 encoding (Ñ, tildes, etc.)
        '^PW609\n'
        '^LL0200\n'
        '^LS0\n'
        '${ltCmd.isNotEmpty ? '$ltCmd\n' : ''}'
        '^FT${cfg.getLabelCoord('name1_x')},${cfg.getLabelCoord('name1_y')}^A0N,38,38^FH\\^FDTEST ETIQUETA^FS\n'
        '^FT${cfg.getLabelCoord('name2_x')},${cfg.getLabelCoord('name2_y')}^A0N,38,38^FH\\^FDTheosVisor^FS\n'
        '^FT${cfg.getLabelCoord('price_x')},${cfg.getLabelCoord('price_y')}^A0N,68,67^FH\\^FD\$9.99^FS\n'
        '^BY2,3,54^FT${cfg.getLabelCoord('barcode_x')},${cfg.getLabelCoord('barcode_y')}^BCN,,Y,N\n'
        '^FD>:1234567890^FS\n'
        '^FT${cfg.getLabelCoord('iva_x')},${cfg.getLabelCoord('iva_y')}^A0N,17,16^FH\\^FDINCLUYE 15% IVA^FS\n'
        '^FT${cfg.getLabelCoord('presentation_x')},${cfg.getLabelCoord('presentation_y')}^A0N,20,19^FH\\^FDUNIDAD X 1^FS\n'
        '^FT${cfg.getLabelCoord('code_x')},${cfg.getLabelCoord('code_y')}^A0N,28,28^FH\\^FD88981^FS\n'
        '^PQ1,0,1,Y^XZ\n';
  }

  /// Print a product label
  Future<String?> printLabel(
    Product product,
    PresentationPrice? presentation,
  ) async {
    final config = getConfig();
    if (config == null) return 'Impresora no configurada';

    final zpl = generateZpl(product, presentation);
    return _sendZpl(zpl, config);
  }

  /// Configure printer: set media type, label size, and head close action.
  Future<String?> calibrate() async {
    final config = getConfig();
    if (config == null) return 'Impresora no configurada';

    const printerSetup =
        '! U1 setvar "device.languages" "zpl"\r\n'
        '! U1 setvar "ezpl.media_type" "mark"\r\n'
        '! U1 setvar "ezpl.head_close_action" "no_motion"\r\n'
        '! U1 setvar "ezpl.power_up_action" "no_motion"\r\n';

    const zplSetup =
        '^XA'
        '^PW609'
        '^LL200'
        '^MNM'  // Mark mode: detect black marks on back
        '^JUS'
        '^XZ';

    try {
      if (config.type == PrinterType.bluetooth) {
        if (Platform.isIOS) {
          await _bleConnect(config.address);
          await _bleSendData(printerSetup);
          await Future.delayed(const Duration(seconds: 1));
          await _bleSendData(zplSetup);
          await Future.delayed(const Duration(seconds: 2));
          await _bleDisconnect();
        } else {
          await _btChannel.invokeMethod('connect', {'address': config.address});
          await _btChannel.invokeMethod('send', {'data': printerSetup});
          await Future.delayed(const Duration(seconds: 1));
          await _btChannel.invokeMethod('send', {'data': zplSetup});
          await Future.delayed(const Duration(seconds: 2));
          await _btChannel.invokeMethod('disconnect');
        }
      } else {
        final socket = await Socket.connect(
          config.address,
          config.port,
          timeout: const Duration(seconds: 5),
        );
        socket.add(utf8.encode(printerSetup));
        await socket.flush();
        await Future.delayed(const Duration(seconds: 1));
        socket.add(utf8.encode(zplSetup));
        await socket.flush();
        await Future.delayed(const Duration(seconds: 2));
        await socket.close();
      }
      return null;
    } catch (e) {
      return 'Error configurando: $e';
    }
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
      socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(seconds: 5),
      );
      socket.add(utf8.encode(zpl));
      await socket.flush();
      return null;
    } on SocketException catch (e) {
      return 'Error de conexión WiFi: ${e.message}';
    } finally {
      await socket?.close();
    }
  }

  static const _setZplCommand = '! U1 setvar "device.languages" "zpl"\r\n';

  /// Send ZPL via Bluetooth (Android: native SPP, iOS: flutter_blue_plus BLE)
  Future<String?> _sendViaBluetooth(String zpl, String address) async {
    if (!isBluetoothSupported) {
      return 'Bluetooth no soportado en esta plataforma';
    }

    if (Platform.isIOS) {
      return _sendViaBleFbp(zpl, address);
    }

    // Android: native SPP channel
    try {
      debugPrint('PrinterService: Connecting via SPP to $address...');
      await _btChannel.invokeMethod('connect', {'address': address});

      debugPrint('PrinterService: Sending ${zpl.length} bytes of ZPL...');
      await _btChannel.invokeMethod('send', {'data': zpl});

      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint('PrinterService: Done, disconnecting...');
      await _btChannel.invokeMethod('disconnect');
      return null;
    } catch (e) {
      debugPrint('PrinterService: BT failed: $e');
      try {
        await _btChannel.invokeMethod('disconnect');
      } catch (_) {}
      return 'Error Bluetooth: $e';
    }
  }

  // ══════════════════════════════════════════════════════════════
  // iOS BLE via flutter_blue_plus
  // ══════════════════════════════════════════════════════════════

  /// Standard BLE services to skip when looking for printer data characteristic
  static const _standardServiceUuids = {
    '00001800-0000-1000-8000-00805f9b34fb', // Generic Access
    '00001801-0000-1000-8000-00805f9b34fb', // Generic Attribute
    '0000180a-0000-1000-8000-00805f9b34fb', // Device Information
    '0000180f-0000-1000-8000-00805f9b34fb', // Battery
  };

  /// Scan for BLE devices (iOS) or paired devices (Android)
  Future<List<BtDevice>> getPairedDevices() async {
    if (!isBluetoothSupported) return [];

    if (Platform.isIOS) {
      return _bleScanDevices();
    }

    // Android: native channel
    try {
      debugPrint('PrinterService: Getting paired devices via native channel...');
      final result = await _btChannel.invokeMethod('getPairedDevices');
      if (result is List) {
        final devices = result.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return BtDevice(
            name: map['name'] as String? ?? 'Desconocido',
            address: map['address'] as String? ?? '',
          );
        }).toList();
        debugPrint('PrinterService: Found ${devices.length} paired devices');
        for (final d in devices) {
          debugPrint('PrinterService:   - ${d.name} (${d.address})');
        }
        return devices;
      }
      return [];
    } catch (e) {
      debugPrint('PrinterService: Error getting paired devices: $e');
      return [];
    }
  }

  /// iOS: Scan for BLE devices using flutter_blue_plus
  Future<List<BtDevice>> _bleScanDevices() async {
    try {
      // Wait up to 3s for adapter to be on (may be initializing)
      final state = await FlutterBluePlus.adapterState
          .where((s) => s == BluetoothAdapterState.on)
          .first
          .timeout(const Duration(seconds: 3), onTimeout: () {
        return BluetoothAdapterState.off;
      });
      if (state != BluetoothAdapterState.on) {
        debugPrint('PrinterService: BLE adapter is off');
        return [];
      }

      debugPrint('PrinterService: BLE scanning for 4 seconds...');
      _bleScanResults = [];

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 4),
        androidUsesFineLocation: false,
      );

      // Wait for scan to complete
      await FlutterBluePlus.isScanning.where((s) => s == false).first;

      _bleScanResults = FlutterBluePlus.lastScanResults;

      final devices = _bleScanResults
          .where((r) => r.device.platformName.isNotEmpty)
          .map((r) => BtDevice(
                name: r.device.platformName,
                address: r.device.remoteId.str,
              ))
          .toList();

      debugPrint('PrinterService: BLE found ${devices.length} devices');
      for (final d in devices) {
        debugPrint('PrinterService:   - ${d.name} (${d.address})');
      }
      return devices;
    } catch (e) {
      debugPrint('PrinterService: BLE scan error: $e');
      return [];
    }
  }

  /// iOS: Connect to BLE device by remoteId.
  /// Does a fresh scan to ensure iOS BLE stack has an active peripheral reference,
  /// then connects using that freshly discovered device.
  Future<void> _bleConnect(String address) async {
    debugPrint('PrinterService: BLE connecting to $address...');

    // Check if already connected
    final connectedDevices = FlutterBluePlus.connectedDevices;
    final alreadyConnected = connectedDevices
        .where((d) => d.remoteId.str == address)
        .toList();

    BluetoothDevice device;

    if (alreadyConnected.isNotEmpty) {
      debugPrint('PrinterService: BLE device already connected, reusing');
      device = alreadyConnected.first;
    } else {
      // Fresh scan to get an active peripheral reference (critical for iOS BLE)
      debugPrint('PrinterService: BLE pre-connect scan...');
      BluetoothDevice? scannedDevice;

      // Listen for scan results and stop as soon as we find our target
      final subscription = FlutterBluePlus.onScanResults.listen((results) {
        for (final r in results) {
          if (r.device.remoteId.str == address) {
            scannedDevice = r.device;
            debugPrint('PrinterService: BLE found target in scan, RSSI=${r.rssi}');
            FlutterBluePlus.stopScan();
            break;
          }
        }
      });

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 8),
        androidUsesFineLocation: false,
      );

      // Wait for scan to finish
      await FlutterBluePlus.isScanning.where((s) => s == false).first;
      await subscription.cancel();

      if (scannedDevice != null) {
        device = scannedDevice!;
      } else {
        // Fallback: try from previous scan results or by ID
        debugPrint('PrinterService: BLE target not found in pre-scan, trying fromId...');
        final scanMatch = _bleScanResults
            .where((r) => r.device.remoteId.str == address)
            .toList();
        device = scanMatch.isNotEmpty
            ? scanMatch.first.device
            : BluetoothDevice.fromId(address);
      }

      debugPrint('PrinterService: BLE calling connect()...');
      await device.connect(
        license: License.free,
        timeout: const Duration(seconds: 15),
        mtu: null,
        autoConnect: false,
      );
      debugPrint('PrinterService: BLE connected!');

      // Request MTU
      try {
        await device.requestMtu(512);
        debugPrint('PrinterService: BLE MTU=${device.mtuNow}');
      } catch (e) {
        debugPrint('PrinterService: BLE MTU request failed (ok): $e');
      }
    }

    // Discover services and find writable characteristic
    final services = await device.discoverServices();
    debugPrint('PrinterService: BLE found ${services.length} services');

    BluetoothCharacteristic? writeChar;

    for (final svc in services) {
      final svcUuid = svc.uuid.str.toLowerCase();
      if (_standardServiceUuids.contains(svcUuid)) {
        debugPrint('PrinterService: BLE skip standard service $svcUuid');
        continue;
      }

      debugPrint('PrinterService: BLE vendor service ${svc.uuid}');
      for (final c in svc.characteristics) {
        final props = c.properties;
        debugPrint(
          'PrinterService: BLE   char ${c.uuid} '
          'W=${props.write} WnR=${props.writeWithoutResponse} '
          'R=${props.read} N=${props.notify}',
        );

        if (writeChar == null &&
            (props.writeWithoutResponse || props.write)) {
          writeChar = c;
          debugPrint('PrinterService: BLE >>> SELECTED ${c.uuid}');
        }
      }
    }

    if (writeChar == null) {
      await device.disconnect();
      throw Exception('Sin característica de escritura BLE');
    }

    _bleDevice = device;
    _bleWriteChar = writeChar;
  }

  /// iOS: Send string data via BLE
  Future<void> _bleSendData(String data) async {
    final char = _bleWriteChar;
    if (char == null) throw Exception('No hay conexión BLE');

    final bytes = utf8.encode(data);
    final mtu = _bleDevice?.mtuNow ?? 23;
    final chunkSize = (mtu - 3).clamp(20, 512);
    final useResponse = char.properties.write;

    debugPrint(
      'PrinterService: BLE sending ${bytes.length}B, MTU=$mtu, '
      'chunk=$chunkSize, withResponse=$useResponse',
    );

    for (var offset = 0; offset < bytes.length; offset += chunkSize) {
      final end = (offset + chunkSize).clamp(0, bytes.length);
      final chunk = bytes.sublist(offset, end);
      await char.write(chunk, withoutResponse: !useResponse);
    }

    debugPrint('PrinterService: BLE send complete');
  }

  /// iOS: Disconnect BLE
  Future<void> _bleDisconnect() async {
    try {
      await _bleDevice?.disconnect();
    } catch (_) {}
    _bleDevice = null;
    _bleWriteChar = null;
  }

  /// iOS: Send ZPL via BLE using flutter_blue_plus
  Future<String?> _sendViaBleFbp(String zpl, String address) async {
    try {
      await _bleConnect(address);
      await _bleSendData(zpl);
      await Future.delayed(const Duration(milliseconds: 2000));
      await _bleDisconnect();
      return null;
    } catch (e) {
      debugPrint('PrinterService: BLE failed: $e');
      await _bleDisconnect();
      return 'Error Bluetooth: $e';
    }
  }
}
