import 'package:flutter/material.dart';

class FallingDroplet extends StatelessWidget {
  const FallingDroplet({super.key, required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
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
