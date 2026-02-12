import 'dart:math' as math;

import 'package:flutter/material.dart';

class WateryBackground extends StatefulWidget {
  const WateryBackground({super.key});

  @override
  State<WateryBackground> createState() => _WateryBackgroundState();
}

class _WateryBackgroundState extends State<WateryBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  late final List<_SparkleSpec> _sparkles = List<_SparkleSpec>.generate(
    42,
    (index) {
      final random = math.Random(9000 + index * 31);
      return _SparkleSpec(
        x: random.nextDouble(),
        y: random.nextDouble(),
        radius: 0.7 + random.nextDouble() * 1.8,
        phase: random.nextDouble() * math.pi * 2,
        speed: 0.7 + random.nextDouble() * 1.1,
      );
    },
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => SizedBox.expand(
          child: CustomPaint(
            painter: WateryBackgroundPainter(
              t: _controller.value,
              sparkles: _sparkles,
            ),
          ),
        ),
      ),
    );
  }
}

class WateryBackgroundPainter extends CustomPainter {
  WateryBackgroundPainter({required this.t, required this.sparkles});

  final double t;
  final List<_SparkleSpec> sparkles;

  final Paint _basePaint = Paint();
  final Paint _causticPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0x29FFFFFF);
  final Paint _wavePaint = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0x140C6E8F);
  final Paint _sparklePaint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    _basePaint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFE8F5FA),
        Color(0xFFDEEEF6),
        Color(0xFFEFF7FC),
      ],
      stops: [0.0, 0.55, 1.0],
    ).createShader(rect);
    canvas.drawRect(rect, _basePaint);

    _paintWaveShadows(canvas, size);
    _paintCaustics(canvas, size);
    _paintSparkles(canvas, size);
  }

  void _paintWaveShadows(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    for (var i = 0; i < 3; i++) {
      final phase = t * math.pi * 2 + i * 1.7;
      final dx = math.sin(phase * (0.55 + i * 0.2)) * w * 0.1;
      final dy = math.cos(phase * (0.45 + i * 0.15)) * h * 0.06;
      final center = Offset(w * (0.2 + i * 0.3) + dx, h * (0.28 + i * 0.24) + dy);
      final waveRect = Rect.fromCenter(
        center: center,
        width: w * (0.7 + i * 0.18),
        height: h * (0.35 + i * 0.12),
      );
      canvas.drawOval(waveRect, _wavePaint);
    }
  }

  void _paintCaustics(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    for (var i = 0; i < 7; i++) {
      final phase = t * math.pi * 2 + i * 0.9;
      final cx = w * (i / 6) + math.sin(phase * 0.7) * 18;
      final cy = h * (0.18 + (i % 4) * 0.22) + math.cos(phase * 0.9) * 14;
      final rw = w * (0.23 + (i % 3) * 0.05);
      final rh = h * (0.035 + (i % 2) * 0.01);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: rw, height: rh), _causticPaint);
    }
  }

  void _paintSparkles(Canvas canvas, Size size) {
    for (final sparkle in sparkles) {
      final blink = (math.sin((t * math.pi * 2 * sparkle.speed) + sparkle.phase) + 1) * 0.5;
      final alpha = 0.02 + blink * 0.09;
      _sparklePaint.color = Colors.white.withValues(alpha: alpha);
      final center = Offset(size.width * sparkle.x, size.height * sparkle.y);
      canvas.drawCircle(center, sparkle.radius, _sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant WateryBackgroundPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.sparkles != sparkles;
  }
}

class _SparkleSpec {
  const _SparkleSpec({
    required this.x,
    required this.y,
    required this.radius,
    required this.phase,
    required this.speed,
  });

  final double x;
  final double y;
  final double radius;
  final double phase;
  final double speed;
}
