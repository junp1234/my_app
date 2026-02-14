import 'package:flutter/material.dart';

import '../theme/water_theme.dart';
import 'sparkle_overlay.dart';

class CompletedOverlay extends StatelessWidget {
  const CompletedOverlay({
    super.key,
    required this.progress,
    required this.backgroundStrength,
  });

  final double progress;
  final double backgroundStrength;

  @override
  Widget build(BuildContext context) {
    final bgIn = Curves.easeOut.transform((backgroundStrength / 0.25).clamp(0.0, 1.0));
    final bgOut = 1 - Curves.easeIn.transform(((backgroundStrength - 0.55) / 0.45).clamp(0.0, 1.0));
    final bgOpacity = (bgIn * bgOut * 0.52).clamp(0.0, 1.0);

    final sparklePhase = ((progress - 0.1) / 0.5).clamp(0.0, 1.0);

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Opacity(
              opacity: bgOpacity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, 0.2),
                    radius: 1.05,
                    colors: [
                      WaterTheme.primaryWater.withValues(alpha: 0.92),
                      WaterTheme.deepWater.withValues(alpha: 0.72),
                      WaterTheme.deepWater.withValues(alpha: 0.22),
                    ],
                    stops: const [0.0, 0.62, 1.0],
                  ),
                ),
              ),
            ),
            SparkleOverlay(progress: sparklePhase),
          ],
        ),
      ),
    );
  }
}
