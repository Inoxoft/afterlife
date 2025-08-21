import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/animated_particles.dart';
import '../../core/services/onboarding_service.dart';
import '../character_gallery/character_gallery_screen.dart';
import 'pages/mask_page.dart';
import 'pages/llm_page.dart';
import 'pages/setup_guide_page.dart';
import 'pages/explore_page.dart';
import 'pages/language_page.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/ukrainian_font_utils.dart';

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
    if (_currentPage < 4) {
      _animationController.reset();
      setState(() {
        _currentPage++;
        _isForward = true;
      });
      _animationController.forward();
    } else {
      // Mark onboarding as complete and navigate to main app
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    // Mark onboarding as complete
    await OnboardingService.markOnboardingComplete();

    if (!mounted) return;

    // Navigate to main app
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const CharacterGalleryScreen()),
    );
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
        return const LanguagePage();
      case 1:
        return MaskPage(animationController: _animationController);
      case 2:
        return LLMPage(animationController: _animationController);
      case 3:
        return SetupGuidePage(animationController: _animationController);
      case 4:
        return ExplorePage(animationController: _animationController);
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: Stack(
          children: [
            // Background stars and particles
            RepaintBoundary(
              child: CustomPaint(
                painter: StarfieldPainter(starCount: 100),
                size: Size.infinite,
              ),
            ),
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
                          foregroundColor: AppTheme.warmGold,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(
                              color: AppTheme.warmGold,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text(
                          localizations.backButton,
                          style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                            text: localizations.backButton,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),

                    // Space between buttons or page indicators
                    const SizedBox(width: 20),

                    // Page indicators
                    Row(
                      children: List.generate(
                        5,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                _currentPage == index
                                    ? AppTheme.warmGold
                                    : AppTheme.warmGold.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 20),

                    // Next/Begin button
                    ElevatedButton(
                      onPressed: _navigateToNextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.warmGold,
                        foregroundColor: AppTheme.midnightPurple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                        shadowColor: AppTheme.warmGold.withValues(alpha: 0.5),
                      ),
                      child: Text(
                        _currentPage == 4
                            ? localizations.getStarted
                            : localizations.nextButton,
                        style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                          text:
                              _currentPage == 4
                                  ? localizations.getStarted
                                  : localizations.nextButton,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
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

// Star background classes
class StarfieldPainter extends CustomPainter {
  final int starCount;
  final List<_Star> _stars = [];
  final Paint _starPaint = Paint()..color = Colors.white;

  // Fixed random for consistent rendering
  final Random _random = Random(42);

  StarfieldPainter({this.starCount = 100}) {
    // Pre-generate stars only once for performance
    _generateStars();
  }

  void _generateStars() {
    for (int i = 0; i < starCount; i++) {
      _stars.add(
        _Star(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 2 + 0.5,
          opacity: _random.nextDouble() * 0.7 + 0.3,
        ),
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in _stars) {
      final x = star.x * size.width;
      final y = star.y * size.height;
      _starPaint.color = Colors.white.withValues(alpha: star.opacity);
      canvas.drawCircle(Offset(x, y), star.size, _starPaint);
    }
  }

  @override
  bool shouldRepaint(StarfieldPainter oldDelegate) => false; // Never repaint
}

class _Star {
  final double x;
  final double y;
  final double size;
  final double opacity;

  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
  });
}
