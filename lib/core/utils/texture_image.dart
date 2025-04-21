import 'dart:math';
import 'package:flutter/material.dart';

/// A widget that generates a subtle noise texture at runtime
class TextureWidget extends StatelessWidget {
  final double opacity;

  const TextureWidget({super.key, this.opacity = 0.05});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: TexturePainter(),
          isComplex: true,
          willChange: false,
          size: const Size(300, 300),
        ),
      ),
    );
  }
}

class TexturePainter extends CustomPainter {
  final Random random = Random(42); // Fixed seed for consistent results

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    // Create subtle noise pattern
    final int pointCount = (size.width * size.height * 0.02).round();

    for (int i = 0; i < pointCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final pointSize = random.nextDouble() * 1.0;

      paint.color = Colors.white.withOpacity(random.nextDouble() * 0.1);
      canvas.drawCircle(Offset(x, y), pointSize, paint);
    }

    // Add some larger subtle dust particles
    final int dustCount = (size.width * size.height * 0.0001).round();
    for (int i = 0; i < dustCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final dustSize = 0.5 + random.nextDouble() * 2.0;

      paint.color = Colors.white.withOpacity(random.nextDouble() * 0.08);
      canvas.drawCircle(Offset(x, y), dustSize, paint);
    }

    // Add very subtle directional lines
    final int lineCount = (size.width * 0.05).round();
    for (int i = 0; i < lineCount; i++) {
      final x = random.nextDouble() * size.width;
      final startY = 0.0;
      final endY = size.height;

      final linePaint =
          Paint()
            ..color = Colors.white.withOpacity(random.nextDouble() * 0.03)
            ..strokeWidth = 0.5;

      canvas.drawLine(Offset(x, startY), Offset(x, endY), linePaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
