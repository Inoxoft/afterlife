import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:afterlife/core/theme/app_theme.dart';
import 'package:afterlife/core/widgets/animated_particles.dart';
import 'package:afterlife/features/main/main_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // After animation completes, navigate to the main screen
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        });
      }
    });

    // Set preferred orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: Stack(
          children: [
            const AnimatedParticles(
              particleCount: 50,
              particleColor: Colors.white,
              minSpeed: 0.01,
              maxSpeed: 0.05,
            ),
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        errorBuilder: (context, error, stackTrace) {
                          return const CircleAvatar(
                            radius: 75,
                            backgroundColor: Colors.white24,
                            child: Icon(
                              Icons.person_outline,
                              size: 80,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'Afterlife',
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your Digital Twin Awaits',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 60),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
