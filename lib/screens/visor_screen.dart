import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../views/ads_view.dart';
import '../views/product_view.dart';

import '../providers/visor_provider.dart';

class VisorScreen extends StatelessWidget {
  const VisorScreen({super.key});

  // Fixed dimensions for main container
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
        color: Color(0x4D000000), // 0.3 alpha black
        blurRadius: 20,
        spreadRadius: 5,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D2D2D),
      body: Center(
        child: Container(
          width: _containerWidth,
          height: _containerHeight,
          decoration: _containerDecoration,
          clipBehavior: Clip.antiAlias,
          child: Consumer<VisorProvider>(
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
          ),
        ),
      ),
    );
  }
}
