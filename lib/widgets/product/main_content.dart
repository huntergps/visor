import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../core/app_sizes.dart';
import 'info_card.dart';
import 'product_card.dart';

class MainContent extends StatelessWidget {
  final Product product;
  final bool imageLoading;
  final Function(String) onSearch;
  final VoidCallback? onClear;

  const MainContent({
    super.key,
    required this.product,
    this.imageLoading = false,
    required this.onSearch,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMedium,
        vertical: AppSizes.paddingXSmall,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left column: Product Image Card (reduced by ~20%)
          Expanded(flex: 40, child: ProductCard(product: product, imageLoading: imageLoading)),

          const SizedBox(width: AppSizes.paddingMedium),

          // Right column: Info Card
          Expanded(
            flex: 60,
            child: InfoCard(product: product, onSearch: onSearch, onClear: onClear),
          ),
        ],
      ),
    );
  }
}
