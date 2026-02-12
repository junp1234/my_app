import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class RippleScreenOverlay extends StatelessWidget {
  const RippleScreenOverlay({
    super.key,
    required this.t,
    required this.center,
    required this.enabled,
  });

  final Animation<double> t;
  final Offset? center;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled || center == null) {
      return const SizedBox.expand();
    }

    return CustomPaint(
      painter: _RippleScreenPainter(
        t: t.value,
        center: center!,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _RippleScreenPainter extends CustomPainter {
  const _RippleScreenPainter({
    required this.t,
    required this.center,
  });

  final double t;
  final Offset center;

  @override
  void paint(Canvas canvas, Size size) {
    final maxR = math.sqrt((size.width * size.width) + (size.height * size.height)) * 1.05;
    _drawRing(canvas, maxR: maxR, progress: t, alphaMultiplier: 1.0);

    const delay = 0.18;
    final t2 = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
    _drawRing(canvas, maxR: maxR, progress: t2, alphaMultiplier: 0.65);
  }

  void _drawRing(
    Canvas canvas, {
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
    final alpha = (pulse * 0.22 * alphaMultiplier).clamp(0.0, 1.0);
    final strokeWidth = lerpDouble(0.8, 2.4, pulse)!;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = const Color(0xFF7EC8FF).withValues(alpha: alpha);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _RippleScreenPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.center != center;
  }
}
