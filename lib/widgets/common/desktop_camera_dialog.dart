import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

/// A dialog that shows a live camera preview on desktop platforms.
/// Returns the captured image as a [File], or null if cancelled.
class DesktopCameraDialog extends StatefulWidget {
  const DesktopCameraDialog({super.key});

  @override
  State<DesktopCameraDialog> createState() => _DesktopCameraDialogState();
}

class _DesktopCameraDialogState extends State<DesktopCameraDialog> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isCapturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No se encontró cámara');
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Error al iniciar cámara: $e');
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || _isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final xFile = await _controller!.takePicture();
      if (mounted) {
        Navigator.of(context).pop(File(xFile.path));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _error = 'Error al capturar: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Capturar foto'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: FloatingActionButton.large(
            backgroundColor: AppColors.brandPrimary,
            onPressed: _isCapturing ? null : _capturePhoto,
            child: _isCapturing
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.camera_alt, color: Colors.white, size: 36),
          ),
        ),
      ],
    );
  }
}
