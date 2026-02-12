import 'dart:math';

import 'package:flutter/material.dart';

class GlassBowlPainter extends CustomPainter {
  const GlassBowlPainter({
    required this.outerRect,
    required this.innerRect,
  });

  final Rect outerRect;
  final Rect innerRect;

  @override
  void paint(Canvas canvas, Size size) {
    final center = outerRect.center;
    final softShadowPath = Path()..addOval(outerRect.shift(const Offset(0, 10)));
    canvas.drawShadow(softShadowPath, const Color(0x25000000), 24, false);

    final bowlFillPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.3),
        radius: 1.0,
        colors: [
          Colors.white.withValues(alpha: 0.22),
          const Color(0x91EDF5FF),
          const Color(0x3FD7E4F3),
        ],
      ).createShader(outerRect);
    canvas.drawOval(outerRect, bowlFillPaint);

    final outerStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..shader = SweepGradient(
        transform: const GradientRotation(-pi / 2),
        colors: [
          Colors.white.withValues(alpha: 0.95),
          const Color(0x9EDDEBFA),
          const Color(0x80C6D7EA),
          Colors.white.withValues(alpha: 0.86),
        ],
      ).createShader(outerRect);
    canvas.drawOval(outerRect, outerStrokePaint);

    final innerStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..color = Colors.white.withValues(alpha: 0.45);
    canvas.drawOval(innerRect.inflate(2), innerStrokePaint);

    final leftRefraction = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.24),
          Colors.white.withValues(alpha: 0.02),
          Colors.transparent,
        ],
      ).createShader(innerRect)
      ..blendMode = BlendMode.screen;
    canvas.drawOval(innerRect.shift(const Offset(-8, 2)), leftRefraction);

    final topHighlightRect = Rect.fromCenter(
      center: Offset(center.dx, outerRect.top + outerRect.height * 0.22),
      width: outerRect.width * 0.8,
      height: outerRect.height * 0.2,
    );

    final topHighlight = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(topHighlightRect);
    canvas.drawOval(topHighlightRect, topHighlight);

    final sideSpecular = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    canvas.drawArc(
      Rect.fromCenter(center: center.translate(-24, -18), width: outerRect.width * 0.9, height: outerRect.height * 0.8),
      pi * 0.95,
      pi * 0.28,
      false,
      sideSpecular,
    );
  }

  @override
  bool shouldRepaint(covariant GlassBowlPainter oldDelegate) {
    return oldDelegate.outerRect != outerRect || oldDelegate.innerRect != innerRect;
  }
}
