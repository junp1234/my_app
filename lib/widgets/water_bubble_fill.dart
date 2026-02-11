import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Circular water fill effect designed to sit inside an existing ring chart.
///
/// - [progress] controls the fill level from 0.0 to 1.0.
/// - Background stays transparent so this widget can be layered.
class WaterBubbleFill extends StatefulWidget {
  const WaterBubbleFill({
    super.key,
    required this.progress,
    this.color = const Color(0xFF4FC3F7),
    this.waveAmplitude = 4,
    this.waveLengthFactor = 1.4,
    this.waveSpeed = 1,
    this.onTap,
    this.enableTapGesture = false,
  });

  final double progress;
  final Color color;
  final double waveAmplitude;
  final double waveLengthFactor;
  final double waveSpeed;
  final VoidCallback? onTap;
  final bool enableTapGesture;

  @override
  State<WaterBubbleFill> createState() => WaterBubbleFillState();
}

class WaterBubbleFillState extends State<WaterBubbleFill>
    with TickerProviderStateMixin {
  late final AnimationController _waveController;
  late final AnimationController _jellyController;
  late final Animation<double> _jellyAnimation;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _jellyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _jellyAnimation = CurvedAnimation(
      parent: _jellyController,
      curve: const ElasticOutCurve(1.2),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _jellyController.dispose();
    super.dispose();
  }

  Future<void> triggerWobble() async {
    widget.onTap?.call();
    await _jellyController.forward(from: 0);
  }

  Widget _buildBubbleBody(double clampedProgress) {
    return AnimatedBuilder(
      animation: Listenable.merge([_waveController, _jellyAnimation]),
      builder: (context, child) {
        final wobbleValue = _jellyAnimation.value;
        final wobblePulse = math.sin(wobbleValue * math.pi);
        final scaleX = 1 + 0.022 * math.sin(wobbleValue * math.pi * 2);
        final scaleY = 1 - 0.018 * math.sin(wobbleValue * math.pi * 2);

        return Transform.scale(
          scaleX: scaleX,
          scaleY: scaleY,
          child: ClipOval(
            child: CustomPaint(
              painter: _WaterBubblePainter(
                progress: clampedProgress,
                wavePhase: _waveController.value * 2 * math.pi,
                color: widget.color,
                waveAmplitude: widget.waveAmplitude,
                waveLengthFactor: widget.waveLengthFactor,
                waveSpeed: widget.waveSpeed,
                wobble: wobblePulse,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final clampedProgress = widget.progress.clamp(0.0, 1.0);
    final bubbleBody = _buildBubbleBody(clampedProgress);

    if (!widget.enableTapGesture) {
      return bubbleBody;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: triggerWobble,
      child: bubbleBody,
    );
  }
}

class _WaterBubblePainter extends CustomPainter {
  const _WaterBubblePainter({
    required this.progress,
    required this.wavePhase,
    required this.color,
    required this.waveAmplitude,
    required this.waveLengthFactor,
    required this.waveSpeed,
    required this.wobble,
  });

  final double progress;
  final double wavePhase;
  final Color color;
  final double waveAmplitude;
  final double waveLengthFactor;
  final double waveSpeed;
  final double wobble;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;
    final circle = Rect.fromCircle(center: center, radius: radius);

    final fillTop = size.height * (1 - progress);
    final waterRect = Rect.fromLTWH(0, fillTop, size.width, size.height - fillTop);

    // Transparent lens base (always visible, even above current water level).
    final lensBasePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.3),
        radius: 1.15,
        colors: [
          Colors.white.withValues(alpha: 0.18),
          color.withValues(alpha: 0.08),
          color.withValues(alpha: 0.02),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.75, 1.0],
      ).createShader(circle);
    canvas.drawOval(circle, lensBasePaint);

    final lensVerticalPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.1),
          Colors.transparent,
          color.withValues(alpha: 0.08),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(circle);
    canvas.drawOval(circle, lensVerticalPaint);

    if (waterRect.height > 0) {
      canvas.save();
      canvas.clipRect(waterRect);

      final wavelength = size.width * waveLengthFactor;
      final waveAmp = waveAmplitude * (1 + (0.5 * wobble));

      // Water layer with restrained transparency.
      final wavePath = Path()..moveTo(0, size.height);

      for (double x = 0; x <= size.width; x += 1) {
        final sine = math.sin((x / wavelength) * 2 * math.pi + wavePhase * waveSpeed);
        final y = fillTop + sine * waveAmp;
        wavePath.lineTo(x, y);
      }

      wavePath
        ..lineTo(size.width, size.height)
        ..close();

      final basePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.34),
          ],
        ).createShader(waterRect);
      canvas.drawPath(wavePath, basePaint);

      // Soft meniscus line around the moving surface.
      final meniscusPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.22),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, fillTop - 8, size.width, 16));

      final meniscusPath = Path()..moveTo(0, fillTop);
      for (double x = 0; x <= size.width; x += 1) {
        final sine = math.sin((x / wavelength) * 2 * math.pi + wavePhase * waveSpeed);
        final y = fillTop + sine * waveAmp;
        meniscusPath.lineTo(x, y);
      }
      meniscusPath
        ..lineTo(size.width, fillTop + 8)
        ..lineTo(0, fillTop + 8)
        ..close();
      canvas.drawPath(meniscusPath, meniscusPaint);

      // Subtle refractive tint inside the water region.
      final wetRefractionPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.6),
          radius: 1.2,
          colors: [
            Colors.white.withValues(alpha: 0.14),
            Colors.transparent,
          ],
        ).createShader(waterRect);
      canvas.drawRect(waterRect, wetRefractionPaint);

      canvas.restore();
    }

    // S-curve refraction bands (always visible, slightly displaced by wobble).
    final wobbleOffsetX = size.width * 0.045 * wobble;
    _drawRefractionBand(
      canvas,
      size,
      startYFactor: 0.25,
      endYFactor: 0.62,
      controlDelta: 0.18,
      strokeWidth: size.width * 0.07,
      color: Colors.white.withValues(alpha: 0.12),
      xOffset: wobbleOffsetX,
    );
    _drawRefractionBand(
      canvas,
      size,
      startYFactor: 0.38,
      endYFactor: 0.78,
      controlDelta: 0.14,
      strokeWidth: size.width * 0.055,
      color: color.withValues(alpha: 0.1),
      xOffset: -wobbleOffsetX * 0.6,
    );

    // Upper-left glossy highlight (elliptical, thin and bright).
    final highlightRect = Rect.fromCenter(
      center: Offset(size.width * 0.33, size.height * 0.28),
      width: size.width * 0.52,
      height: size.height * 0.32,
    );
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.28),
          const Color(0xFFBEEFFF).withValues(alpha: 0.18),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(highlightRect);
    canvas.drawOval(highlightRect, highlightPaint);

    // Lower-right inner shadow for thickness.
    final shadowRect = Rect.fromCenter(
      center: Offset(size.width * 0.68, size.height * 0.72),
      width: size.width * 0.95,
      height: size.height * 0.72,
    );
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.65, 0.7),
        radius: 0.92,
        colors: [
          color.withValues(alpha: 0.16),
          Colors.black.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(shadowRect);
    canvas.drawOval(shadowRect, shadowPaint);

    // Glass-like rim lights.
    final rimBrightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, radius * 0.03)
      ..shader = SweepGradient(
        startAngle: -math.pi,
        endAngle: math.pi,
        colors: [
          Colors.white.withValues(alpha: 0.5),
          Colors.white.withValues(alpha: 0.12),
          Colors.white.withValues(alpha: 0.45),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(circle);
    canvas.drawOval(circle.deflate(rimBrightPaint.strokeWidth * 0.5), rimBrightPaint);

    final rimDarkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, radius * 0.018)
      ..shader = SweepGradient(
        startAngle: -math.pi,
        endAngle: math.pi,
        colors: [
          color.withValues(alpha: 0.32),
          color.withValues(alpha: 0.12),
          color.withValues(alpha: 0.3),
        ],
      ).createShader(circle);
    canvas.drawOval(circle.deflate(rimBrightPaint.strokeWidth + 0.8), rimDarkPaint);
  }

  void _drawRefractionBand(
    Canvas canvas,
    Size size, {
    required double startYFactor,
    required double endYFactor,
    required double controlDelta,
    required double strokeWidth,
    required Color color,
    required double xOffset,
  }) {
    final path = Path()
      ..moveTo(size.width * 0.16 + xOffset, size.height * startYFactor)
      ..cubicTo(
        size.width * (0.36 + controlDelta) + xOffset,
        size.height * (startYFactor - 0.08),
        size.width * (0.55 - controlDelta) + xOffset,
        size.height * (startYFactor + 0.18),
        size.width * 0.74 + xOffset,
        size.height * (startYFactor + 0.2),
      )
      ..cubicTo(
        size.width * (0.66 - controlDelta) + xOffset,
        size.height * (endYFactor - 0.12),
        size.width * (0.34 + controlDelta) + xOffset,
        size.height * (endYFactor + 0.08),
        size.width * 0.2 + xOffset,
        size.height * endYFactor,
      );

    final refractionPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, refractionPaint);

    final crispPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth * 0.42
      ..color = color.withValues(alpha: color.opacity * 0.8);
    canvas.drawPath(path, crispPaint);
  }

  @override
  bool shouldRepaint(covariant _WaterBubblePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.color != color ||
        oldDelegate.waveAmplitude != waveAmplitude ||
        oldDelegate.waveLengthFactor != waveLengthFactor ||
        oldDelegate.waveSpeed != waveSpeed ||
        oldDelegate.wobble != wobble;
  }
}
