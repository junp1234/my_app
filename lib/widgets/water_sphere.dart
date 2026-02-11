import 'dart:math' as math;

import 'package:flutter/material.dart';

class WaterSphere extends StatefulWidget {
  const WaterSphere({
    super.key,
    required this.size,
    required this.child,
  });

  final double size;
  final Widget child;

  @override
  State<WaterSphere> createState() => WaterSphereState();
}

class WaterSphereState extends State<WaterSphere>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wobbleController;
  late final Animation<double> _wobbleCurve;

  @override
  void initState() {
    super.initState();
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _wobbleCurve = CurvedAnimation(
      parent: _wobbleController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    super.dispose();
  }

  Future<void> triggerWobble() async {
    await _wobbleController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: triggerWobble,
        child: AnimatedBuilder(
          animation: _wobbleCurve,
          builder: (context, _) {
            final wobble = _wobbleCurve.value;
            final wobbleWave = math.sin(wobble * math.pi);
            final scaleX = 1 + (0.05 * wobbleWave);
            final scaleY = 1 - (0.04 * wobbleWave);

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..scale(scaleX, scaleY),
              child: ClipOval(
                child: CustomPaint(
                  painter: WaterSpherePainter(wobble: wobble),
                  child: Center(child: widget.child),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class WaterSpherePainter extends CustomPainter {
  WaterSpherePainter({required this.wobble});

  final double wobble;

  static final List<_BubbleSeed> _bubbleSeeds = _buildBubbleSeeds();

  static List<_BubbleSeed> _buildBubbleSeeds() {
    final random = math.Random(1207);
    return List.generate(44, (_) {
      final x = random.nextDouble();
      final yBias = math.pow(random.nextDouble(), 1.8).toDouble();
      final y = yBias * 0.95;
      final r = 0.008 + random.nextDouble() * 0.02;
      final alpha = 0.08 + random.nextDouble() * 0.16;
      return _BubbleSeed(x: x, y: y, radiusFactor: r, alpha: alpha);
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) * 0.5;
    final sphereRect = Rect.fromCircle(center: center, radius: radius);

    final wobbleAngle = wobble * math.pi * 2.4;
    final shiftX = math.sin(wobbleAngle) * size.width * 0.018;
    final shiftY = math.cos(wobbleAngle * 0.8) * size.height * 0.012;

    final basePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          -0.15 + (shiftX / size.width),
          -0.25 + (shiftY / size.height),
        ),
        radius: 1.08,
        colors: const [
          Color(0xB8D9F8FF),
          Color(0xA67EDBFF),
          Color(0x7A58C2F0),
          Color(0x963A8CC4),
        ],
        stops: const [0.0, 0.34, 0.78, 1.0],
      ).createShader(sphereRect);
    canvas.drawOval(sphereRect, basePaint);

    final bottomShadePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0x552D77B2),
        ],
        stops: const [0.48, 1.0],
      ).createShader(sphereRect);
    canvas.drawOval(sphereRect, bottomShadePaint);

    _drawCaustics(canvas, size, wobbleAngle);
    _drawMicroBubbles(canvas, size, shiftX, shiftY);
    _drawSpecularHighlights(canvas, size, shiftX, shiftY);
    _drawMembrane(canvas, sphereRect, radius);
  }

  void _drawCaustics(Canvas canvas, Size size, double wobbleAngle) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

    for (var i = 0; i < 4; i++) {
      final phase = wobbleAngle + i * 0.7;
      final startY = size.height * (0.26 + (i * 0.14)) + math.sin(phase) * 2.5;
      final bandHeight = size.height * (0.08 + i * 0.01);
      final horizontalDrift = math.cos(phase * 1.25) * size.width * 0.028;

      final path = Path()
        ..moveTo(size.width * 0.1 + horizontalDrift, startY)
        ..cubicTo(
          size.width * 0.28 + horizontalDrift,
          startY - bandHeight,
          size.width * 0.52 + horizontalDrift,
          startY + bandHeight,
          size.width * 0.84 + horizontalDrift,
          startY,
        )
        ..lineTo(size.width * 0.84 + horizontalDrift, startY + bandHeight * 0.45)
        ..cubicTo(
          size.width * 0.56 + horizontalDrift,
          startY + bandHeight * 1.2,
          size.width * 0.3 + horizontalDrift,
          startY - bandHeight * 0.2,
          size.width * 0.1 + horizontalDrift,
          startY + bandHeight * 0.45,
        )
        ..close();

      paint.color = Colors.white.withValues(alpha: 0.06 + (0.02 * (3 - i)));
      canvas.drawPath(path, paint);
    }
  }

  void _drawMicroBubbles(Canvas canvas, Size size, double shiftX, double shiftY) {
    for (final bubble in _bubbleSeeds) {
      final bubbleX = size.width * bubble.x + (shiftX * (0.2 + bubble.y));
      final bubbleY = size.height * bubble.y + (shiftY * (0.16 + bubble.x * 0.24));
      final bubbleRadius = math.max(0.8, size.shortestSide * bubble.radiusFactor);

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: bubble.alpha),
            Colors.white.withValues(alpha: bubble.alpha * 0.35),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(
          Rect.fromCircle(
            center: Offset(bubbleX, bubbleY),
            radius: bubbleRadius,
          ),
        );

      canvas.drawCircle(Offset(bubbleX, bubbleY), bubbleRadius, paint);
    }
  }

  void _drawSpecularHighlights(Canvas canvas, Size size, double shiftX, double shiftY) {
    final primaryHighlight = Rect.fromCenter(
      center: Offset(
        size.width * 0.34 + shiftX * 1.3,
        size.height * 0.27 + shiftY * 0.7,
      ),
      width: size.width * 0.48,
      height: size.height * 0.24,
    );
    final primaryPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.2),
        radius: 1.0,
        colors: [
          Colors.white.withValues(alpha: 0.62),
          const Color(0xFFEEFCFF).withValues(alpha: 0.34),
          Colors.transparent,
        ],
        stops: const [0.0, 0.52, 1.0],
      ).createShader(primaryHighlight);
    canvas.drawOval(primaryHighlight, primaryPaint);

    final secondaryHighlight = Rect.fromCenter(
      center: Offset(
        size.width * 0.7 - shiftX * 0.9,
        size.height * 0.2 + shiftY * 0.4,
      ),
      width: size.width * 0.16,
      height: size.height * 0.095,
    );
    final secondaryPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.48)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
    canvas.drawOval(secondaryHighlight, secondaryPaint);
  }

  void _drawMembrane(Canvas canvas, Rect rect, double radius) {
    final rimOuter = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, radius * 0.032)
      ..shader = SweepGradient(
        startAngle: -math.pi,
        endAngle: math.pi,
        colors: [
          Colors.white.withValues(alpha: 0.48),
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.42),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawOval(rect.deflate(rimOuter.strokeWidth * 0.5), rimOuter);

    final innerShadow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.9, radius * 0.024)
      ..shader = SweepGradient(
        startAngle: -math.pi,
        endAngle: math.pi,
        colors: [
          const Color(0x802A6A9B),
          const Color(0x402A6A9B),
          const Color(0x902A6A9B),
        ],
      ).createShader(rect);
    canvas.drawOval(rect.deflate(rimOuter.strokeWidth + 1), innerShadow);
  }

  @override
  bool shouldRepaint(covariant WaterSpherePainter oldDelegate) {
    return oldDelegate.wobble != wobble;
  }
}

class _BubbleSeed {
  const _BubbleSeed({
    required this.x,
    required this.y,
    required this.radiusFactor,
    required this.alpha,
  });

  final double x;
  final double y;
  final double radiusFactor;
  final double alpha;
}
