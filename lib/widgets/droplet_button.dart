import 'package:flutter/material.dart';

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
    return GestureDetector(
      onTap: onTap,
      onLongPressStart: onLongPressStart,
      onLongPressEnd: onLongPressEnd,
      child: Transform.scale(
        scale: scale,
        child: SizedBox(
          width: 92,
          height: 108,
          child: ClipPath(
            clipper: DropletClipper(),
            child: Container(
              width: 80,
              height: 98,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.95),
                    const Color(0xB8C9EEFF),
                    const Color(0xCC7ECEFA),
                    const Color(0xFF56B7ED),
                  ],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x3320A2E6),
                    blurRadius: isPressed ? 14 : 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 17,
                    top: 17,
                    child: Container(
                      width: 24,
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: RadialGradient(
                          colors: [Colors.white.withValues(alpha: 0.75), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 14,
                    bottom: 18,
                    child: Container(
                      width: 16,
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DropletClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.cubicTo(size.width * 0.12, size.height * 0.26, size.width * 0.04, size.height * 0.56, size.width * 0.2, size.height * 0.8);
    path.cubicTo(size.width * 0.33, size.height * 0.98, size.width * 0.43, size.height, size.width * 0.5, size.height);
    path.cubicTo(size.width * 0.57, size.height, size.width * 0.67, size.height * 0.98, size.width * 0.8, size.height * 0.8);
    path.cubicTo(size.width * 0.96, size.height * 0.56, size.width * 0.88, size.height * 0.26, size.width * 0.5, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
