import 'package:flutter/material.dart';

import '../theme/water_theme.dart';

class DropShotOverlay extends StatelessWidget {
  const DropShotOverlay({
    super.key,
    required this.controller,
    required this.start,
    required this.end,
  });

  final AnimationController controller;
  final Offset? start;
  final Offset? end;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final begin = start;
        final finish = end;
        final hidden = controller.value == 0 || controller.value == 1 || begin == null || finish == null;
        if (hidden) {
          return const SizedBox.shrink();
        }

        final t = Curves.easeIn.transform(controller.value);
        final position = Offset.lerp(begin, finish, t);
        if (position == null) {
          return const SizedBox.shrink();
        }

        const dropletSize = 16.0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: position.dx - (dropletSize / 2),
              top: position.dy - (dropletSize / 2),
              child: const _DropDot(size: dropletSize),
            ),
          ],
        );
      },
    );
  }
}

class _DropDot extends StatelessWidget {
  const _DropDot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size / 2;

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: WaterTheme.deepBlue.withValues(alpha: 0.98),
          border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            width: radius * 0.56,
            height: radius * 0.56,
            margin: EdgeInsets.only(left: radius * 0.22, top: radius * 0.22),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.68),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
