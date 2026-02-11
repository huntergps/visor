import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Listens for hardware barcode scanner events via platform channels.
/// Currently supports Zebra DataWedge (Android only).
/// On non-Android platforms, the stream emits nothing.
class HardwareScannerService {
  static const _scanChannel = EventChannel('tech.galapagos.theosvisor/scan');
  static const _methodChannel = MethodChannel('tech.galapagos.theosvisor/hardware');
  static Stream<String>? _stream;

  /// Whether a hardware barcode scanner (DataWedge) is available.
  /// Must call [init] before accessing.
  static bool isAvailable = false;

  /// Detect hardware scanner at startup. Safe on all platforms.
  static Future<void> init() async {
    if (!Platform.isAndroid) return;
    try {
      isAvailable = await _methodChannel.invokeMethod<bool>('hasHardwareScanner') ?? false;
      debugPrint('HardwareScannerService: isAvailable=$isAvailable');
    } catch (e) {
      debugPrint('HardwareScannerService: init error: $e');
      isAvailable = false;
    }
  }

  /// Stream of barcodes from hardware scanner (Zebra DataWedge).
  /// Safe to listen on any platform — emits nothing on non-Android.
  static Stream<String> get scanStream {
    if (!Platform.isAndroid) return const Stream.empty();
    _stream ??= _scanChannel
        .receiveBroadcastStream()
        .map((event) => event.toString().trim());
    return _stream!;
  }
}
