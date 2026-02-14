import 'package:flutter/material.dart';

class RipplePainter extends CustomPainter {
  const RipplePainter({
    required this.t,
    required this.center,
    required this.maxWidth,
    required this.extraLayer,
  });

  final double t;
  final Offset center;
  final double maxWidth;
  final bool extraLayer;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) {
      return;
    }

    final eased = Curves.easeOut.transform(t);
    final rings = [0.0, 0.16, 0.3, if (extraLayer) 0.42];
    for (final lag in rings) {
      final ringT = ((eased - lag) / (1 - lag)).clamp(0.0, 1.0);
      if (ringT <= 0) {
        continue;
      }

      final oldOpacity = (1 - ringT) * 0.28;
      final rippleColor = Colors.white.withValues(alpha: (oldOpacity + 0.12).clamp(0.0, 1.0));
      final width = 14 + maxWidth * ringT;
      final height = width * 0.3;
      final ripplePaint = Paint()
        ..color = rippleColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawOval(Rect.fromCenter(center: center, width: width, height: height), ripplePaint);
    }
  }

  @override
  bool shouldRepaint(covariant RipplePainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.center != center ||
        oldDelegate.maxWidth != maxWidth ||
        oldDelegate.extraLayer != extraLayer;
  }
}
