import 'dart:math';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Optimized lava lamp background with reduced CPU usage
class LavaLampBackground extends StatefulWidget {
  final Widget child;

  const LavaLampBackground({super.key, required this.child});

  @override
  State<LavaLampBackground> createState() => _LavaLampBackgroundState();
}

class _LavaLampBackgroundState extends State<LavaLampBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Static blob data - colors pre-computed with alpha
  static final List<BlobData> _blobs = [
    BlobData(
      color: const Color(0x99D6002F), // brandPrimary with 0.6 alpha
      baseX: 0.25,
      baseY: 0.35,
      radiusX: 0.38,
      radiusY: 0.28,
      cycleCount: 1,
      phase: 0,
    ),
    BlobData(
      color: const Color(0x80B71C1C), // Red 900 with 0.5 alpha
      baseX: 0.7,
      baseY: 0.25,
      radiusX: 0.32,
      radiusY: 0.38,
      cycleCount: 1,
      phase: pi / 2,
    ),
    BlobData(
      color: const Color(0x80FF1744), // Red Accent 400 with 0.5 alpha
      baseX: 0.5,
      baseY: 0.72,
      radiusX: 0.42,
      radiusY: 0.32,
      cycleCount: 1,
      phase: pi,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Slower animation = less CPU usage
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 45),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Static base gradient (never repaints)
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.lavaGradientStart,
                AppColors.lavaGradientMiddle,
                AppColors.lavaGradientEnd,
              ],
            ),
          ),
        ),
        // Animated blobs - isolated repaint boundary
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _LavaLampPainter(
                  blobs: _blobs,
                  animationValue: _controller.value,
                ),
                size: Size.infinite,
              );
            },
          ),
        ),
        // Content (static)
        widget.child,
      ],
    );
  }
}

/// Data class for a single blob
class BlobData {
  final Color color;
  final double baseX;
  final double baseY;
  final double radiusX;
  final double radiusY;
  final int cycleCount;
  final double phase;

  const BlobData({
    required this.color,
    required this.baseX,
    required this.baseY,
    required this.radiusX,
    required this.radiusY,
    required this.cycleCount,
    required this.phase,
  });
}

/// Optimized painter with reduced calculations
class _LavaLampPainter extends CustomPainter {
  final List<BlobData> blobs;
  final double animationValue;

  // Pre-allocated paint object
  static final Paint _paint = Paint()..style = PaintingStyle.fill;

  // Pre-computed constants
  static const double _twoPi = 2 * pi;
  static const int _numPoints = 12; // Reduced from 16

  _LavaLampPainter({required this.blobs, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    for (final blob in blobs) {
      _drawBlob(canvas, size, blob);
    }
  }

  void _drawBlob(Canvas canvas, Size size, BlobData blob) {
    final time = animationValue * _twoPi * blob.cycleCount + blob.phase;

    // Simplified movement calculations
    final sinTime = sin(time);
    final cosTime = cos(time);
    final moveX = sinTime * 0.05;
    final moveY = cosTime * 0.04;

    final centerX = (blob.baseX + moveX) * size.width;
    final centerY = (blob.baseY + moveY) * size.height;

    // Simplified breathing effect
    final radiusMultiplier = 1.0 + sinTime * 0.06;
    final radX = blob.radiusX * size.width * radiusMultiplier;
    final radY = blob.radiusY * size.height * radiusMultiplier;

    // Simplified blob shape (fewer points)
    final path = _createSimpleBlobPath(centerX, centerY, radX, radY, time);

    // Reuse paint with new shader
    _paint.shader = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [blob.color, blob.color.withValues(alpha: 0.0)],
      stops: const [0.0, 1.0],
    ).createShader(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: radX * 2,
        height: radY * 2,
      ),
    );

    canvas.drawPath(path, _paint);
  }

  Path _createSimpleBlobPath(
    double centerX,
    double centerY,
    double radiusX,
    double radiusY,
    double time,
  ) {
    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < _numPoints; i++) {
      final angle = (i / _numPoints) * _twoPi;
      // Simplified noise calculation
      final noise = sin(angle * 3 + time) * 0.05;
      final r = 1.0 + noise;

      final x = centerX + cos(angle) * radiusX * r;
      final y = centerY + sin(angle) * radiusY * r;
      points.add(Offset(x, y));
    }

    // Simpler curve through points
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < _numPoints; i++) {
      final p1 = points[(i + 1) % _numPoints];
      final p2 = points[(i + 2) % _numPoints];

      final midX = (p1.dx + p2.dx) / 2;
      final midY = (p1.dy + p2.dy) / 2;

      path.quadraticBezierTo(p1.dx, p1.dy, midX, midY);
    }

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_LavaLampPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}
