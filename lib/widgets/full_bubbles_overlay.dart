import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

class FullBubblesOverlay extends StatefulWidget {
  const FullBubblesOverlay({super.key});

  @override
  State<FullBubblesOverlay> createState() => _FullBubblesOverlayState();
}

class _FullBubblesOverlayState extends State<FullBubblesOverlay> with SingleTickerProviderStateMixin {
  static const int _bubbleCount = 42;
  static const double _maxDriftPx = 6;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  late final List<_BubbleSpec> _bubbles = _createBubbles();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_BubbleSpec> _createBubbles() {
    final random = math.Random(90210);
    return List<_BubbleSpec>.generate(_bubbleCount, (_) {
      final size = lerpDouble(2, 10, random.nextDouble())!;
      final alpha = lerpDouble(0.10, 0.30, random.nextDouble())!;
      return _BubbleSpec(
        x: random.nextDouble(),
        baseSize: size,
        speed: lerpDouble(0.8, 1.33, random.nextDouble())!,
        phase: random.nextDouble(),
        drift: random.nextDouble(),
        alpha: alpha,
        strokeWidth: lerpDouble(0.8, 1.4, random.nextDouble())!,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return CustomPaint(
            painter: _FullBubblesPainter(
              t: _controller.value,
              bubbles: _bubbles,
              maxDriftPx: _maxDriftPx,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _FullBubblesPainter extends CustomPainter {
  _FullBubblesPainter({
    required this.t,
    required this.bubbles,
    required this.maxDriftPx,
  });

  final double t;
  final List<_BubbleSpec> bubbles;
  final double maxDriftPx;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x33D8F1FF),
          Color(0x52BFE9FF),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, background);

    final highlightPaint = Paint()..style = PaintingStyle.fill;
    final outlinePaint = Paint()..style = PaintingStyle.stroke;

    for (final bubble in bubbles) {
      final bubbleY = 1.0 - ((t * bubble.speed + bubble.phase) % 1.0);
      final y = bubbleY * size.height;
      final sway = math.sin((t + bubble.phase) * math.pi * 2) * maxDriftPx * bubble.drift;
      final x = bubble.x * size.width + sway;

      final center = Offset(x, y);

      outlinePaint
        ..strokeWidth = bubble.strokeWidth
        ..color = Colors.white.withValues(alpha: bubble.alpha);
      canvas.drawCircle(center, bubble.baseSize, outlinePaint);

      highlightPaint.color = Colors.white.withValues(alpha: bubble.alpha * 0.35);
      canvas.drawCircle(
        center.translate(-bubble.baseSize * 0.28, -bubble.baseSize * 0.35),
        bubble.baseSize * 0.25,
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FullBubblesPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.bubbles != bubbles;
  }
}

class _BubbleSpec {
  const _BubbleSpec({
    required this.x,
    required this.baseSize,
    required this.speed,
    required this.phase,
    required this.drift,
    required this.alpha,
    required this.strokeWidth,
  });

  final double x;
  final double baseSize;
  final double speed;
  final double phase;
  final double drift;
  final double alpha;
  final double strokeWidth;
}
