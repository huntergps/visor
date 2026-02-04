import 'dart:async';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
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
        _images = newImages;
        // Reset current page if out of bounds
        if (_currentPage >= _images.length) {
          _currentPage = 0;
        }
      });
      _startAutoSlide();
    }
  }

  void _startAutoSlide() {
    _stopAutoSlide();
    if (_images.isEmpty) return;

    _autoSlideTimer = Timer.periodic(Duration(seconds: _adsDuration), (_) {
      if (!mounted || _images.isEmpty) return;

      // Ensure currentPage is within bounds before calculating next
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
    // Pause timer when app is backgrounded
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
          errorBuilder: _errorBuilder,
        );
      },
    );
  }

  Widget _errorBuilder(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return Container(
      color: AppColors.brandPrimary,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 100,
          color: Colors.white,
        ),
      ),
    );
  }
}
