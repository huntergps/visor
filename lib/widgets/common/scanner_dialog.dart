import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/app_colors.dart';

/// Formatos de código de barras aceptados (sin QR)
const _allowedFormats = [
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.upcA,
  BarcodeFormat.upcE,
  BarcodeFormat.code128,
  BarcodeFormat.code39,
  BarcodeFormat.code93,
  BarcodeFormat.codabar,
  BarcodeFormat.itf,
];

class ScannerDialog extends StatefulWidget {
  const ScannerDialog({super.key});

  /// Show the scanner dialog and return the scanned code, or null if cancelled.
  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ScannerDialog(),
    );
  }

  @override
  State<ScannerDialog> createState() => _ScannerDialogState();
}

class _ScannerDialogState extends State<ScannerDialog>
    with SingleTickerProviderStateMixin {
  MobileScannerController? _controller;
  bool _scanned = false;

  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      autoStart: true,
      formats: _allowedFormats,
    );
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
    _scanLineController.repeat(reverse: true);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    // Double-check: skip QR codes
    if (barcode.format == BarcodeFormat.qrCode) return;

    final code = barcode.rawValue!;
    if (code.isEmpty) return;

    _scanned = true;
    // Beep + vibrate
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(code);
  }

  void _toggleFlash() {
    _controller?.toggleTorch();
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Escanear código',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Apunte la cámara al código de barras',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),
            // Camera with scan line
            Container(
              height: MediaQuery.sizeOf(context).height * 0.35,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.brandPrimary, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: _controller!,
                      fit: BoxFit.cover,
                      onDetect: _onDetect,
                    ),
                    // Animated scan line
                    AnimatedBuilder(
                      animation: _scanLineAnimation,
                      builder: (context, child) {
                        return Positioned(
                          top: _scanLineAnimation.value *
                              (MediaQuery.sizeOf(context).height * 0.35 - 6),
                          left: 16,
                          right: 16,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  AppColors.brandPrimary,
                                  AppColors.brandPrimary,
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.2, 0.8, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.brandPrimary.withValues(alpha: 0.6),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Controls
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ValueListenableBuilder(
                    valueListenable: _controller!,
                    builder: (_, state, __) {
                      final isOn = state.torchState == TorchState.on;
                      return _ControlButton(
                        icon: isOn ? Icons.flash_on : Icons.flash_off,
                        label: isOn ? 'Apagar flash' : 'Encender flash',
                        isActive: isOn,
                        onPressed: _toggleFlash,
                      );
                    },
                  ),
                  _ControlButton(
                    icon: Icons.cameraswitch,
                    label: 'Cambiar cámara',
                    isActive: false,
                    onPressed: () => _controller?.switchCamera(),
                  ),
                  _ControlButton(
                    icon: Icons.cancel_outlined,
                    label: 'Cancelar',
                    isActive: false,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white38, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Soporta EAN-13, EAN-8, UPC, Code 128, Code 39',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isActive ? AppColors.brandPrimary : Colors.white12,
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: Colors.white, size: 26),
            padding: const EdgeInsets.all(10),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
