import 'dart:math';

import 'package:flutter/material.dart';

import 'painters/glass_bowl_painter.dart';
import 'painters/ripple_painter.dart';
import 'painters/water_fill_painter.dart';
import 'shapes/teardrop_path.dart';
import 'water_surface_wobble.dart';

class GlassGauge extends StatelessWidget {
  const GlassGauge({
    super.key,
    required this.progress,
    required this.rippleT,
    required this.shakeT,
    required this.dropT,
    required this.wobbleT,
    this.extraRippleLayer = false,
    this.size = 272,
  });

  final double progress;
  final double rippleT;
  final double shakeT;
  final double dropT;
  final double wobbleT;
  final bool extraRippleLayer;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Transform.rotate(
        angle: sin(shakeT * pi) * (1 - shakeT) * 0.015,
        child: CustomPaint(
          size: Size.square(size),
          painter: _GlassGaugePainter(
            progress: progress,
            rippleT: rippleT,
            dropT: dropT,
            wobbleT: wobbleT,
            extraRippleLayer: extraRippleLayer,
          ),
        ),
      ),
    );
  }
}

class _GlassGaugePainter extends CustomPainter {
  const _GlassGaugePainter({
    required this.progress,
    required this.rippleT,
    required this.dropT,
    required this.wobbleT,
    required this.extraRippleLayer,
  });

  final double progress;
  final double rippleT;
  final double dropT;
  final double wobbleT;
  final bool extraRippleLayer;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final bowlRadius = size.width * 0.39;
    final outerRect = Rect.fromCircle(center: center, radius: bowlRadius);
    final innerRect = outerRect.deflate(11);

    final airVolumePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.28),
        radius: 1.08,
        colors: [
          const Color(0xFFEFFCFF).withValues(alpha: 0.20),
          const Color(0xFFCFE9FA).withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(innerRect);
    canvas.drawOval(innerRect, airVolumePaint);

    canvas.save();
    canvas.clipPath(Path()..addOval(innerRect));
    WaterFillPainter(innerRect: innerRect, progress: progress).paint(canvas, size);

    final isFull = WaterFillPainter.isFull(progress);
    final waterTopY = WaterFillPainter.waterTopYForProgress(innerRect, progress);

    if (isFull) {
      final wobblePainter = WaterSurfaceWobblePainter(
        waterRect: Rect.fromLTRB(innerRect.left, innerRect.top, innerRect.right, innerRect.bottom),
        t: wobbleT,
      );
      final wobbleWaterPath = wobblePainter.buildWaterRegionPath();

      canvas.save();
      canvas.clipPath(wobbleWaterPath);

      final innerReflection = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.11),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.55],
        ).createShader(WaterFillPainter.waterGradientRectForTop(innerRect, innerRect.top));
      canvas.drawRect(innerRect, innerReflection);
      canvas.restore();

      canvas.save();
      canvas.clipPath(wobbleWaterPath);
      wobblePainter.paint(canvas, size);
      canvas.restore();
    } else {
      final rippleCenter = Offset(center.dx, waterTopY + 6);
      final waterPath = WaterFillPainter.waterPathForProgress(innerRect, progress);
      canvas.save();
      canvas.clipPath(waterPath);
      RipplePainter(
        t: rippleT,
        center: rippleCenter,
        maxWidth: innerRect.width * 0.42,
        extraLayer: extraRippleLayer,
      ).paint(canvas, size);
      canvas.restore();
    }

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
          const Color(0xFFE9F8FF).withValues(alpha: 0.65 * opacity),
          const Color(0xCC8ED8FF).withValues(alpha: opacity),
          const Color(0xE058A8D8).withValues(alpha: opacity),
        ],
      ).createShader(dropRect);
    canvas.drawPath(dropPath, dropPaint);

    final specPaint = Paint()..color = Colors.white.withValues(alpha: 0.35 * opacity);
    canvas.drawCircle(dropRect.center.translate(-3, -dropRect.height * 0.2), dropRect.width * 0.12, specPaint);
  }

  @override
  bool shouldRepaint(covariant _GlassGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.rippleT != rippleT ||
        oldDelegate.dropT != dropT ||
        oldDelegate.wobbleT != wobbleT ||
        oldDelegate.extraRippleLayer != extraRippleLayer;
  }
}
