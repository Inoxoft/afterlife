import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';

class MaskPage extends StatelessWidget {
  final AnimationController animationController;

  const MaskPage({Key? key, required this.animationController})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
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
                      localizations.understandMasks,
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
                      localizations.digitalPersonasWithHistoricalEssence,
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

            const SizedBox(height: 0), // No space between title and image
            // Einstein mask illustration with animation
            FadeTransition(
              opacity: imageAnimation,
              child: ScaleTransition(
                scale: imageAnimation,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Mathematical equations background elements
                    Positioned(
                      top: 20,
                      right: 40,
                      child: Text(
                        'E=mc²',
                        style: GoogleFonts.lato(
                          color: AppTheme.warmGold.withOpacity(0.3),
                          fontSize: 22,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w200,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 50,
                      left: 40,
                      child: Text(
                        'π',
                        style: GoogleFonts.lato(
                          color: AppTheme.warmGold.withOpacity(0.25),
                          fontSize: 24,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w200,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 120,
                      left: 50,
                      child: Transform.rotate(
                        angle: -0.2,
                        child: Text(
                          'ψ',
                          style: GoogleFonts.lato(
                            color: AppTheme.warmGold.withOpacity(0.2),
                            fontSize: 20,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w200,
                          ),
                        ),
                      ),
                    ),

                    // Yellow neural connection lines
                    CustomPaint(
                      size: const Size(300, 350),
                      painter: NeuralLinesPainter(),
                    ),

                    // Einstein image - this would be replaced with the actual asset image
                    Hero(
                      tag: 'einstein_mask',
                      child: Container(
                        height: 310, // More compact image size
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Image.asset(
                          'assets/images/einstein_mask.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 280,
                              decoration: BoxDecoration(
                                color: AppTheme.midnightPurple.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      color: AppTheme.warmGold,
                                      size: 60,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      localizations.einsteinWithMaskAndLLMArmor,
                                      textAlign: TextAlign.center,
                                      style: AppTheme.captionStyle,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 0,
            ), // No space between image and explanations
            // Explanation points with animation and icons
            SlideTransition(
              position: contentAnimation,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: animationController,
                  curve: const Interval(0.3, 1.0),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildExplanationWithIcon(
                      context,
                      Icons.face_retouching_natural,
                      localizations.masksAreAIPersonas,
                    ),
                    const SizedBox(height: 10),
                    _buildExplanationWithIcon(
                      context,
                      Icons.psychology,
                      localizations.eachMaskTriesToEmbody,
                    ),
                    const SizedBox(height: 10),
                    _buildExplanationWithIcon(
                      context,
                      Icons.people_alt,
                      localizations.theseDigitalTwinsAllow,
                    ),
                    // Add extra spacing at the bottom to avoid button overlap
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

  Widget _buildExplanationWithIcon(BuildContext context, IconData iconData, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            child: Icon(iconData, color: AppTheme.warmGold, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.lato(
                color: AppTheme.silverMist,
                fontSize: 14,
                height: 1.3,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for the neural network-like yellow lines
class NeuralLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppTheme.warmGold.withOpacity(0.4)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    // Draw a few curved lines representing neural connections
    final path1 =
        Path()
          ..moveTo(size.width * 0.65, size.height * 0.35)
          ..quadraticBezierTo(
            size.width * 0.8,
            size.height * 0.4,
            size.width * 0.7,
            size.height * 0.5,
          );

    final path2 =
        Path()
          ..moveTo(size.width * 0.7, size.height * 0.3)
          ..quadraticBezierTo(
            size.width * 0.85,
            size.height * 0.35,
            size.width * 0.75,
            size.height * 0.45,
          );

    final path3 =
        Path()
          ..moveTo(size.width * 0.72, size.height * 0.32)
          ..quadraticBezierTo(
            size.width * 0.9,
            size.height * 0.38,
            size.width * 0.8,
            size.height * 0.48,
          );

    // Add some small circles at the neural connection endpoints
    final circlePaint =
        Paint()
          ..color = AppTheme.warmGold.withOpacity(0.6)
          ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.65, size.height * 0.35),
      2,
      circlePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.5),
      2,
      circlePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.3),
      2,
      circlePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.45),
      2,
      circlePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.32),
      2,
      circlePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.48),
      2,
      circlePaint,
    );

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}