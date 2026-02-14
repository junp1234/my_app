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
  final List<_SparkleCross> _sparkles = List.generate(20, (index) => _SparkleCross.seeded(index));

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
  final List<_SparkleCross> sparkles;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.62);
    final rayScale = lerpDouble(0.9, 1.05, Curves.easeInOut.transform((t * 0.85).clamp(0.0, 1.0))) ?? 1.0;

    _paintRays(canvas, size, center, rayScale);
    _paintBokeh(canvas, size);
    _paintSparkles(canvas, size);
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
    final wave = Curves.easeInOut.transform((t * 1.2).clamp(0.0, 1.0));

    for (final dot in bokehDots) {
      final yLift = (dot.speed * (0.08 + wave * 0.18)) * size.height;
      final flicker = 0.6 + 0.4 * math.sin((t * 2 * math.pi) + dot.phase);
      final alpha = (dot.alpha * phase * flicker).clamp(0.0, 0.22);
      if (alpha <= 0.001) {
        continue;
      }

      final position = Offset(dot.x * size.width, dot.y * size.height - yLift);
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
      final localT = ((t - sparkle.phase) * 2.2).clamp(0.0, 1.0);
      if (localT <= 0) {
        continue;
      }
      final blink = math.sin(localT * math.pi);
      final opacity = (blink * 0.7 * phase).clamp(0.0, 0.7);
      if (opacity <= 0.001) {
        continue;
      }

      final center = Offset(sparkle.x * size.width, sparkle.y * size.height - (localT * sparkle.rise * size.height));
      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.2
        ..blendMode = BlendMode.plus
        ..color = Colors.white.withValues(alpha: opacity);

      canvas.drawLine(center.translate(-sparkle.size, 0), center.translate(sparkle.size, 0), paint);
      canvas.drawLine(center.translate(0, -sparkle.size), center.translate(0, sparkle.size), paint);
    }
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
    required this.speed,
    required this.alpha,
    required this.phase,
  });

  factory _BokehDot.seeded(int i) {
    final random = math.Random(111 + i * 17);
    return _BokehDot(
      x: random.nextDouble(),
      y: 0.24 + random.nextDouble() * 0.78,
      radius: 6 + random.nextDouble() * 54,
      speed: 0.45 + random.nextDouble() * 0.55,
      alpha: 0.05 + random.nextDouble() * 0.17,
      phase: random.nextDouble() * math.pi * 2,
    );
  }

  final double x;
  final double y;
  final double radius;
  final double speed;
  final double alpha;
  final double phase;
}

class _SparkleCross {
  _SparkleCross({
    required this.x,
    required this.y,
    required this.size,
    required this.phase,
    required this.rise,
  });

  factory _SparkleCross.seeded(int i) {
    final random = math.Random(901 + i * 13);
    return _SparkleCross(
      x: 0.08 + random.nextDouble() * 0.84,
      y: 0.34 + random.nextDouble() * 0.56,
      size: 6 + random.nextDouble() * 12,
      phase: random.nextDouble() * 0.62,
      rise: 0.03 + random.nextDouble() * 0.05,
    );
  }

  final double x;
  final double y;
  final double size;
  final double phase;
  final double rise;
}
