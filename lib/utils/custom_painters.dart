import 'package:flutter/material.dart';

class CurvedBottomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    var path = Path();

    // Start at the bottom-left
    path.moveTo(0, size.height);

    // Draw a curved path to the bottom-right
    path.quadraticBezierTo(
      size.width / 2, size.height * 0.4,  // Control point
      size.width, size.height,             // End point
    );

    // Close the path by drawing to the top-right, then top-left, then back to start
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}