import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../core/app_colors.dart';
import '../core/app_sizes.dart';
import '../services/hardware_scanner_service.dart';
import '../services/image_upload_service.dart';
import '../views/ads_view.dart';
import '../views/product_view.dart';

import '../providers/visor_provider.dart';
import '../widgets/common/window_title_bar.dart';
import '../widgets/lava_lamp_background.dart';

class VisorScreen extends StatefulWidget {
  const VisorScreen({super.key});

  @override
  State<VisorScreen> createState() => _VisorScreenState();
}

class _VisorScreenState extends State<VisorScreen> {
  // Fixed dimensions for desktop container
  static const double _containerWidth = 1366;
  static const double _containerHeight = 768;

  // Static decoration - avoids recreation on every build
  static final _containerDecoration = BoxDecoration(
    color: Colors.white,
    border: Border.all(color: const Color(0xFF808080), width: 3),
    boxShadow: const [
      BoxShadow(
        color: Color.fromARGB(255, 255, 255, 255),
        blurRadius: 20,
        spreadRadius: 5,
      ),
    ],
  );

  // Keyboard capture for barcode scanner
  final FocusNode _screenFocusNode = FocusNode();
  String _keyboardBuffer = '';
  VisorViewState? _lastViewState;

  // Hardware scanner (Zebra DataWedge) — Android only, no-op on other platforms
  StreamSubscription<String>? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _scanSubscription = HardwareScannerService.scanStream.listen((barcode) {
      if (!mounted) return;
      context.read<VisorProvider>().searchProduct(barcode.toUpperCase());
    });
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _screenFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final provider = context.read<VisorProvider>();

    // Ignore all input during loading
    if (provider.viewState == VisorViewState.loading) {
      return KeyEventResult.handled;
    }

    final isAds = provider.viewState == VisorViewState.ads;
    final isMobile = Device.screenType == ScreenType.mobile;

    // On desktop: only intercept during ads or while completing a buffered scan
    // On mobile: always intercept hardware keyboard input (barcode scanners)
    if (!isMobile && !isAds && _keyboardBuffer.isEmpty) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (_keyboardBuffer.isNotEmpty) {
        final query = _keyboardBuffer.toUpperCase();
        _keyboardBuffer = '';
        provider.searchProduct(query);
      } else if (isAds) {
        provider.showProductView();
      }
      return KeyEventResult.handled;
    }

    final char = event.character;
    if (char != null && char.isNotEmpty && char.codeUnitAt(0) >= 32) {
      _keyboardBuffer += char;
      if (isAds) provider.showProductView();
      return KeyEventResult.handled;
    }

    // Any other key during ads (arrows, function keys, etc.)
    if (isAds) {
      provider.showProductView();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    // Use desktop layout only on actual desktop platforms (not tablets)
    if (!AppSizes.isDesktop) {
      return Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        body: Focus(
          focusNode: _screenFocusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: SizedBox(width: 100.w, height: 100.h, child: _buildContent()),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Focus(
        focusNode: _screenFocusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: LavaLampBackground(
          child: Stack(
            children: [
              Center(
                child: Container(
                  width: _containerWidth,
                  height: _containerHeight,
                  decoration: _containerDecoration,
                  clipBehavior: Clip.antiAlias,
                  child: _buildContent(),
                ),
              ),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: WindowTitleBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleTakePhoto(
    BuildContext context,
    VisorProvider provider,
  ) async {
    final product = provider.currentProduct;
    if (product.barcode.isEmpty) return;

    if (product.id == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo obtener el ID del producto'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final productId = product.id.toString();

    // Pause idle timer during image editing to prevent ads from showing
    provider.pauseIdleTimer();

    try {
      final success = await ImageUploadService().captureAndProcess(
        context,
        productId,
      );
      if (success) {
        await provider.refreshProductImage(product.barcode);
      }
    } finally {
      // Resume idle timer after editing (whether success or cancel)
      provider.resumeIdleTimer();
    }
  }

  Widget _buildLoadingView(VisorProvider provider) {
    final progress = provider.loadingTotalGroups > 0
        ? provider.loadingCurrentGroup / provider.loadingTotalGroups
        : 0.0;

    return Container(
      key: const ValueKey('loading'),
      color: Colors.white,
      child: Center(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.storefront_rounded,
                size: 64,
                color: AppColors.brandPrimary,
              ),
              const SizedBox(height: 16),
              Text(
                'Visor de Precios',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTitle,
                ),
              ),
              const SizedBox(height: 32),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.brandPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                provider.loadingStatus,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<VisorProvider>(
      builder: (context, provider, child) {
        // Re-capture keyboard focus when ads start showing
        if (provider.viewState == VisorViewState.ads &&
            _lastViewState != VisorViewState.ads) {
          _keyboardBuffer = '';
        }
        _lastViewState = provider.viewState;
        if (provider.viewState == VisorViewState.ads) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_screenFocusNode.hasFocus) {
              _screenFocusNode.requestFocus();
            }
          });
        } else if (provider.viewState == VisorViewState.product &&
            AppSizes.isDesktop) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _screenFocusNode.hasFocus) {
              _screenFocusNode.nextFocus();
            }
          });
        }

        return GestureDetector(
          onTap: provider.viewState == VisorViewState.loading
              ? null
              : () => provider.showProductView(),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: switch (provider.viewState) {
              VisorViewState.loading => _buildLoadingView(provider),
              VisorViewState.ads => AdsView(key: const ValueKey('ads')),
              VisorViewState.product => ProductView(
                key: const ValueKey('product'),
                product: provider.currentProduct,
                imageLoading: provider.imageLoading,
                onSearch: (query) => provider.searchProduct(query),
                onClear: () => provider.resetProduct(),
                onTakePhoto:
                    !Platform.isMacOS &&
                        provider.isEditor &&
                        provider.currentProduct.barcode.isNotEmpty
                    ? () => _handleTakePhoto(context, provider)
                    : null,
              ),
            },
          ),
        );
      },
    );
  }
}
