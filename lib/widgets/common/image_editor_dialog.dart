import 'dart:math';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../core/app_colors.dart';
import '../../services/image_upload_service.dart';

/// Image editor dialog with crop, rotation, brightness, and background removal.
/// Two tabs: Crop first, then Adjustments with live preview.
/// Receives raw image bytes and returns edited bytes (or null on cancel).
class ImageEditorDialog extends StatefulWidget {
  final Uint8List imageBytes;

  const ImageEditorDialog({super.key, required this.imageBytes});

  @override
  State<ImageEditorDialog> createState() => _ImageEditorDialogState();
}

class _ImageEditorDialogState extends State<ImageEditorDialog>
    with SingleTickerProviderStateMixin {
  // Tab controller
  late TabController _tabController;

  // Images
  late Uint8List _originalImageBytes;
  Uint8List? _croppedImageBytes; // After crop (null if not cropped yet)

  // Crop
  final _cropController = CropController();
  bool _isCropping = false;

  // Adjustments
  double _rotation = 0; // degrees: -180 to 180
  double _brightness = 0; // -100 to 100
  double _contrast = 0; // -100 to 100
  double _saturation = 0; // -100 to 100
  Uint8List? _bgRemovedBytes; // After bg removal
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _originalImageBytes = widget.imageBytes;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _removeBackground() async {
    setState(() => _isProcessing = true);

    try {
      // Work with current image state (cropped if available, otherwise original)
      final sourceBytes = _croppedImageBytes ?? _originalImageBytes;
      final result = await ImageUploadService().removeBackground(sourceBytes);

      if (result != null && mounted) {
        setState(() {
          _bgRemovedBytes = result;
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al quitar el fondo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Build color filter with brightness, contrast, and saturation
  ColorFilter _buildColorFilter() {
    final b = _brightness / 100;
    final c = 1 + (_contrast / 100);
    final s = 1 + (_saturation / 100);

    // Saturation matrix
    final double sr = (1 - s) * 0.3086;
    final double sg = (1 - s) * 0.6094;
    final double sb = (1 - s) * 0.0820;

    return ColorFilter.matrix(<double>[
      sr + s * c, sg, sb, 0, b * 255,
      sr, sg + s * c, sb, 0, b * 255,
      sr, sg, sb + s * c, 0, b * 255,
      0, 0, 0, 1, 0,
    ]);
  }

  /// Reset rotation to 0
  void _resetRotation() {
    setState(() => _rotation = 0);
  }

  /// Reset brightness to 0
  void _resetBrightness() {
    setState(() => _brightness = 0);
  }

  /// Reset contrast to 0
  void _resetContrast() {
    setState(() => _contrast = 0);
  }

  /// Reset saturation to 0
  void _resetSaturation() {
    setState(() => _saturation = 0);
  }

  /// Reset all adjustments
  void _resetAllAdjustments() {
    setState(() {
      _rotation = 0;
      _brightness = 0;
      _contrast = 0;
      _saturation = 0;
    });
  }

  /// Reset crop (go back to tab 1 with original image)
  void _resetCrop() {
    setState(() {
      _croppedImageBytes = null;
      _bgRemovedBytes = null;
    });
    _tabController.animateTo(0);
  }

  /// Handle crop completion (called by Crop widget when crop() is triggered)
  void _onCropped(CropResult result) {
    switch (result) {
      case CropSuccess(:final croppedImage):
        setState(() {
          _croppedImageBytes = croppedImage;
          _isCropping = false;
        });
        // Auto-switch to adjustments tab to see preview
        _tabController.animateTo(1);
        break;
      case CropFailure(:final cause):
        setState(() => _isCropping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al recortar: $cause'),
            backgroundColor: Colors.red,
          ),
        );
        break;
    }
  }

  /// Apply crop via controller
  void _applyCrop() {
    if (_isCropping) return;
    setState(() => _isCropping = true);
    _cropController.crop();
  }

  /// Called when user presses "Listo" - applies all edits in order
  Future<void> _onDone() async {
    // In crop tab: apply crop first
    if (_tabController.index == 0) {
      _applyCrop();
      return;
    }

    // In adjust tab: finalize with all edits
    setState(() => _isProcessing = true);

    try {
      // Use cropped image if available, otherwise original
      Uint8List finalBytes = _croppedImageBytes ?? _originalImageBytes;

      // Apply background removal if done
      if (_bgRemovedBytes != null) {
        finalBytes = _bgRemovedBytes!;
      }

      // Apply rotation/brightness/contrast/saturation if needed
      if (_rotation != 0 || _brightness != 0 || _contrast != 0 || _saturation != 0) {
        finalBytes = await compute(
          _applyEdits,
          _EditParams(
            bytes: finalBytes,
            rotation: _rotation,
            brightness: _brightness,
            contrast: _contrast,
            saturation: _saturation,
          ),
        );
      }

      if (mounted) Navigator.of(context).pop(finalBytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error procesando imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar imagen'),
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        actions: [
          TextButton(
            onPressed: (_isProcessing || _isCropping) ? null : _onDone,
            child: Text(
              _tabController.index == 0 ? 'Siguiente' : 'Listo',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.crop), text: 'Recortar'),
            Tab(icon: Icon(Icons.tune), text: 'Ajustes'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildCropTab(),
              _buildAdjustTab(),
            ],
          ),
          // Loading overlay
          if (_isProcessing || _isCropping)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Procesando...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCropTab() {
    return Column(
      children: [
        Expanded(
          child: Crop(
            controller: _cropController,
            image: _originalImageBytes,
            onCropped: _onCropped,
            aspectRatio: 3 / 4,
            withCircleUi: false,
            baseColor: Colors.black,
            maskColor: Colors.black.withValues(alpha: 0.5),
            initialRectBuilder: InitialRectBuilder.withSizeAndRatio(
              size: 0.7,
            ),
            cornerDotBuilder: (size, edgeAlignment) => SizedBox(
              width: 24,
              height: 24,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
            progressIndicator: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ajusta el área de recorte',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                'Relación 3:4 • Pellizca y arrastra',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdjustTab() {
    return Column(
      children: [
        // Preview with live transforms
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Transform.rotate(
                angle: _rotation * pi / 180,
                child: ColorFiltered(
                  colorFilter: _buildColorFilter(),
                  child: Image.memory(
                    _bgRemovedBytes ?? _croppedImageBytes ?? _originalImageBytes,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Controls (scrollable)
        Container(
          constraints: const BoxConstraints(maxHeight: 320),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Rotation slider
                Row(
                  children: [
                    const Icon(Icons.rotate_right, size: 18),
                    const SizedBox(width: 6),
                    const Text('Rotación', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: _rotation,
                        min: -180,
                        max: 180,
                        divisions: 360,
                        label: '${_rotation.round()}°',
                        activeColor: AppColors.brandPrimary,
                        onChanged: (v) => setState(() => _rotation = v),
                      ),
                    ),
                    SizedBox(
                      width: 35,
                      child: Text(
                        '${_rotation.round()}°',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18),
                      onPressed: _rotation != 0 ? _resetRotation : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Resetear',
                    ),
                  ],
                ),
                // Brightness slider
                Row(
                  children: [
                    const Icon(Icons.brightness_6, size: 18),
                    const SizedBox(width: 6),
                    const Text('Brillo', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: _brightness,
                        min: -100,
                        max: 100,
                        divisions: 200,
                        label: '${_brightness.round()}',
                        activeColor: AppColors.brandPrimary,
                        onChanged: (v) => setState(() => _brightness = v),
                      ),
                    ),
                    SizedBox(
                      width: 35,
                      child: Text(
                        '${_brightness.round()}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18),
                      onPressed: _brightness != 0 ? _resetBrightness : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Resetear',
                    ),
                  ],
                ),
                // Contrast slider
                Row(
                  children: [
                    const Icon(Icons.contrast, size: 18),
                    const SizedBox(width: 6),
                    const Text('Contraste', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: _contrast,
                        min: -100,
                        max: 100,
                        divisions: 200,
                        label: '${_contrast.round()}',
                        activeColor: AppColors.brandPrimary,
                        onChanged: (v) => setState(() => _contrast = v),
                      ),
                    ),
                    SizedBox(
                      width: 35,
                      child: Text(
                        '${_contrast.round()}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18),
                      onPressed: _contrast != 0 ? _resetContrast : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Resetear',
                    ),
                  ],
                ),
                // Saturation slider
                Row(
                  children: [
                    const Icon(Icons.palette, size: 18),
                    const SizedBox(width: 6),
                    const Text('Saturación', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: _saturation,
                        min: -100,
                        max: 100,
                        divisions: 200,
                        label: '${_saturation.round()}',
                        activeColor: AppColors.brandPrimary,
                        onChanged: (v) => setState(() => _saturation = v),
                      ),
                    ),
                    SizedBox(
                      width: 35,
                      child: Text(
                        '${_saturation.round()}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18),
                      onPressed: _saturation != 0 ? _resetSaturation : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Resetear',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing ? null : _resetAllAdjustments,
                        icon: const Icon(Icons.restart_alt, size: 18),
                        label: const Text('Resetear Todo', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.brandPrimary,
                          side: const BorderSide(color: AppColors.brandPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _removeBackground,
                        icon: const Icon(Icons.auto_fix_high, size: 18),
                        label: Text(
                          _bgRemovedBytes != null ? 'Fondo ✓' : 'Quitar fondo',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _bgRemovedBytes != null
                              ? Colors.green
                              : AppColors.brandPrimary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_croppedImageBytes != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _resetCrop,
                    icon: const Icon(Icons.crop_rotate, size: 18),
                    label: const Text('Recortar de nuevo', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brandPrimary,
                      side: const BorderSide(color: AppColors.brandPrimary),
                      minimumSize: const Size(double.infinity, 36),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Parameters for the isolate function.
class _EditParams {
  final Uint8List bytes;
  final double rotation;
  final double brightness;
  final double contrast;
  final double saturation;

  _EditParams({
    required this.bytes,
    required this.rotation,
    required this.brightness,
    required this.contrast,
    required this.saturation,
  });
}

/// Top-level function for isolate: apply rotation and brightness edits.
Uint8List _applyEdits(_EditParams params) {
  var image = img.decodeImage(params.bytes);
  if (image == null) throw Exception('Failed to decode image');

  if (params.rotation != 0) {
    image = img.copyRotate(image, angle: params.rotation);
  }

  // Apply color adjustments if any
  if (params.brightness != 0 || params.contrast != 0 || params.saturation != 0) {
    image = img.adjustColor(
      image,
      brightness: 1.0 + (params.brightness / 100),
      contrast: 1.0 + (params.contrast / 100),
      saturation: 1.0 + (params.saturation / 100),
    );
  }

  return Uint8List.fromList(img.encodePng(image));
}
