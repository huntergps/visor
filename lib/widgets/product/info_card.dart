import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_colors.dart';
import '../../core/app_sizes.dart';
import '../../core/app_text_styles.dart';
import '../../models/product.dart';
import '../../services/app_config_service.dart';
import '../../services/scanner_service.dart';
import 'presentations_card.dart';
import 'price_row.dart';

/// Standalone search bar widget for mobile layout
class ProductSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final VoidCallback? onClear;
  final String? currentBarcode;

  const ProductSearchBar({
    super.key,
    required this.onSearch,
    this.onClear,
    this.currentBarcode,
  });

  @override
  State<ProductSearchBar> createState() => ProductSearchBarState();
}

class ProductSearchBarState extends State<ProductSearchBar> {
  late TextEditingController _searchController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Focus the field but hide soft keyboard (ready for hardware scanner input)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
        if (AppSizes.isMobile) {
          SystemChannels.textInput.invokeMethod('TextInput.hide');
        }
      }
    });
  }

  @override
  void didUpdateWidget(ProductSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentBarcode != widget.currentBarcode) {
      _searchController.clear();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitSearch() {
    final text = _searchController.text.toUpperCase();
    if (text.isEmpty) return;
    widget.onSearch(text);
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
    _focusNode.requestFocus();
  }

  void _toggleKeyboard() {
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    if (keyboardVisible) {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    } else {
      _focusNode.requestFocus();
      SystemChannels.textInput.invokeMethod('TextInput.show');
    }
  }

  Future<void> _openScanner() async {
    final code = await ScannerService.scan(context);
    if (!mounted) return;
    if (code != null) {
      _searchController.text = code;
      widget.onSearch(code.toUpperCase());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppSizes.isMobile;
    final iconSize = isMobile ? 24.0 : 28.0;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    final boxDecoration = BoxDecoration(
      color: const Color(0x99FFFFFF),
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      boxShadow: const [
        BoxShadow(
          color: Color(0x149F2A2A),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    );

    return Container(
      decoration: boxDecoration,
      padding: EdgeInsets.all(AppSizes.paddingSmall),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: AppColors.textSecondary,
            size: iconSize,
          ),
          SizedBox(width: AppSizes.paddingXSmall),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              autofocus: false,
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => _submitSearch(),
              decoration: InputDecoration(
                hintText: 'Digitar código del producto...',
                hintStyle: AppTextStyles.searchHint,
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: AppTextStyles.searchInput,
            ),
          ),
          if (isMobile)
            IconButton(
              icon: Icon(
                keyboardVisible ? Icons.keyboard_hide : Icons.keyboard,
                color: keyboardVisible ? AppColors.brandPrimary : AppColors.textSecondary,
                size: iconSize,
              ),
              onPressed: _toggleKeyboard,
            ),
          if (isMobile &&
              AppConfigService().scannerStyle == 'inline')
            IconButton(
              icon: Icon(Icons.camera_alt, color: AppColors.brandPrimary, size: iconSize),
              onPressed: _openScanner,
            ),
          IconButton(
            icon: Icon(Icons.close, color: AppColors.textSecondary, size: iconSize),
            onPressed: () {
              _searchController.clear();
              _focusNode.requestFocus();
              widget.onClear?.call();
            },
          ),
          if (!isMobile)
            IconButton(
              icon: Icon(
                Icons.arrow_forward,
                color: AppColors.brandPrimary,
                size: iconSize,
              ),
              onPressed: _submitSearch,
            ),
        ],
      ),
    );
  }
}

/// Info card that shows product details. Can optionally include search bar.
class InfoCard extends StatefulWidget {
  final Product product;
  final Function(String) onSearch;
  final VoidCallback? onClear;
  final bool showSearchBar;
  final bool useExpanded;

  const InfoCard({
    super.key,
    required this.product,
    required this.onSearch,
    this.onClear,
    this.showSearchBar = true,
    this.useExpanded = true,
  });

  @override
  State<InfoCard> createState() => _InfoCardState();
}

class _InfoCardState extends State<InfoCard> {
  late TextEditingController _searchController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void didUpdateWidget(InfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.barcode != widget.product.barcode) {
      _searchController.clear();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitSearch() {
    final text = _searchController.text.toUpperCase();
    if (text.isEmpty) return;
    widget.onSearch(text);
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
    _focusNode.requestFocus();
  }

  Widget _wrapExpanded({required Widget child}) {
    if (widget.useExpanded) {
      return Expanded(child: child);
    }
    return child;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final discount = product.bestDiscount;
    final isMobile = AppSizes.isMobile;
    final iconSize = isMobile ? 24.0 : 28.0;

    final boxDecoration = BoxDecoration(
      color: const Color(0x99FFFFFF),
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      boxShadow: const [
        BoxShadow(
          color: Color(0x149F2A2A),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    );

    return Column(
      children: [
        // Search Bar (only on desktop — mobile uses external ProductSearchBar)
        if (widget.showSearchBar) ...[
          Container(
            decoration: boxDecoration,
            padding: EdgeInsets.all(AppSizes.paddingSmall),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                  size: iconSize,
                ),
                SizedBox(width: AppSizes.paddingXSmall),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    onSubmitted: (_) => _submitSearch(),
                    decoration: InputDecoration(
                      hintText: 'Digitar código del producto...',
                      hintStyle: AppTextStyles.searchHint,
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: AppTextStyles.searchInput,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.textSecondary, size: iconSize),
                  onPressed: () {
                    _searchController.clear();
                    _focusNode.requestFocus();
                    widget.onClear?.call();
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.arrow_forward,
                    color: AppColors.brandPrimary,
                    size: iconSize,
                  ),
                  onPressed: _submitSearch,
                ),
              ],
            ),
          ),
          SizedBox(height: AppSizes.paddingMedium),
        ],

        // Info Panel - Fully scrollable
        _wrapExpanded(
          child: Container(
            width: double.infinity,
            decoration: boxDecoration,
            padding: EdgeInsets.symmetric(
              vertical: AppSizes.paddingSmall,
              horizontal: isMobile ? AppSizes.paddingSmall : AppSizes.paddingXXLarge,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSizes.paddingXSmall),
                  // Product name
                  if (isMobile)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        product.name,
                        style: AppTextStyles.productName,
                        maxLines: 1,
                      ),
                    )
                  else
                    Text(
                      product.name,
                      style: AppTextStyles.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  SizedBox(height: AppSizes.paddingXSmall),

                  // Code - Family Row
                  isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Código: ${product.barcode}',
                              style: AppTextStyles.productCode,
                            ),
                            if (product.family.isNotEmpty)
                              Text(
                                'Familia: ${product.family}',
                                style: AppTextStyles.productFamily,
                              ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Código: ${product.barcode}',
                              style: AppTextStyles.productCode,
                            ),
                            if (product.family.isNotEmpty)
                              Text(
                                'Familia: ${product.family}',
                                style: AppTextStyles.productFamily,
                              ),
                          ],
                        ),

                  SizedBox(height: AppSizes.paddingSmall),

                  // Price Row
                  PriceRow(
                    priceOld: product.regularPrice,
                    priceFinal: product.finalPrice,
                    discountPercent: discount?.percent.toInt() ?? 0,
                    hasDiscount: product.hasDiscount,
                  ),

                  if (product.unitLabel.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(
                        product.unitLabel,
                        style: AppTextStyles.unitLabelSmall,
                      ),
                    ),

                  // Other presentations
                  if (product.presentations.isNotEmpty)
                    PresentationsCard(
                      presentations: product.presentations,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
