import 'package:flutter/material.dart';
import 'dart:math' as math;

class WatermarkOverlay extends StatelessWidget {
  final List<String> watermarks;
  final double opacity;
  final double angle;

  const WatermarkOverlay({
    Key? key,
    this.watermarks = const ['Vivah4Ever', 'Kerala Matrimony'],
    this.opacity = 0.15,
    this.angle = -math.pi / 4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: CustomPaint(
          size: Size.infinite,
          painter: _WatermarkPainter(
            watermarks: watermarks,
            opacity: opacity,
            angle: angle,
          ),
        ),
      ),
    );
  }
}

class _WatermarkPainter extends CustomPainter {
  final List<String> watermarks;
  final double opacity;
  final double angle;

  _WatermarkPainter({
    required this.watermarks,
    required this.opacity,
    required this.angle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textStyle = TextStyle(
      color: Colors.grey.shade700.withOpacity(0.4), // Darker grey with higher opacity
      fontSize: 18,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          blurRadius: 2,
          color: Colors.black.withOpacity(0.1),
          offset: const Offset(1, 1),
        ),
      ],
    );

    // Positions for the 4 watermarks (roughly 4 quadrants)
    final List<Offset> positions = [
      Offset(size.width * 0.2, size.height * 0.25), // Top Left area
      Offset(size.width * 0.7, size.height * 0.35), // Top Right area
      Offset(size.width * 0.25, size.height * 0.75), // Bottom Left area
      Offset(size.width * 0.75, size.height * 0.65), // Bottom Right area
    ];

    for (int i = 0; i < positions.length; i++) {
      final text = watermarks[i % watermarks.length];
      final textPainter = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      canvas.save();
      // Move to position and rotate individual instance
      canvas.translate(positions[i].dx, positions[i].dy);
      canvas.rotate(angle);
      
      // Center the text on the position
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
