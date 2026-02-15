import 'package:flutter/material.dart';

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
        debugPrint('DROP t=${controller.value}');

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

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: position.dx - 6,
              top: position.dy - 6,
              child: const _DropDot(),
            ),
          ],
        );
      },
    );
  }
}

class _DropDot extends StatelessWidget {
  const _DropDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: const BoxDecoration(
        color: Color(0xD6E8F7FF),
        shape: BoxShape.circle,
      ),
    );
  }
}
