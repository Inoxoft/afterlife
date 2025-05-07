import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/animated_particles.dart';
import '../character_gallery/character_gallery_screen.dart';
import 'pages/mask_page.dart';
import 'pages/llm_page.dart';
import 'pages/explore_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  int _currentPage = 0;
  late AnimationController _animationController;
  bool _isForward = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToNextPage() {
    if (_currentPage < 2) {
      _animationController.reset();
      setState(() {
        _currentPage++;
        _isForward = true;
      });
      _animationController.forward();
    } else {
      // Navigate to main app on last page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CharacterGalleryScreen()),
      );
    }
  }

  void _navigateToPreviousPage() {
    if (_currentPage > 0) {
      _animationController.reset();
      setState(() {
        _currentPage--;
        _isForward = false;
      });
      _animationController.forward();
    }
  }

  Widget _getPage() {
    switch (_currentPage) {
      case 0:
        return MaskPage(animationController: _animationController);
      case 1:
        return LLMPage(animationController: _animationController);
      case 2:
        return ExplorePage(animationController: _animationController);
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2E1A47), // Deep purple
              const Color(0xFF1F1147), // Dark purple
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background grid and particles
            CustomPaint(painter: GridPainter(), size: Size.infinite),
            const RepaintBoundary(
              child: Opacity(
                opacity: 0.5,
                child: AnimatedParticles(
                  particleCount: 20,
                  particleColor: Colors.white,
                  minSpeed: 0.01,
                  maxSpeed: 0.05,
                ),
              ),
            ),

            // Main content with animations
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  ),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin:
                          _isForward
                              ? const Offset(0.3, 0)
                              : const Offset(-0.3, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_currentPage),
                child: _getPage(),
              ),
            ),

            // Navigation buttons at the bottom
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Back button (hidden on first page)
                    if (_currentPage > 0)
                      ElevatedButton(
                        onPressed: _navigateToPreviousPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: const Color(
                            0xFFF9E3A3,
                          ), // Light yellow
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: const BorderSide(
                              color: Color(0xFFF9E3A3), // Light yellow
                              width: 1,
                            ),
                          ),
                        ),
                        child: const Text(
                          "BACK",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    // Space between buttons or page indicators
                    const SizedBox(width: 20),

                    // Page indicators
                    Row(
                      children: List.generate(
                        3,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                _currentPage == index
                                    ? const Color(0xFFF9E3A3) // Light yellow
                                    : const Color(0xFFF9E3A3).withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 20),

                    // Next/Begin button
                    ElevatedButton(
                      onPressed: _navigateToNextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFFF9E3A3,
                        ), // Light yellow
                        foregroundColor: const Color(0xFF2E1A47), // Deep purple
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                        shadowColor: const Color(0xFFF9E3A3).withOpacity(0.5),
                      ),
                      child: Text(
                        _currentPage == 2 ? "BEGIN" : "NEXT",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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

// Grid background painter with adjusted colors
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFFF9E3A3).withOpacity(
            0.05,
          ) // Light yellow with low opacity
          ..strokeWidth = 0.5;

    // Draw vertical lines
    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Draw horizontal lines
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
