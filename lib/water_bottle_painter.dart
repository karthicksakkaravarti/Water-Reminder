import 'package:flutter/material.dart';
import 'dart:math' as math;

class WaterBottlePainter extends CustomPainter {
  final double percentage;

  WaterBottlePainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final double bottleWidth = size.width * 0.6;
    final double bottleHeight = size.height * 0.8;
    final double bottleTop = size.height * 0.1;
    final double bottleBottom = bottleTop + bottleHeight;

    final Paint bottlePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final Paint waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.blue[300]!, Colors.blue[600]!],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Draw bottle
    final Path bottlePath = Path()
      ..moveTo(size.width * 0.5 - bottleWidth / 2, bottleBottom)
      ..lineTo(
          size.width * 0.5 - bottleWidth / 2, bottleTop + bottleHeight * 0.1)
      ..quadraticBezierTo(size.width * 0.5 - bottleWidth / 2, bottleTop,
          size.width * 0.5 - bottleWidth / 4, bottleTop)
      ..lineTo(size.width * 0.5 + bottleWidth / 4, bottleTop)
      ..quadraticBezierTo(size.width * 0.5 + bottleWidth / 2, bottleTop,
          size.width * 0.5 + bottleWidth / 2, bottleTop + bottleHeight * 0.1)
      ..lineTo(size.width * 0.5 + bottleWidth / 2, bottleBottom)
      ..close();

    canvas.drawPath(bottlePath, bottlePaint);

    // Draw water
    final waterHeight = math.min(percentage, 1.0) * bottleHeight;
    final waterTop = bottleBottom - waterHeight;

    final Path waterPath = Path()
      ..moveTo(size.width * 0.5 - bottleWidth / 2, bottleBottom)
      ..lineTo(size.width * 0.5 - bottleWidth / 2, waterTop)
      ..quadraticBezierTo(size.width * 0.5, waterTop - 10,
          size.width * 0.5 + bottleWidth / 2, waterTop)
      ..lineTo(size.width * 0.5 + bottleWidth / 2, bottleBottom)
      ..close();

    canvas.drawPath(waterPath, waterPaint);

    // Draw water surface
    final waterSurfacePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawLine(
        Offset(size.width * 0.5 - bottleWidth / 2, waterTop),
        Offset(size.width * 0.5 + bottleWidth / 2, waterTop),
        waterSurfacePaint);

    // Draw percentage text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${(percentage * 100).toInt()}%',
        style: TextStyle(
            color: Colors.white,
            fontSize: size.width * 0.1,
            fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas,
        Offset(size.width / 2 - textPainter.width / 2, bottleBottom + 10));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
