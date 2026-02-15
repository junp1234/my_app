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

        final t = Curves.easeInOutCubic.transform(controller.value);
        final position = Offset.lerp(begin, finish, t);
        if (position == null) {
          return const SizedBox.shrink();
        }

        const dropletSize = 12.0;
        const dropletHeightMultiplier = 1.30;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: position.dx - (dropletSize / 2),
              top: position.dy - ((dropletSize * dropletHeightMultiplier) / 2),
              child: const _DropTear(size: dropletSize),
            ),
          ],
        );
      },
    );
  }
}

class _DropTear extends StatelessWidget {
  const _DropTear({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.30,
      child: CustomPaint(
        painter: _DropTearPainter(size: size),
      ),
    );
  }
}

class _DropTearPainter extends CustomPainter {
  const _DropTearPainter({required this.size});

  final double size;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final w = size;
    final h = size * 1.30;
    final cx = canvasSize.width / 2;
    final cy = canvasSize.height / 2;
    final top = Offset(cx, cy - h * 0.58);
    final bottom = Offset(cx, cy + h * 0.52);

    final path = Path()
      ..moveTo(top.dx, top.dy)
      ..cubicTo(
        cx + w * 0.55,
        cy - h * 0.40,
        cx + w * 0.62,
        cy + h * 0.10,
        bottom.dx,
        bottom.dy,
      )
      ..cubicTo(
        cx - w * 0.62,
        cy + h * 0.10,
        cx - w * 0.55,
        cy - h * 0.40,
        top.dx,
        top.dy,
      )
      ..close();

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.12), 3, false);

    final fillPaint = Paint()
      ..color = WaterTheme.deepBlue.withValues(alpha: 0.90)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromLTWH(
        cx - w * 0.26,
        cy - h * 0.34,
        w * 0.20,
        h * 0.36,
      ),
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DropTearPainter oldDelegate) {
    return oldDelegate.size != size;
  }
}
