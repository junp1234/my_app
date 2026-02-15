import 'package:flutter/material.dart';

class GlassFallbackRingPainter extends CustomPainter {
  const GlassFallbackRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outerRect = Rect.fromCircle(center: center, radius: size.width * 0.39);
    final innerRect = outerRect.deflate(11);

    final fillPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.18, -0.22),
        radius: 1.0,
        colors: [
          Colors.white.withValues(alpha: 0.12),
          const Color(0xFFC7E7FA).withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(outerRect);
    canvas.drawOval(outerRect, fillPaint);

    final outerRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.65);
    canvas.drawOval(outerRect, outerRing);

    final innerRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFBFE9FF).withValues(alpha: 0.45);
    canvas.drawOval(innerRect, innerRing);
  }

  @override
  bool shouldRepaint(covariant GlassFallbackRingPainter oldDelegate) {
    return false;
  }
}
