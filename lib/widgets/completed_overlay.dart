import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class CompletedOverlay extends StatefulWidget {
  const CompletedOverlay({
    super.key,
    required this.onClose,
  });

  final VoidCallback onClose;

  @override
  State<CompletedOverlay> createState() => _CompletedOverlayState();
}

class _CompletedOverlayState extends State<CompletedOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2300),
  )..forward();

  final List<_BokehDot> _bokehDots = List.generate(46, (index) => _BokehDot.seeded(index));
  final List<_SparkleDot> _sparkles = List.generate(44, (index) => _SparkleDot.seeded(index));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final popIn = Curves.easeOutCubic.transform((t / 0.22).clamp(0.0, 1.0));
          final settle = 1 - Curves.easeIn.transform(((t - 0.72) / 0.28).clamp(0.0, 1.0));
          final phase = (popIn * settle).clamp(0.0, 1.0);

          return Stack(
            children: [
              IgnorePointer(
                child: CustomPaint(
                  painter: _CelebrationOverlayPainter(
                    t: t,
                    phase: phase,
                    bokehDots: _bokehDots,
                    sparkles: _sparkles,
                  ),
                  size: Size.infinite,
                ),
              ),
              Align(
                alignment: const Alignment(0, 0.70),
                child: Opacity(
                  opacity: (phase * 1.08).clamp(0.0, 1.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.white.withValues(alpha: 0.86),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: widget.onClose,
                          child: const Padding(
                            padding: EdgeInsets.all(14),
                            child: Icon(Icons.check_rounded, color: Color(0xFF65BEEA), size: 30),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'COMPLETED!',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CelebrationOverlayPainter extends CustomPainter {
  const _CelebrationOverlayPainter({
    required this.t,
    required this.phase,
    required this.bokehDots,
    required this.sparkles,
  });

  final double t;
  final double phase;
  final List<_BokehDot> bokehDots;
  final List<_SparkleDot> sparkles;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.62);
    final rayScale = lerpDouble(0.9, 1.05, Curves.easeInOut.transform((t * 0.85).clamp(0.0, 1.0))) ?? 1.0;

    _paintRays(canvas, size, center, rayScale);
    _paintBokeh(canvas, size);
    _paintSparkles(canvas, size);
    _paintGlassRimGlow(canvas, size, center);
    _paintGlitterSweep(canvas, size, center);
  }

  void _paintRays(Canvas canvas, Size size, Offset center, double scale) {
    final rays = 28;
    final radius = size.longestSide * 0.82 * scale;
    final baseOpacity = (0.26 * phase).clamp(0.0, 0.26);

    canvas.save();
    canvas.translate(center.dx, center.dy);

    for (var i = 0; i < rays; i++) {
      final angle = (math.pi * 2 / rays) * i + math.sin(i * 0.41) * 0.06;
      final width = (math.pi * 2 / rays) * (0.38 + (i % 4) * 0.08);
      final rayPath = Path()
        ..moveTo(0, 0)
        ..arcTo(
          Rect.fromCircle(center: Offset.zero, radius: radius),
          angle - width * 0.5,
          width,
          false,
        )
        ..close();

      final rayPaint = Paint()
        ..blendMode = BlendMode.screen
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24)
        ..shader = RadialGradient(
          radius: 1,
          colors: [
            Colors.white.withValues(alpha: baseOpacity * 1.35),
            const Color(0xFF8AD7FF).withValues(alpha: baseOpacity * 0.44),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));

      canvas.drawPath(rayPath, rayPaint);
    }

    canvas.restore();
  }

  void _paintBokeh(Canvas canvas, Size size) {
    for (final dot in bokehDots) {
      final flicker = 0.6 + 0.4 * math.sin((t * 2 * math.pi) + dot.phase);
      final alpha = (dot.alpha * phase * flicker).clamp(0.0, 0.22);
      if (alpha <= 0.001) {
        continue;
      }

      final position = Offset(dot.x * size.width, dot.y * size.height);
      final rect = Rect.fromCircle(center: position, radius: dot.radius * 1.7);
      final paint = Paint()
        ..blendMode = BlendMode.screen
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: alpha),
            const Color(0xFFD7F2FF).withValues(alpha: alpha * 0.7),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect);
      canvas.drawCircle(position, dot.radius, paint);
    }
  }

  void _paintSparkles(Canvas canvas, Size size) {
    for (final sparkle in sparkles) {
      final cycleT = (t + sparkle.phaseShift) % 1.0;
      final localT = (cycleT / sparkle.duration).clamp(0.0, 1.0);
      if (localT <= 0) {
        continue;
      }

      final fadeIn = Curves.easeOut.transform((localT / 0.25).clamp(0.0, 1.0));
      final fadeOut = 1 - Curves.easeIn.transform(((localT - 0.64) / 0.36).clamp(0.0, 1.0));
      final opacity = (fadeIn * fadeOut * 0.75 * phase).clamp(0.0, 0.75);
      if (opacity <= 0.001) {
        continue;
      }

      final driftX = math.sin((localT * math.pi * 2) + sparkle.phaseShift * 9) * sparkle.driftX;
      final driftY = -localT * sparkle.rise;
      final center = Offset(
        sparkle.x * size.width + driftX,
        sparkle.y * size.height + driftY,
      );

      final paint = Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: opacity),
            const Color(0xFFAEDFFF).withValues(alpha: opacity * 0.65),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: sparkle.size));

      canvas.drawCircle(center, sparkle.size, paint);
    }
  }

  void _paintGlassRimGlow(Canvas canvas, Size size, Offset center) {
    final glowRect = Rect.fromCircle(center: center, radius: size.width * 0.26);
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.20 * phase),
          const Color(0xFF8ED8FF).withValues(alpha: 0.22 * phase),
          Colors.white.withValues(alpha: 0.14 * phase),
          Colors.transparent,
        ],
        stops: const [0.0, 0.2, 0.52, 0.82, 1.0],
      ).createShader(glowRect);

    canvas.drawArc(glowRect, -math.pi, math.pi * 2, false, glowPaint);
  }

  void _paintGlitterSweep(Canvas canvas, Size size, Offset center) {
    final shimmerAlpha = (0.10 * phase).clamp(0.0, 0.10);
    final rect = Rect.fromCenter(center: center.translate(0, size.height * 0.18), width: size.width * 0.95, height: size.height * 0.30);
    final paint = Paint()
      ..blendMode = BlendMode.screen
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: shimmerAlpha),
          const Color(0xFFAEDFFF).withValues(alpha: shimmerAlpha * 0.72),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);

    canvas.drawOval(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _CelebrationOverlayPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.phase != phase;
  }
}

class _BokehDot {
  _BokehDot({
    required this.x,
    required this.y,
    required this.radius,
    required this.alpha,
    required this.phase,
  });

  factory _BokehDot.seeded(int i) {
    final random = math.Random(111 + i * 17);
    return _BokehDot(
      x: random.nextDouble(),
      y: 0.24 + random.nextDouble() * 0.78,
      radius: 6 + random.nextDouble() * 54,
      alpha: 0.05 + random.nextDouble() * 0.17,
      phase: random.nextDouble() * math.pi * 2,
    );
  }

  final double x;
  final double y;
  final double radius;
  final double alpha;
  final double phase;
}

class _SparkleDot {
  _SparkleDot({
    required this.x,
    required this.y,
    required this.size,
    required this.duration,
    required this.phaseShift,
    required this.rise,
    required this.driftX,
  });

  factory _SparkleDot.seeded(int i) {
    final random = math.Random(901 + i * 13);
    final distanceFromCenter = math.min(1.0, random.nextDouble() * random.nextDouble());
    final horizontalSpread = (random.nextDouble() - 0.5) * (0.22 + distanceFromCenter * 0.76);
    return _SparkleDot(
      x: (0.5 + horizontalSpread).clamp(0.06, 0.94),
      y: (0.40 + random.nextDouble() * (0.42 + distanceFromCenter * 0.12)).clamp(0.22, 0.90),
      size: 1 + random.nextDouble() * 5,
      duration: 0.52 + random.nextDouble() * 0.35,
      phaseShift: random.nextDouble(),
      rise: 6 + random.nextDouble() * 22,
      driftX: 2 + random.nextDouble() * 10,
    );
  }

  final double x;
  final double y;
  final double size;
  final double duration;
  final double phaseShift;
  final double rise;
  final double driftX;
}
