import 'dart:math' as math;

import 'package:flutter/material.dart';

class SparkleOverlay extends StatelessWidget {
  const SparkleOverlay({
    super.key,
    required this.progress,
    this.count = 10,
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
    final opacityIn = Curves.easeOut.transform((t / 0.28).clamp(0.0, 1.0));
    final opacityOut = 1 - Curves.easeIn.transform(((t - 0.42) / 0.58).clamp(0.0, 1.0));
    final alpha = (opacityIn * opacityOut).clamp(0.0, 1.0);
    if (alpha <= 0) {
      return;
    }

    final center = size.center(Offset.zero);
    final topAnchor = Offset(center.dx, center.dy - (size.shortestSide * 0.34));

    for (var i = 0; i < count; i++) {
      final seed = i * 0.73 + 1.1;
      final spread = 16 + (i % 3) * 5.0;
      final angle = (2 * math.pi / count) * i + math.sin(seed) * 0.35;
      final baseOffset = Offset(math.cos(angle) * spread, math.sin(angle) * 5);

      final rise = 10 + (i % 5) * 3.0;
      final y = -((Curves.easeOut.transform(t) * rise) + (math.cos(seed * 2.2) * 4));
      final x = math.sin(seed * 3.7) * 3;
      final sparkleCenter = topAnchor.translate(baseOffset.dx + x, baseOffset.dy + y);

      final radius = 2 + (i % 4) * 0.6;
      final scale = 0.8 + (Curves.easeOut.transform(t) * 0.2);
      final paint = Paint()..color = Colors.white.withValues(alpha: alpha * (0.6 + (i % 3) * 0.12));
      canvas.drawCircle(sparkleCenter, radius * scale, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.count != count;
  }
}
