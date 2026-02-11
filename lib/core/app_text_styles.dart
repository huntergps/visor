import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'app_colors.dart';
import 'app_sizes.dart';

/// Centralized text styles using locally bundled Open Sans font.
/// This eliminates the google_fonts network dependency.
class AppTextStyles {
  AppTextStyles._();

  static const String _fontFamily = 'OpenSans';

  static bool get _mobile => AppSizes.isMobile;

  // Header styles
  static TextStyle get headerTitle => TextStyle(
    fontFamily: _fontFamily,
    fontSize: _mobile ? 22.sp : 42,
    fontWeight: FontWeight.w700,
    color: const Color(0xFFA01438),
  );

  static TextStyle get headerDivider => TextStyle(
    fontFamily: _fontFamily,
    fontSize: _mobile ? 22.sp : 42,
    fontWeight: FontWeight.w300,
    color: const Color(0x80A01438),
  );

  static TextStyle get headerDividerSmall => TextStyle(
    fontFamily: _fontFamily,
    fontSize: _mobile ? 18.sp : 36,
    fontWeight: FontWeight.w300,
    color: const Color(0x80A01438),
  );

  static TextStyle get headerSlogan => TextStyle(
    fontFamily: _fontFamily,
    fontSize: _mobile ? 16.sp : 32,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    color: const Color(0xFFA01438),
  );

  // Mobile-specific header styles (smaller, 2-line layout)
  static TextStyle get headerTitleMobile => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: Color(0xFFA01438),
  );

  static TextStyle get headerDividerMobile => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w300,
    color: Color(0x80A01438),
  );

  static TextStyle get headerSloganMobile => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    color: Color(0xFFA01438),
  );

  // Price styles
  static TextStyle get priceMain => TextStyle(
    fontFamily: _fontFamily,
    fontSize: _mobile ? 36.sp : 64,
    fontWeight: FontWeight.w700,
    color: AppColors.priceFinal,
  );

  static TextStyle get priceOld => TextStyle(
    fontFamily: _fontFamily,
    fontSize: _mobile ? 24.sp : 42,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF4B4B60),
    letterSpacing: -0.5,
  );

  static TextStyle get priceFinal => TextStyle(
    fontFamily: _fontFamily,
    fontSize: _mobile ? 38.sp : 68,
    fontWeight: FontWeight.w700,
    color: const Color(0xFFC62828),
    letterSpacing: -2.0,
  );

  static TextStyle get priceLabel => TextStyle(
    fontFamily: _fontFamily,
    fontSize: _mobile ? 14.sp : 18,
    fontWeight: FontWeight.w700,
    color: Colors.black,
  );

  static TextStyle get unitLabel => TextStyle(
    fontFamily: _fontFamily,
    fontSize: _mobile ? 20.sp : 34,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static TextStyle get unitLabelSmall => TextStyle(
    fontFamily: _fontFamily,
    fontSize: _mobile ? 14.sp : 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  // Discount badge
  static TextStyle get discountBadgeTitle => TextStyle(
    fontFamily: 'Inter',
    fontSize: _mobile ? 14.sp : 20,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );

  static TextStyle get discountBadgePercent => TextStyle(
    fontFamily: 'Inter',
    fontSize: _mobile ? 20.sp : 32,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF6D3200),
  );

  static TextStyle get discountPill => TextStyle(
    fontFamily: _fontFamily,
    fontSize: _mobile ? 24.sp : 38,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  // Product info
  static TextStyle get productName => TextStyle(
    fontFamily: _fontFamily,
    fontSize: _mobile ? 22.sp : 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textTitle,
    height: 1.1,
  );

  static TextStyle get productCode => TextStyle(
    fontFamily: _fontFamily,
    fontSize: _mobile ? 15.sp : 20,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF6B7280),
  );

  static TextStyle get productFamily => TextStyle(
    fontFamily: _fontFamily,
    fontSize: _mobile ? 15.sp : 20,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF6B7280),
  );

  // Search field
  static TextStyle get searchHint => TextStyle(
    fontFamily: _fontFamily,
    fontSize: _mobile ? 15.sp : 16,
    color: AppColors.textSecondary,
  );

  static TextStyle get searchInput => TextStyle(
    fontFamily: _fontFamily,
    fontSize: _mobile ? 17.sp : 18,
    color: AppColors.textPrimary,
  );

  // Presentations
  static TextStyle get presentationLabel => TextStyle(
    fontFamily: _fontFamily,
    fontSize: _mobile ? 14.sp : 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get presentationPriceOld => TextStyle(
    fontFamily: _fontFamily,
    fontSize: _mobile ? 12.sp : 14,
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.lineThrough,
    color: AppColors.textSecondary,
  );

  static TextStyle get presentationDiscount => TextStyle(
    fontFamily: _fontFamily,
    fontSize: _mobile ? 11.sp : 12,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static TextStyle get presentationPrice => TextStyle(
    fontFamily: _fontFamily,
    fontSize: _mobile ? 17.sp : 22,
    fontWeight: FontWeight.w700,
    color: AppColors.priceFinal,
  );

  // Footer
  static TextStyle get footerText => TextStyle(
    fontFamily: _fontFamily,
    fontSize: _mobile ? 16.sp : 16,
    fontWeight: FontWeight.w500,
    color: const Color.fromARGB(255, 50, 50, 55),
  );

  // Helper to create custom style based on OpenSans
  static TextStyle custom({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    FontStyle fontStyle = FontStyle.normal,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
    );
  }
}
