import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';
import '../core/app_sizes.dart';
import '../models/product.dart';
import '../services/app_config_service.dart';
import '../services/hardware_scanner_service.dart';
import '../services/scanner_service.dart';
import '../widgets/common/footer_bar.dart';
import '../widgets/common/header_bar.dart';
import '../widgets/product/main_content.dart';

import '../widgets/lava_lamp_background.dart';

/// Floating logo widget - desktop only (positioned over header)
class _FloatingLogo extends StatelessWidget {
  const _FloatingLogo();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 24,
      top: 0,
      child: Image.asset(
        'assets/mepriga_logo.png',
        height: 180,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const _LogoFallback();
        },
      ),
    );
  }
}

/// Fallback widget when logo fails to load
class _LogoFallback extends StatelessWidget {
  const _LogoFallback();

  static final _decoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 10)],
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: 140,
      decoration: _decoration,
      child: const Center(
        child: Text(
          'MP',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: AppColors.brandPrimary,
          ),
        ),
      ),
    );
  }
}

class _DraggableFloatingScanner extends StatefulWidget {
  final Function(String) onSearch;

  const _DraggableFloatingScanner({required this.onSearch});

  @override
  State<_DraggableFloatingScanner> createState() =>
      _DraggableFloatingScannerState();
}

class _DraggableFloatingScannerState extends State<_DraggableFloatingScanner> {
  late double _right;
  late double _bottom;

  @override
  void initState() {
    super.initState();
    final config = AppConfigService();
    _right = config.fabPositionRight;
    _bottom = config.fabPositionBottom;
  }

  void _clampPosition(Size screenSize) {
    const fabSize = 56.0;
    _right = _right.clamp(0.0, screenSize.width - fabSize);
    _bottom = _bottom.clamp(0.0, screenSize.height - fabSize - 100);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    _clampPosition(screenSize);

    return Positioned(
      right: _right,
      bottom: _bottom,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _right -= details.delta.dx;
            _bottom -= details.delta.dy;
            _clampPosition(screenSize);
          });
        },
        onPanEnd: (_) {
          final config = AppConfigService();
          config.setFabPositionRight(_right);
          config.setFabPositionBottom(_bottom);
        },
        onTap: () async {
          final code = await ScannerService.scan(context);
          if (code != null) {
            widget.onSearch(code.toUpperCase());
          }
          // Hide keyboard after returning from scanner
          SystemChannels.textInput.invokeMethod('TextInput.hide');
        },
        child: FloatingActionButton(
          heroTag: 'scanner_fab',
          backgroundColor: AppColors.brandPrimary,
          onPressed: null,
          child: const Icon(Icons.qr_code_scanner, color: Colors.white),
        ),
      ),
    );
  }
}

class ProductView extends StatefulWidget {
  final Product product;
  final bool imageLoading;
  final Function(String) onSearch;
  final VoidCallback? onClear;
  final VoidCallback? onTakePhoto;

  const ProductView({
    super.key,
    required this.product,
    this.imageLoading = false,
    required this.onSearch,
    this.onClear,
    this.onTakePhoto,
  });

  @override
  State<ProductView> createState() => _ProductViewState();
}

class _ProductViewState extends State<ProductView> {
  bool _showSearchBar = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppSizes.isMobile;
    final hasHwScanner = HardwareScannerService.isAvailable;

    return LavaLampBackground(
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const HeaderBar(),
                Expanded(
                  child: MainContent(
                    product: widget.product,
                    imageLoading: widget.imageLoading,
                    onSearch: widget.onSearch,
                    onClear: widget.onClear,
                    onTakePhoto: widget.onTakePhoto,
                    showSearchBar: !hasHwScanner || _showSearchBar,
                    onSearchDone: hasHwScanner
                        ? () => setState(() => _showSearchBar = false)
                        : null,
                  ),
                ),
                FooterBar(
                  onSearchTap: hasHwScanner
                      ? () => setState(() => _showSearchBar = !_showSearchBar)
                      : null,
                ),
              ],
            ),
            if (!isMobile) const _FloatingLogo(),
            if (isMobile &&
                !hasHwScanner &&
                AppConfigService().scannerStyle == 'floating')
              _DraggableFloatingScanner(onSearch: widget.onSearch),
          ],
        ),
      ),
    );
  }
}
