import 'dart:ui';

import 'package:flutter/material.dart';

class WaterFillPainter extends CustomPainter {
  const WaterFillPainter({
    required this.innerRect,
    required this.progress,
  });

  final Rect innerRect;
  final double progress;

  static const double _minVisualFill = 0.0;
  static const double _innerTopPadding = 4;
  static const double _fullThreshold = 0.999;

  static bool _isFull(double progress) {
    return progress.clamp(0.0, 1.0).toDouble() >= _fullThreshold;
  }

  static double visualFillForProgress(double progress) {
    final clamped = progress.clamp(0.0, 1.0).toDouble();
    if (_isFull(clamped)) {
      return 1.0;
    }
    return clamped;
  }

  static double waterTopYForProgress(Rect innerRect, double progress) {
    final clamped = progress.clamp(0.0, 1.0).toDouble();
    if (_isFull(clamped)) {
      return innerRect.top;
    }
    final visualFill = visualFillForProgress(clamped);
    final bottomInnerY = innerRect.bottom;
    final topInnerY = innerRect.top;
    final minY = bottomInnerY - 6;
    final maxY = topInnerY + _innerTopPadding;
    return lerpDouble(minY, maxY, visualFill) ?? minY;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final clampedProgress = progress.clamp(0.0, 1.0).toDouble();
    if (clampedProgress <= 0) {
      return;
    }
    final isFull = _isFull(clampedProgress);
    final visualFill = visualFillForProgress(clampedProgress);
    final waterTopY = waterTopYForProgress(innerRect, clampedProgress);
    final centerX = innerRect.center.dx;

    final curveDepth = isFull ? 0.0 : 8 + visualFill * 4;
    final waterPath = isFull
        ? (Path()..addRect(innerRect.inflate(2)))
        : (Path()
            ..moveTo(innerRect.left - 2, innerRect.bottom + 2)
            ..lineTo(innerRect.left - 2, waterTopY)
            ..quadraticBezierTo(centerX, waterTopY + curveDepth, innerRect.right + 2, waterTopY)
            ..lineTo(innerRect.right + 2, innerRect.bottom + 2)
            ..close());

    final waterRect = Rect.fromLTWH(
      innerRect.left,
      waterTopY - 20,
      innerRect.width,
      innerRect.bottom - waterTopY + 28,
    );

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0x8CD9F5FF),
          const Color(0xB288D6F9),
          const Color(0xD563B6E7),
          const Color(0xDD4B9CD5),
        ],
      ).createShader(waterRect);
    canvas.drawPath(waterPath, fillPaint);

    final refractionPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.20),
          Colors.transparent,
        ],
      ).createShader(waterRect)
      ..blendMode = BlendMode.screen;
    canvas.drawPath(waterPath.shift(const Offset(-7, 0)), refractionPaint);

    if (isFull) {
      return;
    }

    final surfacePath = Path()
      ..moveTo(innerRect.left + 16, waterTopY + 1)
      ..quadraticBezierTo(centerX, waterTopY + curveDepth - 3, innerRect.right - 16, waterTopY + 1);

    final surfaceLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.16),
          Colors.white.withValues(alpha: 0.10),
        ],
      ).createShader(Rect.fromLTWH(innerRect.left, waterTopY, innerRect.width, 8));
    canvas.drawPath(surfacePath, surfaceLinePaint);

    final highlightRect = Rect.fromCenter(
      center: Offset(centerX, waterTopY + curveDepth - 1),
      width: innerRect.width * 0.48,
      height: innerRect.height * 0.06,
    );
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.14),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(highlightRect);
    canvas.drawOval(highlightRect, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant WaterFillPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.innerRect != innerRect;
  }
}
