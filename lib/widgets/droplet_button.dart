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

  @override
  Widget build(BuildContext context) {
    final effectiveScale = isPressed ? 0.96 : scale;

    return Transform.scale(
      scale: effectiveScale,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          onLongPressStart: onLongPressStart,
          onLongPressEnd: onLongPressEnd,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              'assets/images/water.png',
              width: 56,
              height: 56,
              fit: BoxFit.contain,
              semanticLabel: 'Add water',
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.water_drop,
                size: 56,
                color: Colors.lightBlue,
                semanticLabel: 'Add water',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
