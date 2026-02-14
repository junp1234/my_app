import 'package:flutter/material.dart';

import 'painters/glass_water_palette.dart';

class FullOverlay extends StatelessWidget {
  const FullOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final tint = GlassWaterPalette.fullBackgroundTint(amount: 0.24);

    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      tint.withValues(alpha: 0.06),
                      tint.withValues(alpha: 0.10),
                      tint.withValues(alpha: 0.08),
                    ],
                    stops: const [0.0, 0.56, 1.0],
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, 0.08),
                      radius: 0.55,
                      colors: [
                        GlassWaterPalette.base.withValues(alpha: 0.10),
                        GlassWaterPalette.mid.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.52, 1.0],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: const Alignment(0, 0.12),
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
