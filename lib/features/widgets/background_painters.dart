import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// Background painter classes
class GeometricBackgroundPainter extends CustomPainter {
  final Color color;

  GeometricBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color.withValues(alpha: 0.15)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

    final random = Random(42); // Fixed seed for consistent pattern

    // Draw some triangles and circles
    for (int i = 0; i < 15; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 10 + random.nextDouble() * 30;

      if (i % 2 == 0) {
        // Draw triangles
        final path = Path();
        path.moveTo(x, y - radius);
        path.lineTo(x + radius, y + radius);
        path.lineTo(x - radius, y + radius);
        path.close();
        canvas.drawPath(path, paint);
      } else {
        // Draw circles
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class CosmicBackgroundPainter extends CustomPainter {
  final Color starColor;

  CosmicBackgroundPainter({required this.starColor});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(100); // Fixed seed for consistent stars

    // Draw stars
    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 0.5 + random.nextDouble() * 1.5;
      final opacity = 0.3 + random.nextDouble() * 0.7;

      final paint =
          Paint()
            ..color = starColor.withValues(alpha: opacity)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw a few larger glowing stars
    for (int i = 0; i < 5; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 1.5 + random.nextDouble() * 2.0;

      final paint =
          Paint()
            ..color = starColor.withValues(alpha: 0.8)
            ..style = PaintingStyle.fill;

      // Inner glow
      final glowPaint =
          Paint()
            ..color = starColor.withValues(alpha: 0.2)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), radius * 3, glowPaint);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class NeuralBackgroundPainter extends CustomPainter {
  final Color lineColor;

  NeuralBackgroundPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(25); // Fixed seed for consistency
    final paint =
        Paint()
          ..color = lineColor.withValues(alpha: 0.2)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke;

    final nodePaint =
        Paint()
          ..color = lineColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;

    // Create a network of nodes and connections
    final nodes = <Offset>[];

    // Generate node positions
    for (int i = 0; i < 12; i++) {
      nodes.add(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
      );
    }

    // Draw connections between some nodes
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        if (random.nextDouble() < 0.3) {
          canvas.drawLine(nodes[i], nodes[j], paint);
        }
      }
    }

    // Draw nodes
    for (final node in nodes) {
      canvas.drawCircle(node, 2.5, nodePaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class WaveBackgroundPainter extends CustomPainter {
  final Color waveColor;

  WaveBackgroundPainter({required this.waveColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = waveColor.withValues(alpha: 0.2)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    // Draw several wave patterns
    for (int w = 0; w < 5; w++) {
      final path = Path();
      final amplitude = 5.0 + (w * 3);
      final frequency = 0.02 + (w * 0.005);
      final verticalShift = (w * 30) + (size.height * 0.2);

      path.moveTo(0, size.height / 2);

      for (double x = 0; x <= size.width; x += 1) {
        double y = sin(x * frequency) * amplitude + verticalShift;
        path.lineTo(x, y);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class DigitalBackgroundPainter extends CustomPainter {
  final Color lineColor;

  DigitalBackgroundPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = lineColor.withValues(alpha: 0.25)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

    final random = Random(55);

    // Draw digital circuit-like patterns
    for (int i = 0; i < 8; i++) {
      final startX = random.nextDouble() * size.width * 0.2;
      final startY = (i * size.height / 8) + random.nextDouble() * 20;

      final path = Path();
      path.moveTo(startX, startY);

      double currentX = startX;
      double currentY = startY;

      // Create a path with horizontal and vertical lines only
      for (int j = 0; j < 5; j++) {
        // Horizontal line
        final horizontalLength = 20 + random.nextDouble() * (size.width / 3);
        currentX += horizontalLength;
        path.lineTo(currentX, currentY);

        // Sometimes add a vertical segment
        if (random.nextDouble() > 0.3) {
          final verticalLength = (random.nextDouble() - 0.5) * 40;
          currentY += verticalLength;
          path.lineTo(currentX, currentY);
        }
      }

      canvas.drawPath(path, paint);

      // Add some circuit nodes/connection points
      final nodePaint =
          Paint()
            ..color = lineColor.withValues(alpha: 0.4)
            ..style = PaintingStyle.fill;

      currentX = startX;
      currentY = startY;
      canvas.drawCircle(Offset(currentX, currentY), 2, nodePaint);

      for (int j = 0; j < 3; j++) {
        currentX += 40 + random.nextDouble() * 60;
        canvas.drawCircle(Offset(currentX, currentY), 2, nodePaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class LightBackgroundPainter extends CustomPainter {
  final Color lightColor;

  LightBackgroundPainter({required this.lightColor});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);

    // Draw light rays or beams
    for (int i = 0; i < 15; i++) {
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final angle = random.nextDouble() * pi * 2;
      final length = 30 + random.nextDouble() * 100;
      final opacity = 0.1 + random.nextDouble() * 0.15;

      final paint =
          Paint()
            ..color = lightColor.withValues(alpha: opacity)
            ..strokeWidth = 1 + random.nextDouble() * 3
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke;

      final endX = startX + cos(angle) * length;
      final endY = startY + sin(angle) * length;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);

      // Add a subtle glow at the start point
      final glowPaint =
          Paint()
            ..color = lightColor.withValues(alpha: opacity)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(startX, startY),
        3 + random.nextDouble() * 2,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
} 
