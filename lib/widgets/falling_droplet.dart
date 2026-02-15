import 'package:flutter/material.dart';

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
        final opacity = Tween<double>(begin: 1, end: 0.25).transform(t);

        return CustomPaint(
          painter: _FallingDropletPainter(
            current: current,
            opacity: opacity,
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
    required this.opacity,
    required this.size,
  });

  final Offset current;
  final double opacity;
  final double size;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final dropPaint = Paint()
      ..color = const Color(0xCC8ED8FF).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(current, size / 2, dropPaint);

    final debugPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(current, 6, debugPaint);
  }

  @override
  bool shouldRepaint(covariant _FallingDropletPainter oldDelegate) {
    return oldDelegate.current != current || oldDelegate.opacity != opacity || oldDelegate.size != size;
  }
}
