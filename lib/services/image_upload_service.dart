import 'dart:convert';
import 'dart:io';

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_background_remover/image_background_remover.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_colors.dart';
import '../widgets/common/desktop_camera_dialog.dart';
import '../widgets/common/image_editor_dialog.dart';
import 'app_config_service.dart';
import 'http_client_service.dart';
import 'image_cache_service.dart';

/// Service for capturing, processing, and uploading product images.
class ImageUploadService {
  static final ImageUploadService _instance = ImageUploadService._internal();
  factory ImageUploadService() => _instance;
  ImageUploadService._internal();

  final _picker = ImagePicker();

  /// Pick an image from camera or gallery.
  Future<File?> pickImage(ImageSource source) async {
    try {
      final xFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1366,
      );
      if (xFile == null) return null;
      return File(xFile.path);
    } catch (e) {
      debugPrint('ImageUploadService.pickImage error: $e');
      return null;
    }
  }


  /// Process image: resize to 768x1024 and encode as base64 PNG.
  /// Runs in an isolate to avoid blocking the UI thread.
  Future<String> processImage(File file) async {
    final bytes = await file.readAsBytes();
    return compute(_processImageIsolate, bytes);
  }

  /// Upload base64 image to server via POST /productos/{id}.
  Future<bool> uploadImage(String productId, String base64Image) async {
    final config = AppConfigService();
    final url = '${config.protocol}://${config.host}/api/erp_dat/v1/productos/$productId';

    try {
      final response = await HttpClientService().client.post(
        url,
        queryParameters: {
          'api_key': config.apiKey,
        },
        data: {
          'img': base64Image,
        },
      );
      return response.statusCode == 200 &&
          (response.data is! Map || !(response.data as Map).containsKey('errors'));
    } catch (e) {
      debugPrint('ImageUploadService.uploadImage error: $e');
      return false;
    }
  }

  bool _ortInitialized = false;

  /// Initialize ONNX Runtime for background removal (lazy, once).
  Future<void> _ensureOrtInitialized() async {
    if (_ortInitialized) return;
    await BackgroundRemover.instance.initializeOrt();
    _ortInitialized = true;
  }

  /// Remove background using local ONNX model (offline).
  Future<Uint8List?> removeBackground(Uint8List imageBytes) async {
    try {
      await _ensureOrtInitialized();
      final ui.Image result = await BackgroundRemover.instance.removeBg(
        imageBytes,
      );
      final byteData = await result.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) return null;
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('ImageUploadService.removeBackground error: $e');
      return null;
    }
  }

  /// Orchestrates the full capture-crop-edit-preview-upload flow.
  /// Returns true if the image was saved (locally or remotely).
  Future<bool> captureAndProcess(
    BuildContext context,
    String productId,
  ) async {
    // 1. Show source picker bottom sheet
    final source = await _showSourcePicker(context);
    if (source == null) return false;

    // 2. Pick image (use DesktopCameraDialog for camera on desktop)
    File? file;
    final isDesktop = Platform.isMacOS || Platform.isWindows || Platform.isLinux;
    if (source == ImageSource.camera && isDesktop) {
      if (!context.mounted) return false;
      file = await Navigator.of(context).push<File>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const DesktopCameraDialog(),
        ),
      );
    } else {
      file = await pickImage(source);
    }
    if (file == null) return false;

    // 3. Read original bytes (no processing yet)
    final originalBytes = await file.readAsBytes();

    // 4. Open image editor (crop + rotation + brightness + remove bg)
    if (!context.mounted) return false;
    final editedBytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ImageEditorDialog(
          imageBytes: originalBytes,
        ),
      ),
    );
    if (editedBytes == null) return false;

    // 5. Process edited image (resize to 768x1024)
    final base64Image = await compute(_processImageIsolate, editedBytes);

    // 6. Decode processed bytes for preview
    final processedBytes = base64Decode(base64Image);

    // 7. Show preview dialog
    if (!context.mounted) return false;
    final action = await _showPreviewDialog(context, processedBytes);
    if (action == null) return false;

    // 8. Handle action
    final cacheKey = 'product_$productId';
    final finalBase64 = base64Image;

    if (action == _UploadAction.uploadToServer) {
      // Try to upload to server with retry option
      bool uploadSuccessful = false;

      while (!uploadSuccessful) {
        if (!context.mounted) return false;

        // Show loading overlay using OverlayEntry to avoid Navigator stack issues
        final overlay = OverlayEntry(
          builder: (_) => Material(
            color: Colors.black54,
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Subiendo imagen...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        Overlay.of(context).insert(overlay);

        final success = await uploadImage(productId, finalBase64);

        overlay.remove();

        if (success) {
          uploadSuccessful = true;
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Imagen subida al servidor correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // Upload failed - show retry dialog
          if (!context.mounted) return false;

          final retry = await _showUploadErrorDialog(context, processedBytes);

          if (retry == null || retry == _UploadRetryAction.cancel) {
            // User cancelled - don't save anything
            return false;
          } else if (retry == _UploadRetryAction.saveLocal) {
            // Save locally instead
            break;
          }
          // If retry == _UploadRetryAction.retry, loop continues
        }
      }
    }

    // Save to local cache (both for "save local" and "upload to server")
    await ImageCacheService().cacheImage(cacheKey, processedBytes);

    return true;
  }

  /// Shows a bottom sheet to pick between camera and gallery.
  Future<ImageSource?> _showSourcePicker(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Seleccionar de galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a preview dialog with the processed image and save/upload options.
  Future<_UploadAction?> _showPreviewDialog(
    BuildContext context,
    List<int> imageBytes,
  ) {
    return showDialog<_UploadAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vista previa'),
        content: SizedBox(
          width: 300,
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                Uint8List.fromList(imageBytes),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _UploadAction.saveLocal),
            child: const Text('Guardar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, _UploadAction.uploadToServer),
            child: const Text('Subir al servidor'),
          ),
        ],
      ),
    );
  }

  /// Shows error dialog with image preview and retry/save/cancel options.
  Future<_UploadRetryAction?> _showUploadErrorDialog(
    BuildContext context,
    List<int> imageBytes,
  ) {
    return showDialog<_UploadRetryAction>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Error al subir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    Uint8List.fromList(imageBytes),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No se pudo subir la imagen al servidor.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _UploadRetryAction.cancel),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _UploadRetryAction.saveLocal),
            child: const Text('Guardar local'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, _UploadRetryAction.retry),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

}

/// Actions available in the preview dialog.
enum _UploadAction { saveLocal, uploadToServer }

/// Actions for upload error retry dialog.
enum _UploadRetryAction { retry, saveLocal, cancel }

/// Top-level function for isolate: resize image to 768x1024 and encode as base64 PNG.
String _processImageIsolate(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw Exception('Failed to decode image');
  final resized = img.copyResize(decoded, width: 768, height: 1024);
  final pngBytes = img.encodePng(resized);
  return base64Encode(pngBytes);
}
