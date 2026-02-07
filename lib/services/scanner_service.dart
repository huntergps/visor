import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../widgets/common/scanner_dialog.dart';

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

      return await ScannerDialog.show(context);
    } catch (e) {
      debugPrint('Scanner error: $e');
      return null;
    }
  }
}
