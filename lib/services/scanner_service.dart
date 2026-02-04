import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_barcode_dialog_scanner/qr_barcode_dialog_scanner.dart';

import '../core/app_colors.dart';

class ScannerService {
  static Future<String?> scan(BuildContext context) async {
    try {
      var status = await Permission.camera.status;
      if (status.isDenied) {
        status = await Permission.camera.request();
      }
      if (!context.mounted) return null;

      if (status.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Permiso de cámara denegado. Abra Configuración para habilitarlo.',
            ),
            action: SnackBarAction(
              label: 'Abrir',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        return null;
      }

      if (!status.isGranted) {
        if (!context.mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de cámara denegado')),
        );
        return null;
      }

      final result = await QRBarcodeScanner.showScannerDialog(
        context,
        title: 'Escanear código',
        subtitle: 'Apunte la cámara al código de barras',
        primaryColor: AppColors.brandPrimary,
        backgroundColor: Colors.black87,
        allowFlashToggle: true,
        allowCameraToggle: true,
      );

      if (result != null && result.code.isNotEmpty) {
        return result.code;
      }
      return null;
    } catch (e) {
      debugPrint('Scanner error: $e');
      return null;
    }
  }
}
