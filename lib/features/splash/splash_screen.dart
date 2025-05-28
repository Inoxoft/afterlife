import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../onboarding/onboarding_screen.dart';
import '../providers/language_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/animated_particles.dart';
import '../character_gallery/character_gallery_screen.dart';
import '../../core/utils/env_config.dart';
import '../../core/utils/image_optimizer.dart';
import '../../core/utils/performance_optimizer.dart';
import '../character_interview/chat_service.dart' as interview_chat;
import '../../core/widgets/api_key_input_dialog.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  String _statusMessage = 'INITIALIZING PRESERVATION SYSTEMS';
  double _loadingProgress = 0.0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeInAnimation;
  static const String _firstTimeKey = 'is_first_time_user';

  // Cache widgets for performance
  late final Widget _backgroundParticles = const RepaintBoundary(
    child: Opacity(
      opacity: 0.5,
      child: AnimatedParticles(
        particleCount: 20, // Reduced count for performance
        particleColor: Colors.white,
        minSpeed: 0.01,
        maxSpeed: 0.05,
      ),
    ),
  );

  @override
  void initState() {
    super.initState();

    // Set up pulsing animation for the icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Create fade-in animation
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Start initialization sequence
    _initializeApp();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      // Simulate loading progress
      for (int i = 0; i <= 100; i += 10) {
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 100));
        setState(() {
          _loadingProgress = i / 100;
          switch (i) {
            case 20:
              _statusMessage = 'CALIBRATING NEURAL NETWORKS';
              break;
            case 40:
              _statusMessage = 'SYNCHRONIZING QUANTUM STATES';
              break;
            case 60:
              _statusMessage = 'ALIGNING CONSCIOUSNESS MATRICES';
              break;
            case 80:
              _statusMessage = 'ESTABLISHING NEURAL LINKS';
              break;
            case 100:
              _statusMessage = 'PRESERVATION SYSTEMS READY';
              break;
          }
        });
      }

      // Check if this is the first time running the app
      final prefs = await SharedPreferences.getInstance();
      // For debugging: always show onboarding
      const isFirstTime = true;
      // Uncomment below line for production:
      // final isFirstTime = prefs.getBool(_firstTimeKey) ?? true;

      // Wait for a minimum time to show the splash screen
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Navigate to the appropriate screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => isFirstTime
              ? const OnboardingScreen()
              : const CharacterGalleryScreen(),
        ),
      );

      // Set first time flag to false (commented out for debugging)
      // if (isFirstTime) {
      //   await prefs.setBool(_firstTimeKey, false);
      // }
    } catch (e) {
      print('Error during app initialization: $e');
      if (!mounted) return;
      
      // Show error state in the UI
      setState(() {
        _statusMessage = 'ERROR INITIALIZING SYSTEMS';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: Stack(
          children: [
            // Grid background
            CustomPaint(painter: GridPainter(), size: Size.infinite),

            // Background particles
            _backgroundParticles,

            // Main content
            Center(
              child: FadeTransition(
                opacity: _fadeInAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo/icon
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.warmGold.withOpacity(0.5),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.warmGold.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.psychology_outlined,
                                size: 60,
                                color: AppTheme.warmGold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),

                    // App name
                    Text(
                      'AFTERLIFE',
                      style: GoogleFonts.cinzel(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        color: AppTheme.warmGold,
                        shadows: [
                          Shadow(
                            color: AppTheme.warmGold.withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Status message
                    Text(
                      _statusMessage,
                      style: GoogleFonts.spaceMono(
                        fontSize: 14,
                        color: AppTheme.silverMist.withOpacity(0.7),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Loading progress indicator
                    SizedBox(
                      width: 200,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _loadingProgress,
                          backgroundColor: AppTheme.midnightPurple,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.warmGold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Grid painter to draw a grid pattern background
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppTheme.warmGold.withOpacity(0.08)
          ..strokeWidth = 0.5
          ..style = PaintingStyle.stroke;

    const double spacing = 40.0;

    // Draw vertical lines
    for (double i = 0; i <= size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Draw horizontal lines
    for (double i = 0; i <= size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
