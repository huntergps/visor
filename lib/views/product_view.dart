import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/product.dart';
import '../widgets/common/footer_bar.dart';
import '../widgets/common/header_bar.dart';
import '../widgets/product/main_content.dart';

import '../widgets/lava_lamp_background.dart';

/// Floating logo widget - extracted to avoid rebuilds
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
    boxShadow: const [
      BoxShadow(
        color: Color(0x1A000000), // 0.1 alpha black
        blurRadius: 10,
      ),
    ],
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

class ProductView extends StatelessWidget {
  final Product product;
  final bool imageLoading;
  final Function(String) onSearch;
  final VoidCallback? onClear;

  const ProductView({
    super.key,
    required this.product,
    this.imageLoading = false,
    required this.onSearch,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return LavaLampBackground(
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const HeaderBar(),
                Expanded(
                  child: MainContent(product: product, imageLoading: imageLoading, onSearch: onSearch, onClear: onClear),
                ),
                const FooterBar(),
              ],
            ),
            const _FloatingLogo(),
          ],
        ),
      ),
    );
  }
}
