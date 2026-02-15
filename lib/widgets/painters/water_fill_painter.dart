import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/water_theme.dart';

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

  static bool isFullProgress(double progress) {
    return progress.clamp(0.0, 1.0).toDouble() >= _fullThreshold;
  }

  // Backward-compatible alias for older call sites.
  static bool isFull(double progress) {
    return isFullProgress(progress);
  }

  static double visualFillForProgress(double progress) {
    final clamped = progress.clamp(0.0, 1.0).toDouble();
    if (isFullProgress(clamped)) {
      return 1.0;
    }
    return lerpDouble(_minVisualFill, 1.0, clamped) ?? _minVisualFill;
  }

  static double waterTopYForProgress(Rect innerRect, double progress) {
    final clamped = progress.clamp(0.0, 1.0).toDouble();
    if (isFullProgress(clamped)) {
      return innerRect.top;
    }
    final visualFill = visualFillForProgress(clamped);
    final bottomInnerY = innerRect.bottom;
    final topInnerY = innerRect.top;
    final minY = bottomInnerY - 6;
    final maxY = topInnerY + _innerTopPadding;
    return lerpDouble(minY, maxY, visualFill) ?? minY;
  }

  static Path waterPathForProgress(Rect innerRect, double progress) {
    final clampedProgress = progress.clamp(0.0, 1.0).toDouble();
    final full = isFullProgress(clampedProgress);
    final visualFill = visualFillForProgress(clampedProgress);
    final waterTopY = waterTopYForProgress(innerRect, clampedProgress);
    final centerX = innerRect.center.dx;
    final curveDepth = full ? 0.0 : 5 + visualFill * 3;

    return full
        ? (Path()..addRect(innerRect.inflate(2)))
        : (Path()
            ..moveTo(innerRect.left - 2, innerRect.bottom + 2)
            ..lineTo(innerRect.left - 2, waterTopY)
            ..quadraticBezierTo(centerX, waterTopY + curveDepth, innerRect.right + 2, waterTopY)
            ..lineTo(innerRect.right + 2, innerRect.bottom + 2)
            ..close());
  }

  @override
  void paint(Canvas canvas, Size size) {
    final clampedProgress = progress.clamp(0.0, 1.0).toDouble();
    if (clampedProgress <= 0) {
      return;
    }
    final full = isFullProgress(clampedProgress);
    final visualFill = visualFillForProgress(clampedProgress);
    final waterTopY = waterTopYForProgress(innerRect, clampedProgress);
    final centerX = innerRect.center.dx;

    final curveDepth = full ? 0.0 : 5 + visualFill * 3;
    final waterPath = waterPathForProgress(innerRect, clampedProgress);

    final waterRect = waterGradientRectForTop(innerRect, waterTopY);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          WaterTheme.waterTopColor,
          WaterTheme.waterMidColor,
          WaterTheme.waterDeepColor,
          WaterTheme.waterBottomColor,
        ],
        stops: const [0.0, 0.45, 0.76, 1.0],
      ).createShader(waterRect);
    canvas.drawPath(waterPath, fillPaint);

    final globalWaterTint = Paint()
      ..color = WaterTheme.primaryWater.withValues(alpha: 0.10);
    canvas.drawPath(waterPath, globalWaterTint);

    final depthShadowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.65, 0.7),
        radius: 0.95,
        colors: [
          const Color(0xFF2F74A8).withValues(alpha: 0.14),
          Colors.transparent,
        ],
      ).createShader(waterRect);
    canvas.drawPath(waterPath, depthShadowPaint);

    _paintSurfaceGlitter(canvas, waterPath, waterTopY, centerX, full);

    if (full) {
      return;
    }

    final surfacePath = Path()
      ..moveTo(innerRect.left + 14, waterTopY + 0.5)
      ..quadraticBezierTo(centerX, waterTopY + curveDepth - 1, innerRect.right - 14, waterTopY + 0.5);

    final surfaceLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFFE2F8FF).withValues(alpha: 0.0),
          const Color(0xFFEFFFFF).withValues(alpha: 0.26),
          const Color(0xFFE2F8FF).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(innerRect.left, waterTopY, innerRect.width, 8));
    canvas.drawPath(surfacePath, surfaceLinePaint);

    final highlightRect = Rect.fromCenter(
      center: Offset(centerX, waterTopY + curveDepth + 0.8),
      width: innerRect.width * 0.62,
      height: innerRect.height * 0.085,
    );
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFFC7ECFF).withValues(alpha: 0),
          const Color(0xFFE6F8FF).withValues(alpha: 0.20),
          const Color(0xFFC7ECFF).withValues(alpha: 0),
        ],
      ).createShader(highlightRect);
    canvas.drawOval(highlightRect, highlightPaint);

    final underBandRect = Rect.fromCenter(
      center: Offset(centerX, waterTopY + curveDepth + 4),
      width: innerRect.width * 0.65,
      height: innerRect.height * 0.08,
    );
    final underBandPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFF4F9FD5).withValues(alpha: 0),
          const Color(0xFF4F9FD5).withValues(alpha: 0.12),
          const Color(0xFF4F9FD5).withValues(alpha: 0),
        ],
      ).createShader(underBandRect);
    canvas.drawOval(underBandRect, underBandPaint);
  }

  static Rect waterGradientRectForTop(Rect innerRect, double waterTopY) {
    return Rect.fromLTWH(
      innerRect.left,
      waterTopY - 20,
      innerRect.width,
      innerRect.bottom - waterTopY + 28,
    );
  }


  void _paintSurfaceGlitter(Canvas canvas, Path waterPath, double waterTopY, double centerX, bool isFull) {
    canvas.save();
    canvas.clipPath(waterPath);

    final speckPaint = Paint()
      ..blendMode = BlendMode.screen
      ..color = Colors.white.withValues(alpha: isFull ? 0.19 : 0.14);

    for (var i = 0; i < 22; i++) {
      final progressX = i / 21;
      final x = lerpDouble(innerRect.left + 10, innerRect.right - 10, progressX) ?? centerX;
      final wave = math.sin(i * 0.8) * 1.6;
      final y = waterTopY + (isFull ? 3.6 : 2.4) + wave;
      final radius = i % 4 == 0 ? 1.6 : 1.0;
      canvas.drawCircle(Offset(x, y), radius, speckPaint);
    }

    final linePaint = Paint()
      ..blendMode = BlendMode.screen
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: isFull ? 0.28 : 0.22);

    for (var i = 0; i < 7; i++) {
      final shift = i * 0.11;
      final startX = lerpDouble(innerRect.left + 20, innerRect.right - 70, shift) ?? innerRect.left + 20;
      final y = waterTopY + 1 + (i % 2 == 0 ? 0.9 : 2.2);
      canvas.drawLine(Offset(startX, y), Offset(startX + 18 + (i % 3) * 8, y + 0.8), linePaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WaterFillPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.innerRect != innerRect;
  }
}
