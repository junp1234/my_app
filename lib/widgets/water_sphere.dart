import 'dart:math' as math;

import 'package:flutter/material.dart';

class WaterSphere extends StatelessWidget {
  const WaterSphere({
    super.key,
    required this.size,
    required this.progress,
    required this.ripple,
    required this.wobble,
  });

  final double size;
  final double progress;
  final double ripple;
  final double wobble;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _WaterSpherePainter(
        progress: progress.clamp(0, 1),
        ripple: ripple.clamp(0, 1),
        wobble: wobble.clamp(0, 1),
      ),
    );
  }
}

class _WaterSpherePainter extends CustomPainter {
  const _WaterSpherePainter({required this.progress, required this.ripple, required this.wobble});

  final double progress;
  final double ripple;
  final double wobble;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.38;
    final sphereRect = Rect.fromCircle(center: center, radius: radius);

    final wobblePhase = math.sin(wobble * math.pi * 2.0) * 0.012;
    final scaleX = 1 + wobblePhase;
    final scaleY = 1 - wobblePhase * 0.85;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scaleX, scaleY);
    canvas.translate(-center.dx, -center.dy);

    final bodyBase = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.28),
        radius: 1.1,
        colors: const [
          Color(0xFFDFF7FF),
          Color(0xFF9CDDFE),
          Color(0xFF58B9F6),
          Color(0xFF3E98D8),
        ],
        stops: const [0, 0.35, 0.73, 1],
      ).createShader(sphereRect);
    canvas.drawCircle(center, radius, bodyBase);

    final waterTop = center.dy + radius - (radius * 2 * progress);
    final fillRect = Rect.fromLTRB(center.dx - radius, waterTop, center.dx + radius, center.dy + radius);
    if (progress > 0) {
      canvas.save();
      canvas.clipPath(Path()..addOval(sphereRect));
      canvas.clipRect(fillRect);

      final waterLayer = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFEBFAFF).withValues(alpha: 0.5),
            const Color(0xFF79CFFE).withValues(alpha: 0.82),
            const Color(0xFF3F9BDE).withValues(alpha: 0.95),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(fillRect);
      canvas.drawRect(fillRect, waterLayer);

      final waveWidth = radius * (0.52 + ripple * 0.6);
      final wavePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = Colors.white.withValues(alpha: (0.42 * (1 - ripple)).clamp(0, 0.42));
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx, waterTop + 3),
          width: waveWidth,
          height: 8 + (ripple * 12),
        ),
        wavePaint,
      );
      canvas.restore();
    }

    _drawRefractionBand(canvas, sphereRect, radius, 0.3, 0.54, 0.11);
    _drawRefractionBand(canvas, sphereRect, radius, 0.42, 0.72, 0.08);
    _drawRefractionBand(canvas, sphereRect, radius, 0.2, 0.44, 0.09);

    final topHighlightRect = Rect.fromCenter(
      center: Offset(center.dx - radius * 0.2, center.dy - radius * 0.44),
      width: radius * 1.1,
      height: radius * 0.44,
    );
    final topHighlight = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.82),
          const Color(0xFFECFBFF).withValues(alpha: 0.45),
          Colors.transparent,
        ],
        stops: const [0, 0.45, 1],
      ).createShader(topHighlightRect);
    canvas.drawOval(topHighlightRect, topHighlight);

    final softShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center + Offset(0, radius * 0.1), radius * 0.96, softShadow);

    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..shader = SweepGradient(
        colors: [
          Colors.white.withValues(alpha: 0.62),
          Colors.white.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0.58),
        ],
      ).createShader(sphereRect);
    canvas.drawCircle(center, radius, rim);

    canvas.restore();
  }

  void _drawRefractionBand(Canvas canvas, Rect sphereRect, double radius, double startY, double endY, double alpha) {
    final path = Path()
      ..moveTo(sphereRect.left + radius * 0.36, sphereRect.top + radius * startY)
      ..cubicTo(
        sphereRect.left + radius * 0.85,
        sphereRect.top + radius * (startY - 0.2),
        sphereRect.left + radius * 1.2,
        sphereRect.top + radius * (endY + 0.05),
        sphereRect.left + radius * 1.65,
        sphereRect.top + radius * endY,
      );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = radius * 0.13
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..color = Colors.white.withValues(alpha: alpha);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WaterSpherePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.ripple != ripple || oldDelegate.wobble != wobble;
  }
}
