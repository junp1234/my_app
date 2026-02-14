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
    final effectiveScale = isPressed && scale > 0.97 ? 0.96 : scale;

    return GestureDetector(
      onTap: onTap,
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

  final bool isPressed;

  @override
  void paint(Canvas canvas, Size size) {
    final dropletPath = _buildDropletPath(size);

    canvas.drawShadow(
      dropletPath,
      const Color(0xFF2E8FC7).withValues(alpha: isPressed ? 0.18 : 0.28),
      isPressed ? 7 : 10,
      false,
    );

    canvas.save();
    canvas.clipPath(dropletPath);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFFEAF8FF),
          Color(0xFFC8EBFF),
          Color(0xFF8ED4F7),
        ],
        stops: const [0.0, 0.48, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawPath(dropletPath, fillPaint);

    final upperLiftPath = Path()
      ..moveTo(size.width * 0.31, size.height * 0.12)
      ..cubicTo(
        size.width * 0.20,
        size.height * 0.20,
        size.width * 0.17,
        size.height * 0.43,
        size.width * 0.28,
        size.height * 0.61,
      )
      ..cubicTo(
        size.width * 0.34,
        size.height * 0.66,
        size.width * 0.43,
        size.height * 0.63,
        size.width * 0.45,
        size.height * 0.55,
      )
      ..cubicTo(
        size.width * 0.33,
        size.height * 0.46,
        size.width * 0.30,
        size.height * 0.27,
        size.width * 0.39,
        size.height * 0.14,
      )
      ..close();
    final upperLiftPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.45),
          const Color(0xFFD9F3FF).withValues(alpha: 0.28),
        ],
      ).createShader(upperLiftPath.getBounds());
    canvas.drawPath(upperLiftPath, upperLiftPaint);

    final innerDepthPath = Path()
      ..moveTo(size.width * 0.60, size.height * 0.56)
      ..cubicTo(
        size.width * 0.74,
        size.height * 0.56,
        size.width * 0.84,
        size.height * 0.72,
        size.width * 0.78,
        size.height * 0.86,
      )
      ..cubicTo(
        size.width * 0.69,
        size.height * 0.95,
        size.width * 0.55,
        size.height * 0.92,
        size.width * 0.51,
        size.height * 0.82,
      )
      ..cubicTo(
        size.width * 0.58,
        size.height * 0.76,
        size.width * 0.62,
        size.height * 0.66,
        size.width * 0.60,
        size.height * 0.56,
      )
      ..close();
    final innerDepthPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          const Color(0xFF2E91C9).withValues(alpha: 0.17),
        ],
      ).createShader(innerDepthPath.getBounds());
    canvas.drawPath(innerDepthPath, innerDepthPaint);

    final mainHighlightPath = Path()
      ..moveTo(size.width * 0.34, size.height * 0.17)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.26,
        size.width * 0.23,
        size.height * 0.42,
        size.width * 0.30,
        size.height * 0.57,
      )
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.64,
        size.width * 0.43,
        size.height * 0.64,
        size.width * 0.47,
        size.height * 0.57,
      )
      ..cubicTo(
        size.width * 0.40,
        size.height * 0.48,
        size.width * 0.38,
        size.height * 0.30,
        size.width * 0.45,
        size.height * 0.20,
      )
      ..close();
    final mainHighlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.42),
          const Color(0xFFE8F8FF).withValues(alpha: 0.24),
          Colors.transparent,
        ],
        stops: const [0, 0.55, 1],
      ).createShader(mainHighlightPath.getBounds());
    canvas.drawPath(mainHighlightPath, mainHighlightPaint);

    final subHighlightPath = Path()
      ..moveTo(size.width * 0.63, size.height * 0.70)
      ..cubicTo(
        size.width * 0.70,
        size.height * 0.68,
        size.width * 0.75,
        size.height * 0.74,
        size.width * 0.71,
        size.height * 0.81,
      )
      ..cubicTo(
        size.width * 0.66,
        size.height * 0.85,
        size.width * 0.59,
        size.height * 0.82,
        size.width * 0.58,
        size.height * 0.75,
      )
      ..close();
    final subHighlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.30),
          const Color(0xFFE4F6FF).withValues(alpha: 0.16),
        ],
      ).createShader(subHighlightPath.getBounds());
    canvas.drawPath(subHighlightPath, subHighlightPaint);

    canvas.restore();

    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFFEAF8FF).withValues(alpha: 0.72);
    canvas.drawPath(dropletPath, outlinePaint);
  }

  Path _buildDropletPath(Size size) {
    final centerX = size.width * 0.5;
    final topY = size.height * 0.04;

    return Path()
      ..moveTo(centerX, topY)
      ..cubicTo(
        size.width * 0.34,
        size.height * 0.09,
        size.width * 0.20,
        size.height * 0.28,
        size.width * 0.18,
        size.height * 0.50,
      )
      ..cubicTo(
        size.width * 0.16,
        size.height * 0.73,
        size.width * 0.30,
        size.height * 0.93,
        centerX,
        size.height,
      )
      ..cubicTo(
        size.width * 0.70,
        size.height * 0.93,
        size.width * 0.84,
        size.height * 0.73,
        size.width * 0.82,
        size.height * 0.50,
      )
      ..cubicTo(
        size.width * 0.80,
        size.height * 0.28,
        size.width * 0.66,
        size.height * 0.09,
        centerX,
        topY,
      )
      ..close();
  }

  @override
  bool shouldRepaint(covariant _DropletPainter oldDelegate) => oldDelegate.isPressed != isPressed;
}
