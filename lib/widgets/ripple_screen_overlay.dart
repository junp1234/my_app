import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class RippleScreenOverlay extends StatelessWidget {
  const RippleScreenOverlay({
    super.key,
    required this.burstT,
    required this.waterPath,
    required this.waterTopY,
    required this.waterBounds,
    required this.center,
  });

  final double burstT;
  final Path waterPath;
  final double waterTopY;
  final Rect waterBounds;
  final Offset center;

  @override
  Widget build(BuildContext context) {
    if (burstT <= 0) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _RippleScreenPainter(
            burstT: burstT,
            waterPath: waterPath,
            waterTopY: waterTopY,
            waterBounds: waterBounds,
            center: center,
          ),
        ),
      ),
    );
  }
}

class _RippleScreenPainter extends CustomPainter {
  const _RippleScreenPainter({
    required this.burstT,
    required this.waterPath,
    required this.waterTopY,
    required this.waterBounds,
    required this.center,
  });

  final double burstT;
  final Path waterPath;
  final double waterTopY;
  final Rect waterBounds;
  final Offset center;

  @override
  void paint(Canvas canvas, Size size) {
    final margin = 8.0;
    final topLimit = center.dy - (waterTopY - 2);
    final bottomLimit = waterBounds.bottom - center.dy;
    final sideLimit = math.min(center.dx - waterBounds.left, waterBounds.right - center.dx);
    final rippleMaxRadius = math.max(0.0, math.min(sideLimit, math.min(topLimit, bottomLimit)) - margin);

    canvas.save();
    canvas.clipPath(waterPath);

    _drawRing(canvas, center: center, maxR: rippleMaxRadius, progress: burstT, alphaMultiplier: 1.0);

    const delay = 0.18;
    final t2 = ((burstT - delay) / (1 - delay)).clamp(0.0, 1.0);
    _drawRing(canvas, center: center, maxR: rippleMaxRadius, progress: t2, alphaMultiplier: 0.75);

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
    final alpha = (pulse * 0.58 * alphaMultiplier).clamp(0.0, 1.0);
    final strokeWidth = lerpDouble(1.8, 2.5, pulse)!;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = const Color(0xFFFFFFFF).withValues(alpha: alpha);

    canvas.drawOval(Rect.fromCenter(center: center, width: radius * 2.2, height: radius * 0.72), paint);
  }

  @override
  bool shouldRepaint(covariant _RippleScreenPainter oldDelegate) {
    return oldDelegate.burstT != burstT ||
        oldDelegate.waterTopY != waterTopY ||
        oldDelegate.waterBounds != waterBounds ||
        oldDelegate.center != center ||
        oldDelegate.waterPath != waterPath;
  }
}
