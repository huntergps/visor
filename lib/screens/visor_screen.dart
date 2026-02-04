import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../services/image_upload_service.dart';
import '../views/ads_view.dart';
import '../views/product_view.dart';

import '../providers/visor_provider.dart';

class VisorScreen extends StatelessWidget {
  const VisorScreen({super.key});

  // Fixed dimensions for desktop container
  static const double _containerWidth = 1366;
  static const double _containerHeight = 768;

  // Static decoration - avoids recreation on every build
  static final _containerDecoration = BoxDecoration(
    color: Colors.white,
    border: Border.all(
      color: const Color(0xFF808080),
      width: 3,
    ),
    boxShadow: const [
      BoxShadow(
        color: Color(0x4D000000),
        blurRadius: 20,
        spreadRadius: 5,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final isMobile = Device.screenType == ScreenType.mobile;

    return Scaffold(
      backgroundColor: isMobile ? Colors.white : const Color(0xFF2D2D2D),
      resizeToAvoidBottomInset: false,
      body: Center(
        child: isMobile
            ? SizedBox(
                width: 100.w,
                height: 100.h,
                child: _buildContent(),
              )
            : Container(
                width: _containerWidth,
                height: _containerHeight,
                decoration: _containerDecoration,
                clipBehavior: Clip.antiAlias,
                child: _buildContent(),
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

  Widget _buildContent() {
    return Consumer<VisorProvider>(
      builder: (context, provider, child) {
        return GestureDetector(
          onTap: () => provider.showProductView(),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: provider.viewState == VisorViewState.ads
                ? AdsView(key: const ValueKey('ads'))
                : ProductView(
                    key: const ValueKey('product'),
                    product: provider.currentProduct,
                    imageLoading: provider.imageLoading,
                    onSearch: (query) => provider.searchProduct(query),
                    onClear: () => provider.resetProduct(),
                    onTakePhoto: provider.currentProduct.barcode.isNotEmpty
                        ? () => _handleTakePhoto(context, provider)
                        : null,
                  ),
          ),
        );
      },
    );
  }
}
