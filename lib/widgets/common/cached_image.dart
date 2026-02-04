import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../services/image_cache_service.dart';

/// State of image loading
enum _ImageState { loading, loaded, asset, error }

/// A widget that displays an image with local caching support.
/// Supports URLs, Base64 strings, and local assets.
class CachedImage extends StatefulWidget {
  final String source;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const CachedImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
  });

  @override
  State<CachedImage> createState() => _CachedImageState();
}

class _CachedImageState extends State<CachedImage> {
  _ImageState _state = _ImageState.loading;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    // Early mounted check
    if (!mounted) return;

    final source = widget.source;

    // Early return for empty sources
    if (source.isEmpty) {
      _updateState(_ImageState.error, null);
      return;
    }

    // Check if already have the right bytes cached in memory
    if (_imageBytes != null && _state == _ImageState.loaded) {
      return;
    }

    _updateState(_ImageState.loading, null);

    try {
      final cacheService = ImageCacheService();

      if (source.startsWith('cached:')) {
        // Pre-cached image - load directly by cache key
        final cacheKey = source.substring(7); // Remove "cached:" prefix
        final bytes = await cacheService.getCachedImage(cacheKey, ignoreTTL: true);
        if (!mounted) return;
        _updateState(bytes != null ? _ImageState.loaded : _ImageState.error, bytes);
      } else if (source.startsWith('http')) {
        // Network image - fetch with caching
        final bytes = await cacheService.fetchAndCache(source);
        if (!mounted) return;
        _updateState(bytes != null ? _ImageState.loaded : _ImageState.error, bytes);
      } else if (source.startsWith('assets/')) {
        // Asset image - no caching needed
        _updateState(_ImageState.asset, null);
      } else if (source.length > 100 || source.startsWith('data:image')) {
        // Base64: long strings or data URI format
        final bytes = await cacheService.cacheBase64(source);
        if (!mounted) return;
        _updateState(bytes != null ? _ImageState.loaded : _ImageState.error, bytes);
      } else {
        // Short non-URL, non-asset strings are likely invalid
        _updateState(_ImageState.error, null);
      }
    } catch (e) {
      if (!mounted) return;
      _updateState(_ImageState.error, null);
    }
  }

  /// Single setState call for all state updates
  void _updateState(_ImageState newState, Uint8List? bytes) {
    if (!mounted) return;
    setState(() {
      _state = newState;
      _imageBytes = bytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _ImageState.loading:
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );

      case _ImageState.error:
        if (widget.errorBuilder != null) {
          return widget.errorBuilder!(
            context,
            Exception('Failed to load image'),
            null,
          );
        }
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: const Center(
            child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
          ),
        );

      case _ImageState.asset:
        return Image.asset(
          widget.source,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          errorBuilder: widget.errorBuilder,
        );

      case _ImageState.loaded:
        if (_imageBytes != null) {
          return Image.memory(
            _imageBytes!,
            fit: widget.fit,
            width: widget.width,
            height: widget.height,
            errorBuilder: widget.errorBuilder,
          );
        }
        return SizedBox(width: widget.width, height: widget.height);
    }
  }
}
