import 'package:flutter/material.dart';

import 'painters/glass_water_palette.dart';

class WateryBackground extends StatelessWidget {
  const WateryBackground({
    super.key,
    required this.tintColor,
  });

  final Color tintColor;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: WateryBackgroundPainter(
            tintColor: tintColor,
          ),
        ),
      ),
    );
  }
}

class WateryBackgroundPainter extends CustomPainter {
  const WateryBackgroundPainter({required this.tintColor});

  final Color tintColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white,
          tintColor.withValues(alpha: 0.16),
          Colors.white,
        ],
        stops: const [0.0, 0.56, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.15),
        radius: 0.95,
        colors: [
          GlassWaterPalette.fullBackgroundTint(amount: 0.44).withValues(alpha: 0.22),
          tintColor.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.56, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, glowPaint);

    final bandPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          tintColor.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.42),
        width: size.width * 0.95,
        height: size.height * 0.32,
      ));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.42),
        width: size.width * 0.95,
        height: size.height * 0.32,
      ),
      bandPaint,
    );
  }

  @override
  bool shouldRepaint(covariant WateryBackgroundPainter oldDelegate) {
    return oldDelegate.tintColor != tintColor;
  }
}
