import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized text styles using locally bundled Open Sans font.
/// This eliminates the google_fonts network dependency.
class AppTextStyles {
  AppTextStyles._();

  static const String _fontFamily = 'OpenSans';

  // Header styles
  static const TextStyle headerTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 42,
    fontWeight: FontWeight.w700,
    color: Color(0xFFA01438),
  );

  static const TextStyle headerDivider = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 42,
    fontWeight: FontWeight.w300,
    color: Color(0x80A01438), // 50% opacity
  );

  static const TextStyle headerDividerSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w300,
    color: Color(0x80A01438),
  );

  static const TextStyle headerSlogan = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    color: Color(0xFFA01438),
  );

  // Price styles
  static const TextStyle priceMain = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 64,
    fontWeight: FontWeight.w700,
    color: AppColors.priceFinal,
  );

  static const TextStyle priceOld = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 42,
    fontWeight: FontWeight.w600,
    color: Color(0xFF4B4B60),
    letterSpacing: -0.5,
  );

  static const TextStyle priceFinal = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 68,
    fontWeight: FontWeight.w700,
    color: Color(0xFFC62828),
    letterSpacing: -2.0,
  );

  static const TextStyle priceLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: Colors.black,
  );

  static const TextStyle unitLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 34,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static const TextStyle unitLabelSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  // Discount badge
  static const TextStyle discountBadgeTitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );

  static const TextStyle discountBadgePercent = TextStyle(
    fontFamily: 'Inter',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: Color(0xFF6D3200),
  );

  static const TextStyle discountPill = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 38,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  // Product info
  static const TextStyle productName = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28, // AppSizes.fontH2
    fontWeight: FontWeight.w700,
    color: AppColors.textTitle,
    height: 1.1,
  );

  static const TextStyle productCode = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: Color(0xFF6B7280),
  );

  static const TextStyle productFamily = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Color(0xFF6B7280),
  );

  // Search field
  static const TextStyle searchHint = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16, // AppSizes.fontBody
    color: AppColors.textSecondary,
  );

  static const TextStyle searchInput = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18, // AppSizes.fontBodyLg
    color: AppColors.textPrimary,
  );

  // Presentations
  static const TextStyle presentationLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle presentationPriceOld = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.lineThrough,
    color: AppColors.textSecondary,
  );

  static const TextStyle presentationDiscount = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle presentationPrice = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.priceFinal,
  );

  // Footer
  static const TextStyle footerText = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
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
