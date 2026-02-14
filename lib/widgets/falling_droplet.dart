import 'package:flutter/material.dart';

class FallingDroplet extends StatefulWidget {
  const FallingDroplet({
    super.key,
    required this.controller,
    required this.start,
    required this.end,
    required this.onSplash,
  });

  final AnimationController controller;
  final Offset start;
  final Offset end;
  final ValueChanged<Offset> onSplash;

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
    final t = widget.controller.value;
    if (t <= 0 || t >= 1) {
      return const SizedBox.shrink();
    }

    final eased = Curves.easeIn.transform(t);
    final dx = Tween<double>(begin: widget.start.dx, end: widget.end.dx).transform(eased);
    final dy = Tween<double>(begin: widget.start.dy, end: widget.end.dy).transform(eased);
    final opacity = Tween<double>(begin: 1, end: 0.25).transform(t);
    const dropletSize = 12.0;

    return Positioned(
      left: dx - dropletSize / 2,
      top: dy - dropletSize / 2,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: const Icon(Icons.water_drop_rounded, size: dropletSize, color: Color(0xCC8ED8FF)),
        ),
      ),
    );
  }
}
