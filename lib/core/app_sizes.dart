import 'package:sizer/sizer.dart';

class AppSizes {
  static bool get isMobile => Device.screenType == ScreenType.mobile;

  static double get radiusCard => isMobile ? 16.sp : 24;
  static double get radiusBadge => isMobile ? 10.sp : 14;
  static double get radiusChip => isMobile ? 12.sp : 16;
  static double get paddingBase => isMobile ? 16.sp : 24;
  static double get paddingMedium => isMobile ? 14.sp : 20;
  static double get paddingXXLarge => isMobile ? 20.sp : 50;
  static double get paddingSmall => isMobile ? 12.sp : 16;
  static double get paddingXSmall => isMobile ? 8.sp : 12;

  // Typography sizes
  static double get fontH1 => isMobile ? 32.sp : 64; // price final
  static double get fontH2 => isMobile ? 22.sp : 40; // product name
  static double get fontH3 => isMobile ? 20.sp : 36; // price old / discount
  static double get fontBodyLg => isMobile ? 14.sp : 22;
  static double get fontBody => isMobile ? 12.sp : 18;
  static double get fontCaption => isMobile ? 10.sp : 14;
}
