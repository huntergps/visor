import 'dart:async';
import 'package:flutter/material.dart';

import '../models/visor_config.dart';
import '../services/visor_config_service.dart';
import '../services/app_config_service.dart';
import '../widgets/common/cached_image.dart';

class AdsView extends StatefulWidget {
  const AdsView({super.key});

  @override
  State<AdsView> createState() => _AdsViewState();
}

class _AdsViewState extends State<AdsView> with WidgetsBindingObserver {
  late final PageController _pageController;
  int _currentPage = 0;
  List<String> _images = [];
  int _adsDuration = 5;
  Timer? _autoSlideTimer;
  final Set<String> _failedImages = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController();
    _loadConfig();
  }

  void _loadConfig() {
    final config = VisorConfigService().getConfig();
    final newImages = config.images;

    _adsDuration = AppConfigService().adsDuration;
    if (_adsDuration <= 0) _adsDuration = 5;

    if (mounted) {
      setState(() {
        _images = List.from(newImages);
        if (_currentPage >= _images.length) {
          _currentPage = 0;
        }
      });
      _startAutoSlide();
    }
  }

  void _onImageFailed(String source) {
    if (!mounted || _failedImages.contains(source)) return;
    _failedImages.add(source);

    setState(() {
      _images.removeWhere((img) => _failedImages.contains(img));
      if (_images.isEmpty) {
        _images = List.from(VisorConfig.defaultImages);
        _failedImages.clear();
      }
      _currentPage = _currentPage.clamp(0, _images.length - 1);
    });

    if (_pageController.hasClients && _images.isNotEmpty) {
      _pageController.jumpToPage(_currentPage);
    }
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _stopAutoSlide();
    if (_images.isEmpty) return;

    _autoSlideTimer = Timer.periodic(Duration(seconds: _adsDuration), (_) {
      if (!mounted || _images.isEmpty) return;

      final safeCurrent = _currentPage.clamp(0, _images.length - 1);
      final nextPage = (safeCurrent + 1) % _images.length;

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopAutoSlide();
    } else if (state == AppLifecycleState.resumed) {
      _startAutoSlide();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAutoSlide();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_images.isEmpty) {
      return Container(color: Colors.white);
    }

    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() => _currentPage = index);
      },
      itemCount: _images.length,
      itemBuilder: (context, index) {
        final imagePath = _images[index];

        return CachedImage(
          source: imagePath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            // Schedule removal of failed image for next frame
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _onImageFailed(imagePath);
            });
            // Show blank while transitioning
            return Container(color: Colors.white);
          },
        );
      },
    );
  }
}
