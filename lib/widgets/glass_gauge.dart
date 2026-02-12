import 'dart:math';

import 'package:flutter/material.dart';

import 'painters/glass_bowl_painter.dart';
import 'painters/ripple_painter.dart';
import 'painters/water_fill_painter.dart';
import 'shapes/teardrop_path.dart';

class GlassGauge extends StatelessWidget {
  static const int defaultDotCount = 24;
  static const double dotRadius = 4.0;
  static const double dotRingPadding = 10.0;

  const GlassGauge({
    super.key,
    required this.progress,
    required this.rippleT,
    required this.shakeT,
    required this.dropT,
    required this.tickCount,
    this.size = 272,
  });

  final double progress;
  final double rippleT;
  final double shakeT;
  final double dropT;
  final int tickCount;
  final double size;

  @override
  Widget build(BuildContext context) {
    final glassR = size * 0.39;
    final ringR = glassR + dotRingPadding;
    final litCount = ((progress * tickCount).floor()).clamp(0, tickCount).toInt();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...List.generate(tickCount, (i) {
            final angle = -pi / 2 + i * (2 * pi / tickCount);
            return Transform.translate(
              offset: Offset(cos(angle) * ringR, sin(angle) * ringR),
              child: Container(
                width: dotRadius * 2,
                height: dotRadius * 2,
                decoration: BoxDecoration(
                  color: i < litCount ? const Color(0x66A9D8FF) : const Color(0x22576473),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
          Transform.rotate(
            angle: sin(shakeT * pi) * (1 - shakeT) * 0.015,
            child: CustomPaint(
              size: Size.square(size),
              painter: _GlassGaugePainter(
                progress: progress,
                rippleT: rippleT,
                dropT: dropT,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassGaugePainter extends CustomPainter {
  const _GlassGaugePainter({
    required this.progress,
    required this.rippleT,
    required this.dropT,
  });

  final double progress;
  final double rippleT;
  final double dropT;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final bowlRadius = size.width * 0.39;
    final outerRect = Rect.fromCircle(center: center, radius: bowlRadius);
    final innerRect = outerRect.deflate(11);

    canvas.save();
    canvas.clipPath(Path()..addOval(innerRect));
    WaterFillPainter(innerRect: innerRect, progress: progress).paint(canvas, size);

    final waterTopY = WaterFillPainter.waterTopYForProgress(innerRect, progress);
    final rippleCenter = Offset(center.dx, waterTopY + 6);
    RipplePainter(t: rippleT, center: rippleCenter, maxWidth: innerRect.width * 0.42).paint(canvas, size);

    _paintFallingDrop(canvas, size, waterTopY);
    canvas.restore();

    GlassBowlPainter(outerRect: outerRect, innerRect: innerRect).paint(canvas, size);
  }

  void _paintFallingDrop(Canvas canvas, Size size, double waterTopY) {
    if (dropT <= 0 || dropT >= 1) {
      return;
    }

    final bowlCenter = size.center(Offset.zero);
    final startY = bowlCenter.dy - size.height * 0.43;
    final endY = waterTopY - 2;
    final dropY = Tween<double>(begin: startY, end: endY).transform(Curves.easeIn.transform(dropT));
    final opacity = 1 - Curves.easeIn.transform((dropT * 1.2).clamp(0, 1));

    final dropSize = Size(size.width * 0.06, size.width * 0.09);
    final dropRect = Rect.fromCenter(center: Offset(bowlCenter.dx, dropY), width: dropSize.width, height: dropSize.height);

    final dropPath = buildTeardropPath(dropSize).shift(dropRect.topLeft);
    final dropPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.65 * opacity),
          const Color(0xCC7ACFFF).withValues(alpha: opacity),
          const Color(0xE15FB9F1).withValues(alpha: opacity),
        ],
      ).createShader(dropRect);
    canvas.drawPath(dropPath, dropPaint);

    final specPaint = Paint()..color = Colors.white.withValues(alpha: 0.35 * opacity);
    canvas.drawCircle(dropRect.center.translate(-3, -dropRect.height * 0.2), dropRect.width * 0.12, specPaint);
  }

  @override
  bool shouldRepaint(covariant _GlassGaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.rippleT != rippleT || oldDelegate.dropT != dropT;
  }
}
