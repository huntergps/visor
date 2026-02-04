import 'package:flutter/material.dart';

import '../../core/app_sizes.dart';
import '../../core/app_text_styles.dart';

class PriceRow extends StatelessWidget {
  final double priceOld;
  final double priceFinal;
  final int discountPercent;
  final bool hasDiscount;
  final String unitLabel;

  const PriceRow({
    super.key,
    required this.priceOld,
    required this.priceFinal,
    required this.discountPercent,
    required this.hasDiscount,
    this.unitLabel = '',
  });

  // Static painters - reused across all instances
  static const _gradientArrowPainter = _ThickGradientArrowPainter();
  static const _concaveArrowPainter = _ConcavePlayArrowPainter();

  // Pre-computed decoration for discount pill
  static final _discountPillDecoration = BoxDecoration(
    color: const Color(0xFFD32F2F),
    borderRadius: BorderRadius.circular(8),
    boxShadow: const [
      BoxShadow(
        color: Color(0x40000000),
        blurRadius: 3,
        offset: Offset(1, 1),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final isMobile = AppSizes.isMobile;
    final discountPillStyle = AppTextStyles.discountPill.copyWith(
      shadows: const [
        Shadow(
          offset: Offset(1, 1),
          blurRadius: 2.0,
          color: Color(0x4D000000),
        ),
      ],
    );

    if (!hasDiscount) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '\$${priceOld.toStringAsFixed(2)}',
            style: AppTextStyles.priceMain,
          ),
          if (unitLabel.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(unitLabel, style: AppTextStyles.unitLabel),
          ],
        ],
      );
    }

    // Responsive arrow sizes
    final arrowW1 = isMobile ? 36.0 : 58.0;
    final arrowH1 = isMobile ? 26.0 : 42.0;
    final arrowW2 = isMobile ? 18.0 : 30.0;
    final arrowH2 = isMobile ? 22.0 : 36.0;
    final spacing = isMobile ? 8.0 : 14.0;
    final spacingLg = isMobile ? 10.0 : 16.0;

    if (isMobile) {
      // Mobile: single row, FittedBox shrinks to fit
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Old price
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '\$${priceOld.toStringAsFixed(2)}',
                      style: AppTextStyles.priceOld,
                    ),
                    const Positioned(
                      left: 0,
                      right: 0,
                      child: ColoredBox(
                        color: Color(0xFF4B4B60),
                        child: SizedBox(height: 2, width: double.infinity),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('Antes', style: AppTextStyles.priceLabel),
              ],
            ),
            SizedBox(width: spacing),
            // Arrow
            CustomPaint(
              size: Size(arrowW1, arrowH1),
              painter: _gradientArrowPainter,
            ),
            SizedBox(width: spacing),
            // Discount pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: _discountPillDecoration,
              child: Text('-$discountPercent%', style: discountPillStyle),
            ),
            SizedBox(width: spacingLg),
            // Arrow
            CustomPaint(
              size: Size(arrowW2, arrowH2),
              painter: _concaveArrowPainter,
            ),
            SizedBox(width: spacingLg),
            // Final price
            Text(
              '\$${priceFinal.toStringAsFixed(2)}',
              style: AppTextStyles.priceFinal,
            ),
          ],
        ),
      );
    }

    // Desktop: original single Row
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Old price column
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '\$${priceOld.toStringAsFixed(2)}',
                  style: AppTextStyles.priceOld,
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  child: ColoredBox(
                    color: Color(0xFF4B4B60),
                    child: SizedBox(height: 2.5, width: double.infinity),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text('Antes', style: AppTextStyles.priceLabel),
          ],
        ),

        SizedBox(width: spacing),

        // First Arrow: Thick gradient arrow
        CustomPaint(
          size: Size(arrowW1, arrowH1),
          painter: _gradientArrowPainter,
        ),

        SizedBox(width: spacing),

        // Discount pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: _discountPillDecoration,
          child: Text('-$discountPercent%', style: discountPillStyle),
        ),

        SizedBox(width: spacingLg),

        // Second Arrow: Concave play arrow
        CustomPaint(
          size: Size(arrowW2, arrowH2),
          painter: _concaveArrowPainter,
        ),

        SizedBox(width: spacingLg),

        // Final price
        Text(
          '\$${priceFinal.toStringAsFixed(2)}',
          style: AppTextStyles.priceFinal,
        ),

        if (unitLabel.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(unitLabel, style: AppTextStyles.unitLabel),
        ],
      ],
    );
  }
}

/// Painter for the first thick arrow with gradient
class _ThickGradientArrowPainter extends CustomPainter {
  const _ThickGradientArrowPainter();

  static const _gradient = LinearGradient(
    colors: [Color.fromARGB(255, 220, 103, 101), Color(0xFFC62828)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path();
    final stemHeight = h * 0.45;
    final stemTop = (h - stemHeight) / 2;
    final arrowHeadWidth = w * 0.70;

    path.moveTo(0, stemTop);
    path.lineTo(w - arrowHeadWidth, stemTop);
    path.lineTo(w - arrowHeadWidth, 0);
    path.lineTo(w, h / 2);
    path.lineTo(w - arrowHeadWidth, h);
    path.lineTo(w - arrowHeadWidth, stemTop + stemHeight);
    path.lineTo(0, stemTop + stemHeight);
    path.close();

    final paint = Paint()
      ..shader = _gradient.createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter for the second arrow with concave left side
class _ConcavePlayArrowPainter extends CustomPainter {
  const _ConcavePlayArrowPainter();

  static const _color = Color(0xFFB71C1C);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = _color
      ..style = PaintingStyle.fill;

    final path = Path();

    path.moveTo(w, h / 2);
    path.lineTo(0, h);
    path.quadraticBezierTo(w * 0.3, h / 2, 0, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
