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

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      onLongPressStart: onLongPressStart,
      onLongPressEnd: onLongPressEnd,
      child: Transform.scale(
        scale: effectiveScale,
        child: SizedBox(
          width: 92,
          height: 108,
          child: CustomPaint(
            painter: _DropletPainter(isPressed: isPressed),
          ),
        ),
      ),
    );
  }
}

class _DropletPainter extends CustomPainter {
  const _DropletPainter({required this.isPressed});

  static bool _hasLoggedPathUpdate = false;

  final bool isPressed;

  @override
  void paint(Canvas canvas, Size size) {
    final dropletPath = _buildDropletPath(size);
    final highlightStrength = isPressed ? 0.82 : 1.0;

    final shadowRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.95),
      width: size.width * 0.52,
      height: size.height * 0.12,
    );
    final shadowPaint = Paint()
      ..color = const Color(0xFF1B4D73).withValues(alpha: isPressed ? 0.10 : 0.13)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13);
    canvas.drawOval(shadowRect, shadowPaint);

    canvas.save();
    canvas.clipPath(dropletPath);

    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFFF4FBFF),
          Color(0xFF8EDDFF),
          Color(0xFF2E92D8),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, basePaint);

    final depthPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.30, -0.40),
        radius: 1.02,
        colors: [
          Colors.white.withValues(alpha: 0.14 * highlightStrength),
          const Color(0xFF3A9CD9).withValues(alpha: 0.10),
          const Color(0xFF1E76B5).withValues(alpha: 0.15),
        ],
        stops: const [0.0, 0.64, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, depthPaint);

    final mainHighlightRect = Rect.fromLTWH(
      size.width * 0.27,
      size.height * 0.20,
      size.width * 0.16,
      size.height * 0.46,
    );
    final mainHighlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.22 * highlightStrength),
          const Color(0xFFE8F8FF).withValues(alpha: 0.16 * highlightStrength),
          Colors.transparent,
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(mainHighlightRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(mainHighlightRect, Radius.circular(size.width * 0.10)),
      mainHighlightPaint,
    );

    final subHighlightPath = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.67, size.height * 0.76),
          width: size.width * 0.14,
          height: size.width * 0.14,
        ),
      );
    final subHighlightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.1, -0.1),
        radius: 0.8,
        colors: [
          Colors.white.withValues(alpha: 0.20 * highlightStrength),
          const Color(0xFFD8F3FF).withValues(alpha: 0.11 * highlightStrength),
          Colors.transparent,
        ],
        stops: const [0.0, 0.72, 1.0],
      ).createShader(subHighlightPath.getBounds());
    canvas.drawPath(subHighlightPath, subHighlightPaint);

    canvas.restore();

    final outerOutlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFFDDF4FF).withValues(alpha: 0.50);
    canvas.drawPath(dropletPath, outerOutlinePaint);

    final innerOutlinePath = _buildDropletPath(size).shift(const Offset(0, 0.8));
    final innerOutlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.24);
    canvas.drawPath(innerOutlinePath, innerOutlinePaint);
  }

  Path _buildDropletPath(Size size) {
    if (!_hasLoggedPathUpdate) {
      _hasLoggedPathUpdate = true;
      debugPrint('DROPLET: path updated');
    }

    final centerX = size.width * 0.5;
    final bottomY = size.height * 0.91;
    final bottomRadius = Radius.elliptical(size.width * 0.23, size.height * 0.12);

    return Path()
      ..moveTo(centerX, size.height * 0.07)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.10,
        size.width * 0.16,
        size.height * 0.31,
        size.width * 0.19,
        size.height * 0.56,
      )
      ..cubicTo(
        size.width * 0.23,
        size.height * 0.78,
        size.width * 0.33,
        size.height * 0.90,
        size.width * 0.43,
        bottomY,
      )
      ..arcToPoint(
        Offset(size.width * 0.56, bottomY),
        radius: bottomRadius,
        clockwise: false,
      )
      ..cubicTo(
        size.width * 0.67,
        size.height * 0.90,
        size.width * 0.77,
        size.height * 0.78,
        size.width * 0.81,
        size.height * 0.56,
      )
      ..cubicTo(
        size.width * 0.84,
        size.height * 0.31,
        size.width * 0.65,
        size.height * 0.10,
        centerX,
        size.height * 0.07,
      )
      ..close();
  }

  @override
  bool shouldRepaint(covariant _DropletPainter oldDelegate) => oldDelegate.isPressed != isPressed;
}
