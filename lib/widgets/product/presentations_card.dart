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
        // Use for loop directly instead of toList + spread
        for (var i = 0; i < presentations.length && i < maxVisible; i++)
          _PresentationItem(presentation: presentations[i]),
      ],
    );
  }
}

class _PresentationItem extends StatelessWidget {
  final PresentationPrice presentation;

  const _PresentationItem({required this.presentation});

  // Static decorations
  static final _itemDecoration = BoxDecoration(
    color: AppColors.surfaceAlt,
    borderRadius: BorderRadius.circular(AppSizes.radiusChip),
    border: Border.all(color: AppColors.divider),
  );

  static final _thumbnailDecoration = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(8),
  );

  static final _discountDecoration = BoxDecoration(
    color: Colors.red,
    borderRadius: BorderRadius.circular(4),
  );

  static const _placeholderIcon = Icon(
    Icons.inventory_2_outlined,
    color: Color(0x80757575), // AppColors.textSecondary with 0.5 alpha
    size: 24,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: _itemDecoration,
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 64,
            height: 42,
            decoration: _thumbnailDecoration,
            child: Image.asset(
              PresentationAssets.getAssetForLabel(presentation.label),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => _placeholderIcon,
            ),
          ),

          const SizedBox(width: 16),

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
                  decoration: _discountDecoration,
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

          const SizedBox(width: 12),

          const Icon(
            Icons.shopping_cart,
            color: AppColors.brandPrimary,
            size: 24,
          ),
        ],
      ),
    );
  }
}
