import 'dart:math' as math;

import 'package:flutter/material.dart';

class SoapBubblesPainter extends CustomPainter {
  SoapBubblesPainter({
    required this.t,
    required this.bubbles,
  });

  final double t;
  final List<SoapBubbleSpec> bubbles;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final outlinePaint = Paint()..style = PaintingStyle.stroke;
    final highlightPaint = Paint()..style = PaintingStyle.fill;
    final innerDepthPaint = Paint()..style = PaintingStyle.fill;

    for (final bubble in bubbles) {
      final travel = (t * bubble.riseSpeed + bubble.yPhase) % 1.0;
      final y = size.height + bubble.radius - (size.height + bubble.radius * 2) * travel;
      final sway = math.sin((t * math.pi * 2) + bubble.swayPhase) * bubble.swayAmount;
      final x = bubble.x * size.width + sway;
      final center = Offset(x, y);
      final bubbleRect = Rect.fromCircle(center: center, radius: bubble.radius);

      outlinePaint
        ..shader = null
        ..strokeWidth = bubble.outlineWidth
        ..color = Colors.white.withValues(alpha: bubble.outlineAlpha);
      canvas.drawCircle(center, bubble.radius, outlinePaint);

      outlinePaint
        ..strokeWidth = bubble.outlineWidth * 0.88
        ..shader = SweepGradient(
          startAngle: -math.pi / 3,
          endAngle: math.pi * 5 / 3,
          colors: [
            const Color(0xFF8EEBFF).withValues(alpha: 0.09),
            const Color(0xFF8AB9FF).withValues(alpha: 0.08),
            const Color(0xFFC4A8FF).withValues(alpha: 0.10),
            const Color(0xFFA8FFD9).withValues(alpha: 0.07),
            const Color(0xFF8EEBFF).withValues(alpha: 0.09),
          ],
        ).createShader(bubbleRect);
      canvas.drawCircle(center, bubble.radius - bubble.outlineWidth * 0.25, outlinePaint);

      highlightPaint.color = Colors.white.withValues(alpha: bubble.highlightAlpha);
      canvas.drawCircle(
        center.translate(-bubble.radius * 0.35, -bubble.radius * 0.35),
        bubble.radius * 0.20,
        highlightPaint,
      );

      innerDepthPaint.shader = RadialGradient(
        center: const Alignment(0.3, 0.35),
        radius: 0.95,
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.03),
        ],
        stops: const [0.72, 1.0],
      ).createShader(bubbleRect);
      canvas.drawCircle(center, bubble.radius * 0.94, innerDepthPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SoapBubblesPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.bubbles != bubbles;
  }
}

class SoapBubbleSpec {
  const SoapBubbleSpec({
    required this.x,
    required this.yPhase,
    required this.radius,
    required this.riseSpeed,
    required this.swayPhase,
    required this.swayAmount,
    required this.outlineAlpha,
    required this.highlightAlpha,
    required this.outlineWidth,
  });

  final double x;
  final double yPhase;
  final double radius;
  final double riseSpeed;
  final double swayPhase;
  final double swayAmount;
  final double outlineAlpha;
  final double highlightAlpha;
  final double outlineWidth;
}
