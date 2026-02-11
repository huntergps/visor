import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../models/product.dart';
import '../../core/app_sizes.dart';
import 'info_card.dart';
import 'product_card.dart';

class MainContent extends StatelessWidget {
  final Product product;
  final bool imageLoading;
  final Function(String) onSearch;
  final VoidCallback? onClear;
  final VoidCallback? onTakePhoto;
  final bool showSearchBar;
  final VoidCallback? onSearchDone;

  const MainContent({
    super.key,
    required this.product,
    this.imageLoading = false,
    required this.onSearch,
    this.onClear,
    this.onTakePhoto,
    this.showSearchBar = true,
    this.onSearchDone,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = AppSizes.isMobile;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMedium,
        vertical: AppSizes.paddingXSmall,
      ),
      child: isMobile ? _buildMobileLayout(context) : _buildDesktopLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 40, child: ProductCard(product: product, imageLoading: imageLoading, onTakePhoto: onTakePhoto)),
        SizedBox(width: AppSizes.paddingMedium),
        Expanded(
          flex: 60,
          child: InfoCard(product: product, onSearch: onSearch, onClear: onClear),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Column(
      children: [
        if (showSearchBar) ...[
          ProductSearchBar(
            onSearch: (query) {
              onSearch(query);
              onSearchDone?.call();
            },
            onClear: () {
              onClear?.call();
              onSearchDone?.call();
            },
            currentBarcode: product.barcode,
          ),
          SizedBox(height: AppSizes.paddingXSmall),
        ],
        // Scrollable content: info + image
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(bottom: keyboardHeight),
            child: Column(
              children: [
                InfoCard(
                  product: product,
                  onSearch: onSearch,
                  onClear: onClear,
                  showSearchBar: false,
                  useExpanded: false,
                ),
                SizedBox(height: AppSizes.paddingXSmall),
                SizedBox(
                  height: 40.h,
                  child: ProductCard(product: product, imageLoading: imageLoading, onTakePhoto: onTakePhoto),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
