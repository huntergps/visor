import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_sizes.dart';
import '../../models/product.dart';
import '../common/cached_image.dart';
import 'discount_badge.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final bool imageLoading;

  const ProductCard({
    super.key,
    required this.product,
    this.imageLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final discount = product.bestDiscount;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Product image - takes full space
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(AppSizes.paddingSmall),
              child: _buildProductImage(),
            ),
          ),

          // Discount badge (top-right)
          if (discount != null)
            Positioned(
              top: AppSizes.paddingBase,
              right: AppSizes.paddingBase,
              child: DiscountBadge(percent: discount.percent.toInt()),
            ),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    String? imageSource;

    if (product.imageBase64 != null && product.imageBase64!.isNotEmpty) {
      imageSource = product.imageBase64;
    } else if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
      imageSource = product.imageUrl;
    }

    if (imageSource == null || imageSource.isEmpty) {
      if (imageLoading) {
        return _buildLoadingImage();
      }
      return _buildFallbackImage();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: CachedImage(
        key: ValueKey(imageSource),
        source: imageSource,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
      ),
    );
  }

  Widget _buildLoadingImage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/no_imagen.png', fit: BoxFit.contain),
        Positioned.fill(
          child: Container(
            color: Colors.white.withValues(alpha: 0.6),
            child: Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.brandPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackImage() {
    return Image.asset('assets/no_imagen.png', fit: BoxFit.contain);
  }
}
