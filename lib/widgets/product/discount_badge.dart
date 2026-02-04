import 'package:flutter/material.dart';

import '../../core/app_text_styles.dart';

class DiscountBadge extends StatelessWidget {
  final int percent;

  const DiscountBadge({super.key, required this.percent});

  // Static painter instance - reused across all badges
  static const _painter = _BadgePainter();

  // Pre-computed style with shadows to avoid copyWith() on every rebuild
  static final _titleStyle = AppTextStyles.discountBadgeTitle.copyWith(
    shadows: const [
      Shadow(
        color: Color(0x4D000000), // 0.3 alpha black
        offset: Offset(0, 2),
        blurRadius: 2,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 108,
      child: CustomPaint(
        painter: _painter,
        child: Column(
          children: [
            // Top section (Gold)
            SizedBox(
              height: 38,
              child: Center(
                child: Text('DESC', style: _titleStyle),
              ),
            ),

            // Bottom section (Cream)
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(bottom: 12),
                alignment: Alignment.center,
                child: Text(
                  '-$percent%',
                  style: AppTextStyles.discountBadgePercent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgePainter extends CustomPainter {
  const _BadgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final radius = 8.0;
    final pointHeight = 12.0;
    final headerHeight = 38.0;

    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = const Color(0xFFF4C430);

    // Full shape background (Cream color)
    final path = Path();
    path.moveTo(radius, 0);
    path.lineTo(w - radius, 0);
    path.arcToPoint(Offset(w, radius), radius: Radius.circular(radius));
    path.lineTo(w, h - pointHeight - radius);
    path.lineTo(w, h - pointHeight);
    path.lineTo(w / 2, h);
    path.lineTo(0, h - pointHeight);
    path.lineTo(0, radius);
    path.arcToPoint(Offset(radius, 0), radius: Radius.circular(radius));
    path.close();

    paint.color = const Color(0xFFFFFBE6);
    canvas.drawPath(path, paint);

    // Header (Gold Gradient)
    final headerPath = Path();
    headerPath.moveTo(radius, 0);
    headerPath.lineTo(w - radius, 0);
    headerPath.arcToPoint(Offset(w, radius), radius: Radius.circular(radius));
    headerPath.lineTo(w, headerHeight);
    headerPath.lineTo(0, headerHeight);
    headerPath.lineTo(0, radius);
    headerPath.arcToPoint(Offset(radius, 0), radius: Radius.circular(radius));
    headerPath.close();

    final gradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFD700), Color(0xFFE6AC00)],
    );
    paint.shader = gradient.createShader(Rect.fromLTWH(0, 0, w, headerHeight));
    canvas.drawPath(headerPath, paint);

    // Border
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
