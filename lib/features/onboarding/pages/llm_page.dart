import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' show pi, cos, sin;

class LLMPage extends StatelessWidget {
  final AnimationController animationController;

  const LLMPage({Key? key, required this.animationController})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create staggered animations with smoother curves
    final titleAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    final imageAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    final contentAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title with animation
            SlideTransition(
              position: titleAnimation,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: animationController,
                  curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'LANGUAGE MODELS',
                      style: GoogleFonts.cinzel(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3.0,
                        color: AppTheme.silverMist,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: AppTheme.warmGold.withOpacity(0.8),
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose the right brain for your digital twins',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.silverMist.withOpacity(0.9),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // LLM comparison visualization
            FadeTransition(
              opacity: imageAnimation,
              child: ScaleTransition(
                scale: imageAnimation,
                child: Container(
                  height: 280,
                  child: Stack(
                    children: [
                      // Left side - Basic LLM
                      Positioned(
                        left: 0,
                        top: 0,
                        width: MediaQuery.of(context).size.width * 0.4,
                        height: 280,
                        child: Column(
                          children: [
                            Text(
                              'BASIC LLM',
                              style: GoogleFonts.cinzel(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.silverMist.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Simple neuron visualization
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.midnightPurple.withOpacity(0.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.cosmicBlack.withOpacity(
                                      0.3,
                                    ),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: CustomPaint(
                                painter: SimpleNeuronPainter(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Limited Knowledge',
                              style: GoogleFonts.lato(
                                fontSize: 13,
                                fontWeight: FontWeight.w300,
                                color: AppTheme.silverMist.withOpacity(0.7),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.midnightPurple.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'E = ?',
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.silverMist.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right side - Advanced LLM
                      Positioned(
                        right: 0,
                        top: 0,
                        width: MediaQuery.of(context).size.width * 0.4,
                        height: 280,
                        child: Column(
                          children: [
                            Text(
                              'ADVANCED LLM',
                              style: GoogleFonts.cinzel(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.warmGold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Complex neuron visualization
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.midnightPurple.withOpacity(0.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.cosmicBlack.withOpacity(
                                      0.3,
                                    ),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: CustomPaint(
                                painter: ComplexNeuronPainter(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Deep Expertise',
                              style: GoogleFonts.lato(
                                fontSize: 13,
                                fontWeight: FontWeight.w300,
                                color: AppTheme.warmGold,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.midnightPurple.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'E = mc²',
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.warmGold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Center connecting line
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            width: 2,
                            height: 200,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppTheme.silverMist.withOpacity(0.2),
                                  AppTheme.warmGold.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // LLM options explanation with animation
            SlideTransition(
              position: contentAnimation,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: animationController,
                  curve: const Interval(0.3, 1.0),
                ),
                child: Column(
                  children: [
                    _buildModelOptionCard(
                      'OpenRouter Models',
                      'Access powerful cloud-based models like Claude, GPT-4, and others. Best for complex conversations and deep expertise.',
                      'RECOMMENDED',
                    ),
                    const SizedBox(height: 10),
                    _buildModelOptionCard(
                      'Local LLMs',
                      'Run AI models directly on your device. More private but may have limited capabilities depending on your hardware.',
                      null,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Note: Einstein with a basic model might struggle with complex physics, while Einstein with an advanced model could explain relativity in detail!',
                      style: GoogleFonts.lato(
                        color: AppTheme.silverMist.withOpacity(0.7),
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(
                          Icons.settings,
                          color: AppTheme.warmGold,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'You can change LLM settings anytime',
                          style: GoogleFonts.lato(
                            color: AppTheme.silverMist,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    // Add bottom spacing for button
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelOptionCard(
    String title,
    String description,
    String? badge,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: AppTheme.midnightPurple.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cosmicBlack.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.midnightPurple.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.warmGold.withOpacity(0.2),
                  blurRadius: 5,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(
              title.contains('OpenRouter') ? Icons.cloud : Icons.phone_android,
              color: AppTheme.warmGold,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cinzel(
                        color: AppTheme.silverMist,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.midnightPurple.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: GoogleFonts.lato(
                            color: AppTheme.warmGold,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: GoogleFonts.lato(
                    color: AppTheme.silverMist.withOpacity(0.8),
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Paint a simple neuron network
class SimpleNeuronPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppTheme.silverMist.withOpacity(0.3)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

    final dotPaint =
        Paint()
          ..color = AppTheme.silverMist.withOpacity(0.5)
          ..style = PaintingStyle.fill;

    // Draw a few simple connections
    final center = Offset(size.width / 2, size.height / 2);

    // Draw 4 nodes and connections
    for (int i = 0; i < 4; i++) {
      final angle = i * (pi / 2);
      final nodeOffset = Offset(
        center.dx + cos(angle) * 30,
        center.dy + sin(angle) * 30,
      );

      // Draw connection
      canvas.drawLine(center, nodeOffset, paint);

      // Draw node
      canvas.drawCircle(nodeOffset, 3, dotPaint);
    }

    // Draw center node
    canvas.drawCircle(center, 5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Paint a complex neuron network
class ComplexNeuronPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppTheme.warmGold.withOpacity(0.6)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

    final dotPaint =
        Paint()
          ..color = AppTheme.warmGold.withOpacity(0.8)
          ..style = PaintingStyle.fill;

    // Draw many connections in a more complex pattern
    final center = Offset(size.width / 2, size.height / 2);

    // Draw first layer - 8 nodes
    List<Offset> firstLayer = [];
    for (int i = 0; i < 8; i++) {
      final angle = i * (pi / 4);
      final nodeOffset = Offset(
        center.dx + cos(angle) * 40,
        center.dy + sin(angle) * 40,
      );
      firstLayer.add(nodeOffset);

      // Draw connection to center
      canvas.drawLine(center, nodeOffset, paint);

      // Draw node
      canvas.drawCircle(nodeOffset, 2, dotPaint);
    }

    // Draw some inter-connections between nodes
    for (int i = 0; i < firstLayer.length; i++) {
      for (int j = i + 2; j < firstLayer.length; j += 3) {
        canvas.drawLine(firstLayer[i], firstLayer[j], paint..strokeWidth = 0.5);
      }
    }

    // Draw center node
    canvas.drawCircle(center, 5, dotPaint);

    // Add some glowing effect
    canvas.drawCircle(
      center,
      25,
      Paint()
        ..color = AppTheme.warmGold.withOpacity(0.1)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
