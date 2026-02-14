import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

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

      final alpha = (1 - ringT) * 0.34;
      final width = 14 + maxWidth * ringT;
      final height = width * 0.3;
      final ringRect = Rect.fromCenter(center: center, width: width, height: height);

      final shadowPaint = Paint()
        ..color = const Color(0xFF5F7389).withValues(alpha: alpha * 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

      final glowPaint = Paint()
        ..color = AppColors.primary.withValues(alpha: alpha * 0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      final ripplePaint = Paint()
        ..color = AppColors.primary.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..blendMode = BlendMode.srcOver;

      canvas.drawOval(ringRect, shadowPaint);
      canvas.drawOval(ringRect.deflate(0.8), glowPaint);
      canvas.drawOval(ringRect, ripplePaint);
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
