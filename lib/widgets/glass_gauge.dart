import 'package:flutter/material.dart';

import 'painters/ripple_painter.dart';
import 'painters/water_fill_painter.dart';

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

  static const double bowlRadiusFactor = 0.39;
  static const double innerDeflate = 11;

  static Rect outerRectForSize(Size size) {
    final center = size.center(Offset.zero);
    return Rect.fromCircle(center: center, radius: size.width * bowlRadiusFactor);
  }

  static Rect innerRectForSize(Size size) {
    return outerRectForSize(size).deflate(innerDeflate);
  }

  @override
  Widget build(BuildContext context) {
    final gaugeSize = Size.square(size);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            size: gaugeSize,
            painter: _GlassWaterPainter(
              progress: progress,
            ),
          ),
          CustomPaint(
            size: gaugeSize,
            painter: _GlassRipplePainter(
              progress: progress,
              rippleT: rippleT,
              extraRippleLayer: extraRippleLayer,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassWaterPainter extends CustomPainter {
  const _GlassWaterPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final innerRect = GlassGauge.innerRectForSize(size);

    final airVolumePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.28),
        radius: 1.08,
        colors: [
          const Color(0xFFEFFCFF).withValues(alpha: 0.20),
          const Color(0xFFCFE9FA).withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(innerRect);
    canvas.drawOval(innerRect, airVolumePaint);

    canvas.save();
    canvas.clipPath(Path()..addOval(innerRect));
    WaterFillPainter(innerRect: innerRect, progress: progress).paint(canvas, size);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GlassWaterPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _GlassRipplePainter extends CustomPainter {
  const _GlassRipplePainter({
    required this.progress,
    required this.rippleT,
    required this.extraRippleLayer,
  });

  final double progress;
  final double rippleT;
  final bool extraRippleLayer;

  @override
  void paint(Canvas canvas, Size size) {
    final innerRect = GlassGauge.innerRectForSize(size);
    final waterTopY = WaterFillPainter.waterTopYForProgress(innerRect, progress);
    final rippleCenter = Offset(size.width / 2, waterTopY);
    final waterPath = WaterFillPainter.waterPathForProgress(innerRect, progress);

    canvas.save();
    canvas.clipPath(waterPath);
    RipplePainter(
      t: rippleT,
      center: rippleCenter,
      maxWidth: innerRect.width * 0.45,
      extraLayer: extraRippleLayer,
    ).paint(canvas, size);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GlassRipplePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.rippleT != rippleT ||
        oldDelegate.extraRippleLayer != extraRippleLayer;
  }
}
