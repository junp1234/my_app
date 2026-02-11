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
    this.waveAmplitude = 8,
    this.waveLengthFactor = 1.4,
    this.waveSpeed = 1,
    this.onTap,
  });

  final double progress;
  final Color color;
  final double waveAmplitude;
  final double waveLengthFactor;
  final double waveSpeed;
  final VoidCallback? onTap;

  @override
  State<WaterBubbleFill> createState() => _WaterBubbleFillState();
}

class _WaterBubbleFillState extends State<WaterBubbleFill>
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

  Future<void> _handleTap() async {
    widget.onTap?.call();
    await _jellyController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final clampedProgress = widget.progress.clamp(0.0, 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_waveController, _jellyAnimation]),
        builder: (context, child) {
          final wobbleValue = _jellyAnimation.value;
          final scaleX = 1 + 0.04 * math.sin(wobbleValue * math.pi * 2);
          final scaleY = 1 - 0.03 * math.sin(wobbleValue * math.pi * 2);

          return Transform.scale(
            scaleX: scaleX,
            scaleY: scaleY,
            child: CustomPaint(
              painter: _WaterBubblePainter(
                progress: clampedProgress,
                wavePhase: _waveController.value * 2 * math.pi,
                color: widget.color,
                waveAmplitude: widget.waveAmplitude,
                waveLengthFactor: widget.waveLengthFactor,
                waveSpeed: widget.waveSpeed,
              ),
            ),
          );
        },
      ),
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
  });

  final double progress;
  final double wavePhase;
  final Color color;
  final double waveAmplitude;
  final double waveLengthFactor;
  final double waveSpeed;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;
    final circle = Rect.fromCircle(center: center, radius: radius);

    canvas.save();
    canvas.clipPath(Path()..addOval(circle));

    final fillTop = size.height * (1 - progress);

    // Main water body with a gentle animated surface wave.
    final wavePath = Path()..moveTo(0, size.height);
    final wavelength = size.width * waveLengthFactor;

    for (double x = 0; x <= size.width; x += 1) {
      final sine = math.sin((x / wavelength) * 2 * math.pi + wavePhase * waveSpeed);
      final y = fillTop + sine * waveAmplitude;
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
          color.withValues(alpha: 0.8),
          color.withValues(alpha: 0.95),
        ],
      ).createShader(Rect.fromLTWH(0, fillTop, size.width, size.height - fillTop));

    canvas.drawPath(wavePath, basePaint);

    // Surface gloss to make the meniscus area look softer.
    final meniscusPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.4),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, fillTop - 10, size.width, 20));

    final meniscusPath = Path()..moveTo(0, fillTop);
    for (double x = 0; x <= size.width; x += 1) {
      final sine = math.sin((x / wavelength) * 2 * math.pi + wavePhase * waveSpeed);
      final y = fillTop + sine * waveAmplitude;
      meniscusPath.lineTo(x, y);
    }
    meniscusPath
      ..lineTo(size.width, fillTop + 8)
      ..lineTo(0, fillTop + 8)
      ..close();
    canvas.drawPath(meniscusPath, meniscusPaint);

    // Upper-left highlight for glossy bubble look.
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.45, -0.45),
        radius: 0.55,
        colors: [
          Colors.white.withValues(alpha: 0.45),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(circle);
    canvas.drawOval(circle, highlightPaint);

    // Lower-right shadow to create depth.
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.65, 0.65),
        radius: 0.8,
        colors: [
          Colors.black.withValues(alpha: 0.2),
          Colors.black.withValues(alpha: 0.0),
        ],
      ).createShader(circle);
    canvas.drawOval(circle, shadowPaint);

    // Subtle refraction layer over water region only.
    final refractionRect = Rect.fromLTWH(0, fillTop, size.width, size.height - fillTop);
    final refractionPaint = Paint()
      ..blendMode = BlendMode.screen
      ..shader = RadialGradient(
        center: const Alignment(-0.1, -0.2),
        radius: 1.0,
        colors: [
          Colors.white.withValues(alpha: 0.18),
          Colors.transparent,
        ],
      ).createShader(refractionRect);
    canvas.drawRect(refractionRect, refractionPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WaterBubblePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.color != color ||
        oldDelegate.waveAmplitude != waveAmplitude ||
        oldDelegate.waveLengthFactor != waveLengthFactor ||
        oldDelegate.waveSpeed != waveSpeed;
  }
}
