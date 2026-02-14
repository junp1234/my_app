import 'dart:math' as math;

import 'package:flutter/material.dart';

class WaterSurfaceWobblePainter extends CustomPainter {
  const WaterSurfaceWobblePainter({
    required this.waterRect,
    required this.t,
  });

  final Rect waterRect;
  final double t;

  Path buildSurfacePath() {
    final width = waterRect.width;
    final clampedT = t % 1.0;
    final wave1Amplitude = (width * 0.012).clamp(2.0, 4.0);
    final wave2Amplitude = (width * 0.009).clamp(1.6, 3.2);
    final wave1Length = width * 0.9;
    final wave2Length = width * 1.14;
    final baseY = waterRect.top + 1.8;

    final path = Path();
    const steps = 40;
    for (var i = 0; i <= steps; i++) {
      final ratio = i / steps;
      final x = waterRect.left + (width * ratio);
      final phase1 = (ratio * 2 * math.pi * (width / wave1Length)) + (clampedT * 2 * math.pi);
      final phase2 = (ratio * 2 * math.pi * (width / wave2Length)) - (clampedT * 2 * math.pi * 0.7) + 1.4;
      final y = baseY + (math.sin(phase1) * wave1Amplitude) + (math.sin(phase2) * wave2Amplitude);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    return path;
  }

  Path buildWaterRegionPath() {
    final surfacePath = buildSurfacePath();
    return Path.from(surfacePath)
      ..lineTo(waterRect.right, waterRect.bottom + 2)
      ..lineTo(waterRect.left, waterRect.bottom + 2)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final surfacePath = buildSurfacePath();
    final pulse = 0.2 + 0.08 * math.sin((t % 1.0) * 2 * math.pi);

    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.35
      ..color = Colors.white.withValues(alpha: pulse);

    canvas.drawPath(surfacePath, highlightPaint);

    final subtleGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = const Color(0xFFE8F9FF).withValues(alpha: pulse * 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4);
    canvas.drawPath(surfacePath, subtleGlowPaint);
  }

  @override
  bool shouldRepaint(covariant WaterSurfaceWobblePainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.waterRect != waterRect;
  }
}
