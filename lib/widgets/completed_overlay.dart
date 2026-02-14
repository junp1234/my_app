import 'dart:math' as math;

import 'package:flutter/material.dart';

class CompletedOverlay extends StatelessWidget {
  const CompletedOverlay({
    super.key,
    required this.animation,
    required this.waterColor,
  });

  final Animation<double> animation;
  final Color waterColor;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: animation,
          builder: (_, __) {
            final t = animation.value.clamp(0.0, 1.0);
            final bgIn = Curves.easeOut.transform((t / 0.22).clamp(0.0, 1.0));
            final bgOut = 1 - Curves.easeIn.transform(((t - 0.55) / 0.45).clamp(0.0, 1.0));
            final bgOpacity = (bgIn * bgOut * 0.54).clamp(0.0, 1.0);

            return Stack(
              children: [
                Opacity(
                  opacity: bgOpacity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.0, 0.2),
                        radius: 1.05,
                        colors: [
                          waterColor.withValues(alpha: 0.95),
                          waterColor.withValues(alpha: 0.75),
                          waterColor.withValues(alpha: 0.20),
                        ],
                        stops: const [0.0, 0.62, 1.0],
                      ),
                    ),
                  ),
                ),
                CustomPaint(
                  size: Size.infinite,
                  painter: _CompletedOverlayPainter(progress: t, waterColor: waterColor),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CompletedOverlayPainter extends CustomPainter {
  const _CompletedOverlayPainter({
    required this.progress,
    required this.waterColor,
  });

  final double progress;
  final Color waterColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) {
      return;
    }

    final center = size.center(Offset.zero);
    final anchor = Offset(center.dx, center.dy + size.height * 0.08);

    _paintBurst(canvas, anchor, size);
    _paintSparkles(canvas, anchor, size);
    _paintRimHighlights(canvas, anchor, size);
  }

  void _paintBurst(Canvas canvas, Offset center, Size size) {
    final inT = Curves.easeOutCubic.transform((progress / 0.35).clamp(0.0, 1.0));
    final outT = 1 - Curves.easeIn.transform(((progress - 0.35) / 0.45).clamp(0.0, 1.0));
    final alpha = (inT * outT * 0.36).clamp(0.0, 1.0);
    if (alpha <= 0) {
      return;
    }

    const beamCount = 14;
    final radius = size.shortestSide * 0.28;
    for (var i = 0; i < beamCount; i++) {
      final angle = (2 * math.pi * i / beamCount) + math.sin(i * 0.71) * 0.06;
      final beamLen = radius * (0.72 + (i % 4) * 0.14) * inT;
      final beamWidth = 1.3 + (i % 3) * 0.5;
      final p1 = center.translate(math.cos(angle) * 18, math.sin(angle) * 18);
      final p2 = center.translate(math.cos(angle) * beamLen, math.sin(angle) * beamLen);
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: alpha)
        ..strokeWidth = beamWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(p1, p2, paint);
    }
  }

  void _paintSparkles(Canvas canvas, Offset center, Size size) {
    final twinkleWindow = ((progress - 0.1) / 0.6).clamp(0.0, 1.0);
    if (twinkleWindow <= 0) {
      return;
    }

    final radius = size.shortestSide * 0.34;
    const particleCount = 42;
    for (var i = 0; i < particleCount; i++) {
      final seed = i * 13.37;
      final a = (seed % 6.28318);
      final r = radius * (0.16 + ((math.sin(seed * 0.7) + 1) * 0.42));
      final drift = math.sin(progress * 10 + seed) * 3.0;
      final dx = math.cos(a) * r + drift;
      final dy = math.sin(a) * r * 0.75 - drift * 0.5;
      final pos = center.translate(dx, dy);

      final blink = (math.sin((twinkleWindow * 5.8 + seed) * math.pi) + 1) / 2;
      final env = Curves.easeInOut.transform((1 - (twinkleWindow - 0.5).abs() * 2).clamp(0.0, 1.0));
      final opacity = (blink * env * 0.82).clamp(0.0, 1.0);
      if (opacity < 0.05) {
        continue;
      }

      final baseSize = 1.3 + (i % 4) * 0.75;
      final pulse = 0.9 + 0.28 * math.sin(progress * 14 + seed * 0.5);
      final particleRadius = baseSize * pulse;
      final color = i.isEven ? Colors.white : const Color(0xFFBCE8FF);
      final paint = Paint()..color = color.withValues(alpha: opacity);
      canvas.drawCircle(pos, particleRadius, paint);

      if (i % 5 == 0) {
        final cross = Paint()
          ..color = Colors.white.withValues(alpha: (opacity * 0.86).clamp(0.0, 1.0))
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round;
        final l = particleRadius * 2.3;
        canvas.drawLine(pos.translate(-l, 0), pos.translate(l, 0), cross);
        canvas.drawLine(pos.translate(0, -l), pos.translate(0, l), cross);
      }
    }
  }

  void _paintRimHighlights(Canvas canvas, Offset center, Size size) {
    final rimT = ((progress - 0.15) / 0.45).clamp(0.0, 1.0);
    if (rimT <= 0) {
      return;
    }

    final radius = size.shortestSide * 0.195;
    final decay = 1 - Curves.easeIn.transform(((progress - 0.45) / 0.35).clamp(0.0, 1.0));

    for (var i = 0; i < 5; i++) {
      final start = -math.pi * 0.88 + i * 0.46 + math.sin(i * 1.4) * 0.08;
      final sweep = 0.20 + (i % 2) * 0.10;
      final flicker = (math.sin(progress * 18 + i * 1.7) + 1) / 2;
      final opacity = (rimT * decay * flicker * 0.72).clamp(0.0, 1.0);
      if (opacity < 0.06) {
        continue;
      }

      final rect = Rect.fromCircle(center: center, radius: radius + i * 1.6);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: opacity);
      canvas.drawArc(rect, start, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CompletedOverlayPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.waterColor != waterColor;
  }
}
