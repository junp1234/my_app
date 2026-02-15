import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../painters/soap_bubbles_painter.dart';

class SoapBubblesOverlay extends StatefulWidget {
  const SoapBubblesOverlay({super.key});

  @override
  State<SoapBubblesOverlay> createState() => _SoapBubblesOverlayState();
}

class _SoapBubblesOverlayState extends State<SoapBubblesOverlay> with SingleTickerProviderStateMixin {
  static const int _bubbleCount = 26;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  late final List<SoapBubbleSpec> _bubbles = _createBubbles();

  List<SoapBubbleSpec> _createBubbles() {
    final random = math.Random(77123);
    return List<SoapBubbleSpec>.generate(_bubbleCount, (_) {
      final radius = lerpDouble(10, 42, random.nextDouble())!;
      final normalizedRadius = (radius - 10) / 32;
      final riseSpeed = lerpDouble(1.28, 0.78, normalizedRadius)!;
      final outlineAlpha = lerpDouble(0.22, 0.34, random.nextDouble())!;
      return SoapBubbleSpec(
        x: random.nextDouble(),
        yPhase: random.nextDouble(),
        radius: radius,
        riseSpeed: riseSpeed,
        swayPhase: random.nextDouble() * math.pi * 2,
        swayAmount: lerpDouble(4, 12, random.nextDouble())!,
        outlineAlpha: outlineAlpha,
        highlightAlpha: lerpDouble(0.35, 0.55, random.nextDouble())!,
        outlineWidth: lerpDouble(1.2, 2.0, random.nextDouble())!,
      );
    });
  }

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
        builder: (_, __) {
          return CustomPaint(
            painter: SoapBubblesPainter(t: _controller.value, bubbles: _bubbles),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}
