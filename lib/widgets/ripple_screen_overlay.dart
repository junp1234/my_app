import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'painters/water_fill_painter.dart';

class RippleScreenOverlay extends StatelessWidget {
  const RippleScreenOverlay({
    super.key,
    required this.size,
    required this.progress,
    required this.burstT,
  });

  final double size;
  final double progress;
  final double burstT;

  @override
  Widget build(BuildContext context) {
    if (burstT <= 0 || progress <= 0) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RippleScreenPainter(
            progress: progress,
            burstT: burstT,
          ),
        ),
      ),
    );
  }
}

class _RippleScreenPainter extends CustomPainter {
  const _RippleScreenPainter({
    required this.progress,
    required this.burstT,
  });

  final double progress;
  final double burstT;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final bowlRadius = size.width * 0.39;
    final outerRect = Rect.fromCircle(center: center, radius: bowlRadius);
    final innerRect = outerRect.deflate(11);
    final waterTopY = WaterFillPainter.waterTopYForProgress(innerRect, progress);
    final waterPath = WaterFillPainter.waterPathForProgress(innerRect, progress);
    final rippleCenter = Offset(center.dx, waterTopY + 6);

    canvas.save();
    canvas.clipPath(waterPath);

    final maxR = innerRect.width * 0.44;
    _drawRing(canvas, center: rippleCenter, maxR: maxR, progress: burstT, alphaMultiplier: 1.0);

    const delay = 0.18;
    final t2 = ((burstT - delay) / (1 - delay)).clamp(0.0, 1.0);
    _drawRing(canvas, center: rippleCenter, maxR: maxR, progress: t2, alphaMultiplier: 0.75);

    canvas.restore();
  }

  void _drawRing(
    Canvas canvas, {
    required Offset center,
    required double maxR,
    required double progress,
    required double alphaMultiplier,
  }) {
    if (progress <= 0 || progress >= 1) {
      return;
    }

    final eased = Curves.easeOut.transform(progress);
    final radius = lerpDouble(0, maxR, eased)!;
    final pulse = math.sin(math.pi * progress).clamp(0.0, 1.0);
    final alpha = (pulse * 0.28 * alphaMultiplier).clamp(0.0, 1.0);
    final strokeWidth = lerpDouble(1.6, 3.0, pulse)!;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = const Color(0xFFFFFFFF).withValues(alpha: alpha);

    canvas.drawOval(Rect.fromCenter(center: center, width: radius * 2.2, height: radius * 0.72), paint);
  }

  @override
  bool shouldRepaint(covariant _RippleScreenPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.burstT != burstT;
  }
}
