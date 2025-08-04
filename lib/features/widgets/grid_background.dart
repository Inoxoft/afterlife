import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class GridBackground extends StatelessWidget {
  final Widget child;
  final bool withFade;

  const GridBackground({super.key, required this.child, this.withFade = true});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base color
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkColor.withValues(alpha: 0.9),
                AppTheme.darkAccentColor.withValues(alpha: 0.95),
              ],
            ),
          ),
        ),

        // Grid lines
        const CustomPaint(painter: GridPainter(), size: Size.infinite),

        // Glow orbs for sci-fi effect
        Positioned(
          top: MediaQuery.of(context).size.height * 0.1,
          left: -MediaQuery.of(context).size.width * 0.2,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        Positioned(
          bottom: -100,
          right: -70,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.accentColor.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Overlay fade (for content readability)
        if (withFade)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.darkColor.withValues(alpha: 0.6),
                  AppTheme.darkColor.withValues(alpha: 0.3),
                  AppTheme.darkColor.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),

        // Content
        child,
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  const GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppTheme.primaryColor.withValues(alpha: 0.3)
          ..strokeWidth = 1;

    // Horizontal lines
    double spacingY = 40;
    for (double y = 0; y < size.height; y += spacingY) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Vertical lines
    double spacingX = 40;
    for (double x = 0; x < size.width; x += spacingX) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Add random highlight points at grid intersections
    final highlightPaint =
        Paint()
          ..color = AppTheme.primaryColor.withValues(alpha: 0.7)
          ..strokeWidth = 3;

    final random = Random(42); // Fixed seed for consistent pattern

    for (double x = 0; x < size.width; x += spacingX) {
      for (double y = 0; y < size.height; y += spacingY) {
        if (random.nextDouble() < 0.05) {
          // 5% chance for a highlight
          canvas.drawCircle(Offset(x, y), 2, highlightPaint);

          // Sometimes draw a pulse effect
          if (random.nextDouble() < 0.3) {
            canvas.drawCircle(
              Offset(x, y),
              6,
              Paint()
                ..color = AppTheme.primaryColor.withValues(alpha: 0.3)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1,
            );
          }
        }
      }
    }

    // Draw a few larger grid elements to suggest tech interfaces
    final techInterfacePaint =
        Paint()
          ..color = AppTheme.accentColor.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    for (int i = 0; i < 5; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final size1 = random.nextDouble() * 80 + 40;
      final size2 = random.nextDouble() * 40 + 20;

      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: size1, height: size2),
        techInterfacePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
