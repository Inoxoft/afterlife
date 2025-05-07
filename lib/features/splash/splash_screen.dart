import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/animated_particles.dart';
import '../character_gallery/character_gallery_screen.dart';
import '../onboarding/onboarding_screen.dart';
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
  bool _isInitialized = false;
  String _statusMessage = 'INITIALIZING PRESERVATION SYSTEMS';
  double _loadingProgress = 0.0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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

    // Start initialization sequence
    _initializeApp();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Simulate loading for visual feedback (min 1.5 seconds)
    final loadingTimer = Timer.periodic(const Duration(milliseconds: 50), (
      timer,
    ) {
      if (_loadingProgress < 0.95) {
        // Only go up to 95% during initialization
        setState(() {
          _loadingProgress += 0.025;
          if (_loadingProgress > 0.95) _loadingProgress = 0.95;
        });
      } else {
        timer.cancel();
      }
    });

    try {
      // Initialize services in sequence with status updates

      // Step 1: Load environment configuration
      setState(() => _statusMessage = 'LOADING ENVIRONMENT CONFIGURATION');
      await EnvConfig.initialize();

      // Step 2: Initialize chat services
      setState(() => _statusMessage = 'ESTABLISHING NEURAL CONNECTIONS');
      await interview_chat.ChatService.initialize();

      // Step 3: Optimize performance
      setState(() => _statusMessage = 'OPTIMIZING NEURAL PATHWAYS');
      await PerformanceOptimizer.initialize();

      // Step 4: Preload critical images
      setState(() => _statusMessage = 'LOADING MEMORY FRAGMENTS');
      await ImageOptimizer.preloadAppImages();

      // Step 5: Check for API key
      setState(() => _statusMessage = 'VERIFYING ACCESS CREDENTIALS');
      final hasApiKey = EnvConfig.hasValue('OPENROUTER_API_KEY');

      // Step 6: Complete initialization
      setState(() {
        _statusMessage = 'PRESERVATION SYSTEMS ONLINE';
        _isInitialized = true;
      });

      // Ensure minimum display time (visual polish)
      final minimumDisplayDuration = Duration(milliseconds: 1500);
      final elapsed = DateTime.now().difference(
        DateTime.now().subtract(minimumDisplayDuration),
      );
      if (elapsed < minimumDisplayDuration) {
        await Future.delayed(minimumDisplayDuration - elapsed);
      }

      // Cancel the timer if it's still active
      loadingTimer.cancel();

      // Complete the loading bar to 100%
      setState(() {
        _loadingProgress = 1.0;
      });

      // Wait a moment to show the completed loading bar
      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate to next screen
      if (mounted) {
        if (!hasApiKey) {
          // Show API key input dialog if needed
          final result = await ApiKeyInputDialog.show(context);
          if (result) {
            // User entered API key, proceed to main screen
            _navigateToMainScreen();
          } else {
            // User cancelled, still proceed but they'll be prompted again later
            _navigateToMainScreen();
          }
        } else {
          // API key exists, proceed directly
          _navigateToMainScreen();
        }
      }
    } catch (e) {
      // Handle initialization errors
      setState(() {
        _statusMessage = 'INITIALIZATION ERROR: $e';
        _isInitialized = false;
      });
      loadingTimer.cancel();
    }
  }

  void _navigateToMainScreen() {
    // Animate loading bar from current value to 100% over 2 seconds
    final startValue = _loadingProgress;
    final animationDuration = const Duration(seconds: 2);
    final frameDuration = const Duration(milliseconds: 16); // ~60fps
    final totalFrames =
        animationDuration.inMilliseconds ~/ frameDuration.inMilliseconds;
    int currentFrame = 0;

    Timer.periodic(frameDuration, (timer) {
      currentFrame++;
      if (currentFrame <= totalFrames && mounted) {
        final progress =
            startValue + ((1.0 - startValue) * (currentFrame / totalFrames));
        setState(() {
          _loadingProgress = progress;
        });
      } else {
        timer.cancel();
        if (mounted) {
          // Navigate to onboarding screen instead of character gallery
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        }
      }
    });
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
                          height: 180,
                          decoration: BoxDecoration(
                            color: AppTheme.etherealCyan.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.etherealCyan.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.psychology_alt,
                              size: 60,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 60),

                  // App title
                  const Text(
                    'AFTERLIFE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    'PRESERVED CONSCIOUSNESS',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 80),

                  // Loading status & progress
                  SizedBox(
                    width: 240,
                    child: Column(
                      children: [
                        // Loading bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _loadingProgress,
                            backgroundColor: Colors.black.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.etherealCyan,
                            ),
                            minHeight: 4,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Status message
                        Text(
                          _statusMessage,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
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
          ..color = Colors.teal.withOpacity(0.15)
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
