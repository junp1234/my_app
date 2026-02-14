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

  final bool isPressed;

  @override
  void paint(Canvas canvas, Size size) {
    final dropletPath = _buildDropletPath(size);
    final highlightStrength = isPressed ? 0.82 : 1.0;

    canvas.drawShadow(
      dropletPath,
      const Color(0xFF4B81AA).withValues(alpha: isPressed ? 0.12 : 0.18),
      isPressed ? 8 : 10,
      true,
    );

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
        center: const Alignment(-0.34, -0.42),
        radius: 1.02,
        colors: [
          Colors.white.withValues(alpha: 0.16 * highlightStrength),
          const Color(0xFF3A9CD9).withValues(alpha: 0.12),
          const Color(0xFF1E76B5).withValues(alpha: 0.16),
        ],
        stops: const [0.0, 0.64, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, depthPaint);

    final mainHighlightPath = Path()
      ..moveTo(size.width * 0.40, size.height * 0.14)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.27,
        size.width * 0.23,
        size.height * 0.50,
        size.width * 0.31,
        size.height * 0.67,
      )
      ..cubicTo(
        size.width * 0.36,
        size.height * 0.73,
        size.width * 0.44,
        size.height * 0.72,
        size.width * 0.49,
        size.height * 0.64,
      )
      ..cubicTo(
        size.width * 0.40,
        size.height * 0.52,
        size.width * 0.37,
        size.height * 0.30,
        size.width * 0.46,
        size.height * 0.18,
      )
      ..close();
    final mainHighlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.25 * highlightStrength),
          const Color(0xFFDBF4FF).withValues(alpha: 0.18 * highlightStrength),
          Colors.transparent,
        ],
        stops: const [0.0, 0.58, 1.0],
      ).createShader(mainHighlightPath.getBounds());
    canvas.drawPath(mainHighlightPath, mainHighlightPaint);

    final subHighlightPath = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.66, size.height * 0.77),
          width: size.width * 0.22,
          height: size.height * 0.12,
        ),
      );
    final subHighlightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.1, -0.1),
        radius: 0.8,
        colors: [
          Colors.white.withValues(alpha: 0.16 * highlightStrength),
          const Color(0xFFD8F3FF).withValues(alpha: 0.10 * highlightStrength),
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
    final centerX = size.width * 0.5;

    return Path()
      ..moveTo(centerX, size.height * 0.06)
      ..cubicTo(
        size.width * 0.39,
        size.height * 0.10,
        size.width * 0.22,
        size.height * 0.30,
        size.width * 0.20,
        size.height * 0.52,
      )
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.77,
        size.width * 0.34,
        size.height * 0.96,
        centerX,
        size.height,
      )
      ..cubicTo(
        size.width * 0.66,
        size.height * 0.96,
        size.width * 0.82,
        size.height * 0.77,
        size.width * 0.80,
        size.height * 0.52,
      )
      ..cubicTo(
        size.width * 0.78,
        size.height * 0.30,
        size.width * 0.61,
        size.height * 0.10,
        centerX,
        size.height * 0.06,
      )
      ..close();
  }

  @override
  bool shouldRepaint(covariant _DropletPainter oldDelegate) => oldDelegate.isPressed != isPressed;
}
