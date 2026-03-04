import 'dart:math' as math;

import 'package:flutter/material.dart';

class GlassGauge extends StatelessWidget {
  const GlassGauge({
    super.key,
    required this.progress,
    required this.rippleT,
    required this.dropT,
    this.extraRippleLayer = false,
    this.size = 272,
  });

  final double progress;
  final double rippleT;
  final double dropT;
  final bool extraRippleLayer;
  final double size;

  @override
  Widget build(BuildContext context) {
    final gaugeSize = Size.square(size);
    final percent = progress <= 1.0 ? progress * 100.0 : progress;
    final clamped = percent.clamp(0, 100).toDouble();
    final fill = clamped / 100.0;
    final inset = size * 0.08;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          CustomPaint(
            size: gaugeSize,
            painter: const _GlassBackdropPainter(),
          ),
          Padding(
            padding: EdgeInsets.all(inset),
            child: ClipOval(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _WaterFillPainter(
                      fill: fill,
                      t: rippleT,
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0x12000000),
                          Color(0x33000000),
                        ],
                        stops: [0.55, 0.82, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Transform.scale(
              scale: 1.12,
              child: Image.asset(
                'assets/images/bowl.png',
                fit: BoxFit.contain,
                semanticLabel: 'Water bowl',
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassBackdropPainter extends CustomPainter {
  const _GlassBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final ovalRect = Rect.fromCenter(
      center: rect.center,
      width: size.width * 0.82,
      height: size.height * 0.82,
    );

    final ambient = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.18, -0.24),
        radius: 1.0,
        colors: [
          const Color(0xFFEFFCFF).withValues(alpha: 0.20),
          const Color(0xFFCFE9FA).withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.72, 1.0],
      ).createShader(ovalRect);

    canvas.drawOval(ovalRect, ambient);
  }

  @override
  bool shouldRepaint(covariant _GlassBackdropPainter oldDelegate) => false;
}

class _WaterFillPainter extends CustomPainter {
  const _WaterFillPainter({required this.fill, required this.t});

  final double fill;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final clampedFill = fill.clamp(0.0, 1.0);
    if (clampedFill <= 0) {
      return;
    }

    final width = size.width;
    final height = size.height;
    final waterTopY = height * (1 - clampedFill);
    final amp = (2.0 + clampedFill * 4.0).clamp(2.0, 6.0);
    final phase = t * math.pi * 2;

    final surfacePath = Path()..moveTo(0, waterTopY + math.sin(phase) * amp);

    for (double x = 0; x <= width; x += 2) {
      final y = waterTopY + math.sin((x / width * math.pi * 2) + phase) * amp;
      surfacePath.lineTo(x, y);
    }

    final waterPath = Path.from(surfacePath)
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFBFEFFF).withValues(alpha: 0.48),
          const Color(0xFF7CCEF5).withValues(alpha: 0.72),
          const Color(0xFF2E93D2).withValues(alpha: 0.95),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, waterTopY - 12, width, height - waterTopY + 12));

    canvas.drawPath(waterPath, fillPaint);

    final topHighlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.25)
      ..isAntiAlias = true;
    canvas.drawPath(surfacePath, topHighlightPaint);

    final topShadowPath = Path()..moveTo(0, waterTopY + 2 + math.sin(phase) * amp);
    for (double x = 0; x <= width; x += 2) {
      final y = waterTopY + 2 + math.sin((x / width * math.pi * 2) + phase) * amp;
      topShadowPath.lineTo(x, y);
    }

    final topShadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF1D5A87).withValues(alpha: 0.12)
      ..isAntiAlias = true;
    canvas.drawPath(topShadowPath, topShadowPaint);
  }

  @override
  bool shouldRepaint(covariant _WaterFillPainter oldDelegate) {
    return oldDelegate.fill != fill || oldDelegate.t != t;
  }
}
