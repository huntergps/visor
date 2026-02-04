import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_sizes.dart';
import '../../core/app_text_styles.dart';
import '../../core/presentation_assets.dart';
import '../../models/presentation_price.dart';

class PresentationsCard extends StatelessWidget {
  final List<PresentationPrice> presentations;

  static const int maxVisible = 5;

  const PresentationsCard({super.key, required this.presentations});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const ColoredBox(
          color: AppColors.divider,
          child: SizedBox(height: 1, width: double.infinity),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < presentations.length && i < maxVisible; i++)
          _PresentationItem(presentation: presentations[i]),
      ],
    );
  }
}

class _PresentationItem extends StatelessWidget {
  final PresentationPrice presentation;

  const _PresentationItem({required this.presentation});

  @override
  Widget build(BuildContext context) {
    final isMobile = AppSizes.isMobile;
    final thumbW = isMobile ? 48.0 : 64.0;
    final thumbH = isMobile ? 32.0 : 42.0;
    final innerPad = isMobile ? 8.0 : 12.0;
    final iconSize = isMobile ? 20.0 : 24.0;

    final itemDecoration = BoxDecoration(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(AppSizes.radiusChip),
      border: Border.all(color: AppColors.divider),
    );

    final thumbnailDecoration = BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
    );

    final discountDecoration = BoxDecoration(
      color: Colors.red,
      borderRadius: BorderRadius.circular(4),
    );

    return Container(
      padding: EdgeInsets.all(innerPad),
      margin: EdgeInsets.only(bottom: isMobile ? 6 : 8),
      decoration: itemDecoration,
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: thumbW,
            height: thumbH,
            decoration: thumbnailDecoration,
            child: Image.asset(
              PresentationAssets.getAssetForLabel(presentation.label),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.inventory_2_outlined,
                color: const Color(0x80757575),
                size: iconSize,
              ),
            ),
          ),

          SizedBox(width: isMobile ? 10 : 16),

          // Name
          Expanded(
            child: Text(
              presentation.label,
              style: AppTextStyles.presentationLabel,
            ),
          ),

          // Price and Discount
          if (presentation.discountPercent > 0)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${(presentation.price + presentation.discountAmount).toStringAsFixed(2)}',
                  style: AppTextStyles.presentationPriceOld,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: discountDecoration,
                  child: Text(
                    '-${presentation.discountPercent.toStringAsFixed(0)}%',
                    style: AppTextStyles.presentationDiscount,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${presentation.price.toStringAsFixed(2)}',
                  style: AppTextStyles.presentationPrice,
                ),
              ],
            )
          else
            Text(
              '\$${presentation.price.toStringAsFixed(2)}',
              style: AppTextStyles.presentationPrice,
            ),

          SizedBox(width: isMobile ? 8 : 12),

          Icon(
            Icons.shopping_cart,
            color: AppColors.brandPrimary,
            size: iconSize,
          ),
        ],
      ),
    );
  }
}
