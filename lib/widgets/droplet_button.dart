import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DropletButton extends StatelessWidget {
  const DropletButton({
    super.key,
    required this.scale,
    required this.isPressed,
    required this.onTap,
    this.onLongPressStart,
    this.onLongPressEnd,
  });

  final double scale;
  final bool isPressed;
  final VoidCallback onTap;
  final GestureLongPressStartCallback? onLongPressStart;
  final GestureLongPressEndCallback? onLongPressEnd;

  static const double _dropletSize = 84;

  @override
  Widget build(BuildContext context) {
    final effectiveScale = isPressed ? 0.96 : scale;

    return Transform.scale(
      scale: effectiveScale,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onLongPressStart: onLongPressStart,
          onLongPressEnd: onLongPressEnd,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                'assets/images/water.png',
                width: _dropletSize,
                height: _dropletSize,
                fit: BoxFit.contain,
                semanticLabel: 'Add water',
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.water_drop,
                  size: _dropletSize,
                  color: Colors.lightBlue,
                  semanticLabel: 'Add water',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
