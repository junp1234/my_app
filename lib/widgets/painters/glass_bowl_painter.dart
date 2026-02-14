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
    final baseShadowRect = Rect.fromCenter(
      center: center.translate(0, outerRect.height * 0.56),
      width: outerRect.width * 0.7,
      height: outerRect.height * 0.22,
    );
    final baseShadowPaint = Paint()
      ..color = const Color(0xFF6B85A2).withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawOval(baseShadowRect, baseShadowPaint);

    final bowlFillPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.3),
        radius: 1.0,
        colors: [
          const Color(0xFFEFFAFF).withValues(alpha: 0.26),
          const Color(0xFFCCEAFB).withValues(alpha: 0.14),
          const Color(0xFF9BC6E3).withValues(alpha: 0.07),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(outerRect);
    canvas.drawOval(outerRect, bowlFillPaint);

    final outerStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..shader = SweepGradient(
        transform: const GradientRotation(-pi / 2),
        colors: [
          const Color(0xFFD8EEFF).withValues(alpha: 0.42),
          const Color(0xFFB7D6EC).withValues(alpha: 0.28),
          const Color(0xFFAECFE8).withValues(alpha: 0.26),
          const Color(0xFFD8EEFF).withValues(alpha: 0.4),
        ],
      ).createShader(outerRect);
    canvas.drawOval(outerRect, outerStrokePaint);

    final innerStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFFEFFFFF).withValues(alpha: 0.22);
    canvas.drawOval(innerRect.inflate(1.4), innerStrokePaint);

    final leftRefraction = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFD9F3FF).withValues(alpha: 0.18),
          const Color(0xFFD9F3FF).withValues(alpha: 0.04),
          Colors.transparent,
        ],
      ).createShader(innerRect)
      ..blendMode = BlendMode.screen;
    canvas.drawOval(innerRect.shift(const Offset(-6, 1)), leftRefraction);

    // NOTE: Top-half oval highlight intentionally disabled.
    // This was the source of the bright ellipse that remained on the glass.
    // final topHighlightRect = Rect.fromCenter(
    //   center: Offset(center.dx + outerRect.width * 0.07, outerRect.top + outerRect.height * 0.23),
    //   width: outerRect.width * 0.62,
    //   height: outerRect.height * 0.29,
    // );
    //
    // final topHighlight = Paint()
    //   ..shader = LinearGradient(
    //     begin: Alignment.topLeft,
    //     end: Alignment.bottomRight,
    //     colors: [
    //       const Color(0xFFDDF6FF).withValues(alpha: 0.24),
    //       const Color(0xFFC7EAFF).withValues(alpha: 0.12),
    //       Colors.transparent,
    //     ],
    //     stops: const [0.0, 0.6, 1.0],
    //   ).createShader(topHighlightRect);
    // canvas.drawOval(topHighlightRect, topHighlight);

    final sideSpecular = Paint()
      ..color = const Color(0xFFDEF3FF).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2;
    canvas.drawArc(
      Rect.fromCenter(center: center.translate(-24, -18), width: outerRect.width * 0.9, height: outerRect.height * 0.8),
      pi * 0.95,
      pi * 0.28,
      false,
      sideSpecular,
    );

    final lowerRimShade = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..color = const Color(0xFF7DA5C8).withValues(alpha: 0.16);
    canvas.drawArc(
      innerRect.inflate(0.4),
      pi * 0.18,
      pi * 0.64,
      false,
      lowerRimShade,
    );
  }

  @override
  bool shouldRepaint(covariant GlassBowlPainter oldDelegate) {
    return oldDelegate.outerRect != outerRect || oldDelegate.innerRect != innerRect;
  }
}
