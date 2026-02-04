import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

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
                  ),
          ),
        );
      },
    );
  }
}
