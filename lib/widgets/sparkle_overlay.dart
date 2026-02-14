import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/water_theme.dart';

class SparkleOverlay extends StatelessWidget {
  const SparkleOverlay({
    super.key,
    required this.progress,
    this.count = 24,
  });

  final double progress;
  final int count;

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0).toDouble();
    if (t <= 0 || t >= 1) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      painter: _SparklePainter(t: t, count: count),
      size: Size.infinite,
    );
  }
}

class _SparklePainter extends CustomPainter {
  const _SparklePainter({
    required this.t,
    required this.count,
  });

  final double t;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final fadeIn = Curves.easeOut.transform((t / 0.20).clamp(0.0, 1.0));
    final fadeOut = 1 - Curves.easeIn.transform(((t - 0.52) / 0.48).clamp(0.0, 1.0));
    final alpha = (fadeIn * fadeOut).clamp(0.0, 1.0);
    if (alpha <= 0) {
      return;
    }

    final center = size.center(Offset.zero);
    final anchor = Offset(center.dx, center.dy + size.height * 0.1);

    for (var i = 0; i < count; i++) {
      final seed = i * 1.17 + 7;
      final radius = size.shortestSide * (0.07 + (i % 6) * 0.018);
      final angle = (2 * math.pi / count) * i + math.sin(seed) * 0.14;
      final burst = Curves.easeOut.transform(t);
      final sparkleCenter = anchor.translate(
        math.cos(angle) * radius * burst,
        math.sin(angle) * radius * burst * 0.7,
      );

      final sparkleRadius = 1.4 + (i % 4) * 0.9;
      final sparklePaint = Paint()
        ..color = Colors.white.withValues(alpha: alpha * (0.65 + (i % 3) * 0.1));
      canvas.drawCircle(sparkleCenter, sparkleRadius, sparklePaint);

      final glowPaint = Paint()
        ..color = WaterTheme.brightSparkle.withValues(alpha: alpha * 0.38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(sparkleCenter, sparkleRadius * 1.8, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.count != count;
  }
}
