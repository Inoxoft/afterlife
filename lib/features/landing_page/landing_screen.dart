// lib/features/landing_page/landing_screen.dart
import 'package:flutter/material.dart';
import 'package:afterlife/core/theme/app_theme.dart';
import 'package:afterlife/core/widgets/animated_particles.dart';
import '../character_interview/interview_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

 // In the _onCreateButtonPressed method of landing_screen.dart
Future<void> _onCreateButtonPressed() async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const InterviewScreen()),
  );
  
  if (result != null) {
    // Process the returned character data
    final characterCard = result['characterCard'];
    final characterName = result['characterName'];
    
    // Here you would typically save the character to local storage
    // and/or navigate to a character view screen
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Created digital twin: ${characterName ?? 'Unnamed'}'),
        backgroundColor: AppTheme.etherealCyan,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.backgroundStart, AppTheme.backgroundEnd],
          ),
        ),
        child: Stack(
          children: [
            // Animated particles background
            const AnimatedParticles(
              particleCount: 70,
              particleColor: Colors.white,
            ),
            
            // Main content
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App title with subtle glow
                    const SizedBox(height: 80),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(seconds: 2),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.etherealCyan.withOpacity(0.2),
                              blurRadius: 15,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Text(
                          'AFTERLIFE',
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Tagline
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(seconds: 2),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: child,
                        );
                      },
                      child: Text(
                        'Create your digital twin',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),

                    const Spacer(),
                    
                    // Optional status text
                    Text(
                      'Digital Twins: 0',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 14,
                        color: Colors.white38,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Create button with animation
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.etherealCyan.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _onCreateButtonPressed,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(20),
                            minimumSize: const Size(70, 70),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 32,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 60),
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
