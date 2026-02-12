import 'dart:math';

import 'package:flutter/material.dart';

import 'water_sphere.dart';

class GlassWidget extends StatelessWidget {
  const GlassWidget({
    super.key,
    required this.progress,
    required this.ripple,
    required this.activeDots,
    required this.wobble,
    this.size = 260,
  });

  final double progress;
  final double ripple;
  final int activeDots;
  final double wobble;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ringRadius = size * 0.38;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          WaterSphere(size: size, progress: progress, ripple: ripple, wobble: wobble),
          ...List.generate(14, (i) {
            final angle = -pi / 2 + i * (2 * pi / 14);
            final offset = Offset(cos(angle), sin(angle)) * (ringRadius + 22);
            return Transform.translate(
              offset: offset,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < activeDots ? const Color(0x99A8D8FF) : const Color(0x336B7280),
                ),
                child: const SizedBox(width: 8.4, height: 8.4),
              ),
            );
          }),
        ],
      ),
    );
  }
}
