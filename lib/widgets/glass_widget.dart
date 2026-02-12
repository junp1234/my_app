import 'dart:math';

import 'package:flutter/material.dart';

class GlassWidget extends StatelessWidget {
  const GlassWidget({
    super.key,
    required this.progress,
    required this.ripple,
    required this.activeDots,
    this.size = 260,
  });

  final double progress;
  final double ripple;
  final int activeDots;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _GlassPainter(progress: progress, ripple: ripple, activeDots: activeDots),
    );
  }
}

class _GlassPainter extends CustomPainter {
  _GlassPainter({required this.progress, required this.ripple, required this.activeDots});

  final double progress;
  final double ripple;
  final int activeDots;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.38;

    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x18FFFFFF), Color(0x0FFFFFFF)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, bg);

    final waterTop = center.dy + radius - (radius * 2 * progress);
    final waterRect = Rect.fromLTRB(center.dx - radius + 8, waterTop, center.dx + radius - 8, center.dy + radius - 8);
    final waterPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xAA8EDBFF), Color(0xCC5ABBF9)],
      ).createShader(waterRect);
    if (progress > 0) {
      final path = Path()
        ..addRRect(RRect.fromRectAndRadius(waterRect, const Radius.circular(80)));
      canvas.drawPath(path, waterPaint);

      final ripplePaint = Paint()
        ..color = Colors.white.withValues(alpha: (0.5 * (1 - ripple)).clamp(0, 0.5))
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx, waterTop + 4), width: 30 + ripple * 70, height: 6 + ripple * 12),
        ripplePaint,
      );
    }

    final reflection = Paint()..color = Colors.white.withValues(alpha: 0.35);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center.dx - radius * 0.62, center.dy - radius * 0.78, radius * 0.24, radius * 1.0),
        const Radius.circular(22),
      ),
      reflection,
    );

    final border = Paint()
      ..color = Colors.white.withValues(alpha: 0.78)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, border);

    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(center + const Offset(0, 5), radius * 0.98, shadow);

    final dotPaint = Paint();
    const totalDots = 14;
    for (var i = 0; i < totalDots; i++) {
      final angle = -pi / 2 + i * (2 * pi / totalDots);
      final dotOffset = Offset(cos(angle), sin(angle)) * (radius + 22);
      dotPaint.color = i < activeDots ? const Color(0x99A8D8FF) : const Color(0x336B7280);
      canvas.drawCircle(center + dotOffset, 4.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlassPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.ripple != ripple || oldDelegate.activeDots != activeDots;
  }
}
