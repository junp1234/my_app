import 'package:flutter/material.dart';

import '../theme/water_theme.dart';

class FallingDroplet extends StatefulWidget {
  const FallingDroplet({
    super.key,
    required this.controller,
    required this.start,
    required this.end,
    required this.onSplash,
    this.size = 12,
  });

  final AnimationController controller;
  final Offset start;
  final Offset end;
  final ValueChanged<Offset> onSplash;
  final double size;

  @override
  State<FallingDroplet> createState() => _FallingDropletState();
}

class _FallingDropletState extends State<FallingDroplet> {
  @override
  void initState() {
    super.initState();
    widget.controller.addStatusListener(_onStatusChanged);
  }

  @override
  void didUpdateWidget(covariant FallingDroplet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeStatusListener(_onStatusChanged);
      widget.controller.addStatusListener(_onStatusChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeStatusListener(_onStatusChanged);
    super.dispose();
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onSplash(widget.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (_, __) {
        final t = widget.controller.value;
        if (t <= 0 || t >= 1) {
          return const SizedBox.shrink();
        }

        final eased = Curves.easeIn.transform(t);
        final current = Offset(
          Tween<double>(begin: widget.start.dx, end: widget.end.dx).transform(eased),
          Tween<double>(begin: widget.start.dy, end: widget.end.dy).transform(eased),
        );
        return CustomPaint(
          painter: _FallingDropletPainter(
            current: current,
            size: widget.size,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _FallingDropletPainter extends CustomPainter {
  const _FallingDropletPainter({
    required this.current,
    required this.size,
  });

  final Offset current;
  final double size;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final w = size;
    final h = size * 1.25;
    final cx = current.dx;
    final cy = current.dy;

    final dropPath = Path()
      ..moveTo(cx, cy - h * 0.55)
      ..cubicTo(
        cx + w * 0.45,
        cy - h * 0.35,
        cx + w * 0.55,
        cy + h * 0.10,
        cx,
        cy + h * 0.55,
      )
      ..cubicTo(
        cx - w * 0.55,
        cy + h * 0.10,
        cx - w * 0.45,
        cy - h * 0.35,
        cx,
        cy - h * 0.55,
      )
      ..close();

    canvas.drawShadow(dropPath, Colors.black.withValues(alpha: 0.12), 3, false);

    final fillPaint = Paint()
      ..color = WaterTheme.deepBlue.withValues(alpha: 0.90)
      ..style = PaintingStyle.fill;
    canvas.drawPath(dropPath, fillPaint);

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromLTWH(
        cx - w * 0.28,
        cy - h * 0.35,
        w * 0.24,
        h * 0.42,
      ),
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FallingDropletPainter oldDelegate) {
    return oldDelegate.current != current || oldDelegate.size != size;
  }
}
