import 'package:flutter/material.dart';

class FallingDroplet extends StatefulWidget {
  const FallingDroplet({
    super.key,
    required this.controller,
    required this.onSplash,
  });

  final AnimationController controller;
  final VoidCallback onSplash;

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
      widget.onSplash();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.controller.value;
    if (t <= 0 || t >= 1) {
      return const SizedBox.shrink();
    }

    final y = Tween<double>(begin: -110, end: 88).transform(Curves.easeIn.transform(t));
    final opacity = Tween<double>(begin: 1, end: 0.25).transform(t);

    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -0.78),
        child: Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, y),
            child: const Icon(Icons.water_drop_rounded, size: 38, color: Color(0xAA71CFFF)),
          ),
        ),
      ),
    );
  }
}
