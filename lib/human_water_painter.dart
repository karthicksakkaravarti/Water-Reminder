import 'package:flutter/material.dart';
import 'dart:math' as math;

class HumanWaterPainter extends CustomPainter {
  final double percentage;

  HumanWaterPainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final Paint waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.blue[300]!, Colors.blue[600]!],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Draw human silhouette
    final Path humanPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.1) // Top of head
      ..lineTo(size.width * 0.4, size.height * 0.15) // Left side of head
      ..lineTo(size.width * 0.36, size.height * 0.2) // Left neck
      ..lineTo(size.width * 0.25, size.height * 0.32) // Left shoulder
      ..lineTo(size.width * 0.2, size.height * 0.55) // Left hand
      ..lineTo(size.width * 0.25, size.height * 0.55) // Left hand
      ..lineTo(size.width * 0.3, size.height * 0.4) // Left inner arm
      ..lineTo(size.width * 0.35, size.height * 0.55) // Left waist
      ..lineTo(size.width * 0.33, size.height * 0.8) // Left leg
      ..lineTo(size.width * 0.37, size.height * 0.98) // Left foot
      ..lineTo(size.width * 0.45, size.height * 0.98) // Between feet
      ..lineTo(size.width * 0.47, size.height * 0.8) // Inner left leg
      ..lineTo(size.width * 0.53, size.height * 0.8) // Inner right leg
      ..lineTo(size.width * 0.55, size.height * 0.98) // Right foot
      ..lineTo(size.width * 0.63, size.height * 0.98) // Right foot
      ..lineTo(size.width * 0.65, size.height * 0.8) // Right leg
      ..lineTo(size.width * 0.65, size.height * 0.55) // Right waist
      ..lineTo(size.width * 0.7, size.height * 0.4) // Right inner arm
      ..lineTo(size.width * 0.75, size.height * 0.55) // Right hand
      ..lineTo(size.width * 0.8, size.height * 0.55) // Right hand
      ..lineTo(size.width * 0.75, size.height * 0.32) // Right shoulder
      ..lineTo(size.width * 0.64, size.height * 0.2) // Right neck
      ..lineTo(size.width * 0.6, size.height * 0.15) // Right side of head
      ..close();

    canvas.drawPath(humanPath, outlinePaint);

    // Draw water fill
    final Path waterPath = Path()
      ..moveTo(size.width * 0.33, size.height)
      ..lineTo(size.width * 0.33, size.height * (1 - percentage))
      ..lineTo(size.width * 0.67, size.height * (1 - percentage))
      ..lineTo(size.width * 0.67, size.height)
      ..close();

    canvas.drawPath(waterPath, waterPaint);

    // Draw water surface with a slight wave
    final Path waterSurfacePath = Path()
      ..moveTo(size.width * 0.33, size.height * (1 - percentage))
      ..quadraticBezierTo(
          size.width * 0.5,
          size.height * (1 - percentage - 0.02),
          size.width * 0.67,
          size.height * (1 - percentage));

    canvas.drawPath(waterSurfacePath, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
