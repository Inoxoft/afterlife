// lib/features/landing_page/landing_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:afterlife/core/theme/app_theme.dart';
import 'package:afterlife/core/widgets/animated_particles.dart';
import '../character_interview/interview_screen.dart';
import '../providers/characters_provider.dart';
import '../models/character_model.dart';
import '../character_gallery/character_gallery_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final ValueNotifier<bool> _isHovering = ValueNotifier<bool>(false);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Set loading to false after short delay to ensure screen is visible
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _isHovering.dispose();
    super.dispose();
  }

  Future<void> _onCreateButtonPressed() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const InterviewScreen()),
      );

      if (result != null && mounted) {
        // Process the returned character data
        final characterCard = result['characterCard'];
        final characterName = result['characterName'];

        if (characterCard != null && characterName != null) {
          print('Character data received - Name: $characterName');
          print('Card content length: ${characterCard.length}');

          try {
            // Create new character
            final charactersProvider = Provider.of<CharactersProvider>(
              context,
              listen: false,
            );

            final newCharacter = CharacterModel.fromInterviewData(
              name: characterName,
              cardContent: characterCard,
            );

            print('Character created with ID: ${newCharacter.id}');

            await charactersProvider.addCharacter(newCharacter);
            print('Character added to provider');

            // Navigate directly to the character gallery screen
            // instead of using named route to avoid any navigation issues
            if (mounted) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CharacterGalleryScreen(),
                ),
              );
            }
          } catch (e) {
            print('Error creating character: $e');
            _showError('Error creating character: $e');
          }
        } else {
          print('Invalid character data received');
          _showError('Invalid character data received');
        }
      }
    } catch (e) {
      print("Error navigating to interview screen: $e");
      _showError('Could not open interview screen');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onViewCharactersPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CharacterGalleryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ensure we have a valid screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (screenWidth <= 0 || screenHeight <= 0) {
      // Return a minimal screen if dimensions are invalid
      return const Scaffold(
        backgroundColor: AppTheme.backgroundStart,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.etherealCyan),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundStart, // Fallback background color
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: Stack(
          children: [
            // Animated particles background - only show when not loading
            if (!_isLoading)
              const SafeArea(
                bottom: false,
                child: AnimatedParticles(
                  particleCount: 60,
                  particleColor: Colors.white,
                  minSpeed: 0.01,
                  maxSpeed: 0.05,
                ),
              ),

            // Subtle accent glow
            if (!_isLoading)
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentPurple.withOpacity(0.1),
                        blurRadius: 100,
                        spreadRadius: 50,
                      ),
                    ],
                  ),
                ),
              ),

            if (!_isLoading)
              Positioned(
                bottom: -120,
                left: -120,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.etherealCyan.withOpacity(0.08),
                        blurRadius: 100,
                        spreadRadius: 60,
                      ),
                    ],
                  ),
                ),
              ),

            // Main content
            SafeArea(
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.etherealCyan,
                          ),
                        ),
                      )
                      : Center(
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
                                decoration: AppTheme.glowDecoration,
                                child: Text(
                                  'AFTERLIFE',
                                  style:
                                      Theme.of(context).textTheme.displayLarge,
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
                                return Opacity(opacity: value, child: child);
                              },
                              child: Text(
                                'Create your digital twin',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),

                            const Spacer(),

                            // Characters counter
                            Consumer<CharactersProvider>(
                              builder: (context, provider, _) {
                                final charactersCount =
                                    provider.characters.length;

                                if (charactersCount > 0) {
                                  print(
                                    'Found $charactersCount characters in provider',
                                  );
                                }

                                return Column(
                                  children: [
                                    // Only show if there are characters
                                    if (charactersCount > 0)
                                      GestureDetector(
                                        onTap: _onViewCharactersPressed,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.accentPurple
                                                .withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: AppTheme.accentPurple
                                                  .withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.people_alt_outlined,
                                                size: 16,
                                                color: AppTheme.accentPurple,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Digital Twins: $charactersCount',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white70,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                size: 12,
                                                color: Colors.white30,
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    else
                                      Text(
                                        'Digital Twins: 0',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.copyWith(
                                          fontSize: 14,
                                          color: Colors.white38,
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 24),

                            // Create button with animation and hover effect
                            MouseRegion(
                              onEnter: (_) => _isHovering.value = true,
                              onExit: (_) => _isHovering.value = false,
                              child: ValueListenableBuilder(
                                valueListenable: _isHovering,
                                builder: (context, isHovering, child) {
                                  return ScaleTransition(
                                    scale: _pulseAnimation,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.etherealCyan
                                                .withOpacity(
                                                  isHovering ? 0.5 : 0.3,
                                                ),
                                            blurRadius: isHovering ? 25 : 20,
                                            spreadRadius: isHovering ? 3 : 2,
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
                                  );
                                },
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
