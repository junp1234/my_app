import 'dart:math';

import 'package:flutter/material.dart';

class GlassGauge extends StatelessWidget {
  const GlassGauge({
    super.key,
    required this.progress,
    required this.rippleT,
    required this.shakeT,
    required this.tickCount,
    this.size = 272,
  });

  final double progress;
  final double rippleT;
  final double shakeT;
  final int tickCount;
  final double size;

  @override
  Widget build(BuildContext context) {
    final wobbleX = sin(shakeT * pi * 2) * (1 - shakeT) * 6;
    final activeTicks = (tickCount * progress).round();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...List.generate(tickCount, (i) {
            final angle = -pi / 2 + i * (2 * pi / tickCount);
            final radius = size * 0.5 + 14;
            return Transform.translate(
              offset: Offset(cos(angle) * radius, sin(angle) * radius),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i < activeTicks ? const Color(0x66A9D8FF) : const Color(0x22576473),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
          Transform.translate(
            offset: Offset(wobbleX, 0),
            child: CustomPaint(
              size: Size.square(size),
              painter: _GlassGaugePainter(
                progress: progress,
                rippleT: rippleT,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassGaugePainter extends CustomPainter {
  const _GlassGaugePainter({required this.progress, required this.rippleT});

  final double progress;
  final double rippleT;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.39;
    final sphere = Rect.fromCircle(center: c, radius: r);

    canvas.drawShadow(Path()..addOval(sphere.shift(const Offset(0, 6))), const Color(0x22000000), 14, false);

    final glassFill = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.35),
        radius: 0.95,
        colors: [
          Colors.white.withValues(alpha: 0.36),
          const Color(0xD9F7FAFF),
          const Color(0x66E3EAF4),
        ],
      ).createShader(sphere);
    canvas.drawCircle(c, r, glassFill);

    canvas.save();
    final clipPath = Path()..addOval(sphere.deflate(8));
    canvas.clipPath(clipPath);

    final waterLevel = c.dy + r * 0.76 - (progress.clamp(0, 1) * r * 1.55);
    final waterRect = Rect.fromLTWH(sphere.left, waterLevel - 34, sphere.width, sphere.bottom - waterLevel + 44);

    final waterPath = Path()
      ..moveTo(sphere.left - 2, sphere.bottom + 2)
      ..lineTo(sphere.left - 2, waterLevel)
      ..quadraticBezierTo(c.dx - 44, waterLevel - 7, c.dx, waterLevel + 2)
      ..quadraticBezierTo(c.dx + 52, waterLevel + 8, sphere.right + 2, waterLevel - 1)
      ..lineTo(sphere.right + 2, sphere.bottom + 2)
      ..close();

    final waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0x88D9F3FF),
          Color(0xCC8BDAFF),
          Color(0xEE63B8EB),
          Color(0xEE56A7DF),
        ],
      ).createShader(waterRect);
    canvas.drawPath(waterPath, waterPaint);

    final refractPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.25),
          Colors.transparent,
        ],
      ).createShader(waterRect)
      ..blendMode = BlendMode.screen;
    canvas.drawPath(waterPath.shift(const Offset(-8, 0)), refractPaint);

    final surfacePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.9),
          Colors.white.withValues(alpha: 0.14),
        ],
      ).createShader(Rect.fromLTWH(sphere.left, waterLevel - 2, sphere.width, 5))
      ..strokeWidth = 2.1
      ..style = PaintingStyle.stroke;

    final surfacePath = Path()
      ..moveTo(sphere.left + 20, waterLevel)
      ..quadraticBezierTo(c.dx - 32, waterLevel - 4.5, c.dx, waterLevel + 1.5)
      ..quadraticBezierTo(c.dx + 36, waterLevel + 6, sphere.right - 20, waterLevel + 1);
    canvas.drawPath(surfacePath, surfacePaint);

    if (rippleT > 0 && rippleT < 1) {
      final rippleRadius = 10 + 42 * Curves.easeOut.transform(rippleT);
      final alpha = (1 - rippleT) * 0.45;
      final ripplePaint = Paint()
        ..color = Colors.white.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas.drawCircle(Offset(c.dx, waterLevel + 2), rippleRadius, ripplePaint);
    }

    canvas.restore();

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..shader = SweepGradient(
        colors: [
          Colors.white.withValues(alpha: 0.9),
          const Color(0x99DCE5F1),
          const Color(0xAAC8D4E2),
          Colors.white.withValues(alpha: 0.7),
        ],
      ).createShader(sphere);
    canvas.drawCircle(c, r, ringPaint);

    final innerRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.42);
    canvas.drawCircle(c, r - 7, innerRingPaint);

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: c.translate(-20, -24), radius: r * 0.7), pi * 1.0, pi * 0.34, false, highlightPaint);

    canvas.drawArc(
      Rect.fromCircle(center: c.translate(30, -8), radius: r * 0.54),
      pi * 1.1,
      pi * 0.18,
      false,
      highlightPaint..strokeWidth = 2,
    );

    final glossPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withValues(alpha: 0.45), Colors.transparent],
      ).createShader(Rect.fromCircle(center: c.translate(-36, -40), radius: 38));
    canvas.drawCircle(c.translate(-36, -40), 38, glossPaint);
  }

  @override
  bool shouldRepaint(covariant _GlassGaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.rippleT != rippleT;
  }
}
