import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_sizes.dart';
import '../../core/app_text_styles.dart';
import '../../models/product.dart';
import 'presentations_card.dart';
import 'price_row.dart';

class InfoCard extends StatefulWidget {
  final Product product;
  final Function(String) onSearch;
  final VoidCallback? onClear;

  const InfoCard({
    super.key,
    required this.product,
    required this.onSearch,
    this.onClear,
  });

  @override
  State<InfoCard> createState() => _InfoCardState();
}

class _InfoCardState extends State<InfoCard> {
  late TextEditingController _searchController;

  // Static decoration - reused across all instances
  static final _boxDecoration = BoxDecoration(
    color: const Color(0x99FFFFFF), // AppColors.surface with 0.6 alpha
    borderRadius: BorderRadius.circular(AppSizes.radiusCard),
    boxShadow: const [
      BoxShadow(
        color: Color(0x149F2A2A), // 0.08 alpha
        blurRadius: 18,
        offset: Offset(0, 8),
      ),
    ],
  );

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void didUpdateWidget(InfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear search field when product changes
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
    // Select all text and return focus so next scan replaces it
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final discount = product.bestDiscount;

    return Column(
      children: [
        // Top Panel: Search Bar
        Container(
          decoration: _boxDecoration,
          padding: const EdgeInsets.all(AppSizes.paddingSmall),
          child: Row(
            children: [
              const Icon(
                Icons.search,
                color: AppColors.textSecondary,
                size: 28,
              ),
              const SizedBox(width: AppSizes.paddingXSmall),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
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
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () {
                  _searchController.clear();
                  _focusNode.requestFocus();
                  widget.onClear?.call();
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.arrow_forward,
                  color: AppColors.brandPrimary,
                ),
                onPressed: _submitSearch,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSizes.paddingMedium),

        // Bottom Panel: Existing Info - Fully scrollable
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: _boxDecoration,
            padding: const EdgeInsets.symmetric(
              vertical: AppSizes.paddingSmall,
              horizontal: AppSizes.paddingXXLarge,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSizes.paddingXSmall),
                  // Product name
                  Text(
                    product.name,
                    style: AppTextStyles.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: AppSizes.paddingXSmall),

                  // Code - Family Row
                  Row(
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

                  const SizedBox(height: AppSizes.paddingSmall),

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
