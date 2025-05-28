import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../features/developer_chat/developer_chat_screen.dart';
import '../../../l10n/app_localizations.dart';

class ExplorePage extends StatelessWidget {
  final AnimationController animationController;

  const ExplorePage({super.key, required this.animationController});

  void _navigateToDeveloperChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DeveloperChatScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
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
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    final contentAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    final developerTwinAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
                      l10n?.diversePerspectives ?? 'DIVERSE PERSPECTIVES',
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
                      l10n?.fromPoliticsToArt ?? 'From politics to art, history comes alive',
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

            const SizedBox(height: 30),

            // Conversation visualization with animation
            FadeTransition(
              opacity: imageAnimation,
              child: ScaleTransition(
                scale: imageAnimation,
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Image.asset(
                    'assets/images/perspective_mask.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: AppTheme.silverMist.withOpacity(0.5),
                          size: 40,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Safety and exploration tips with animation
            SlideTransition(
              position: contentAnimation,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: animationController,
                  curve: const Interval(0.3, 0.9),
                ),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppTheme.midnightPurple.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.cosmicBlack.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildTipRow(
                        Icons.history_edu,
                        l10n?.engageWithDiverseFigures ?? 'Engage with diverse figures from politics, science, art, and more who shaped our world.',
                      ),
                      const SizedBox(height: 16),
                      _buildTipRow(
                        Icons.psychology_alt,
                        l10n?.rememberSimulations ?? 'Remember that these are simulations based on available data - responses represent our best attempt at historical accuracy.',
                      ),
                      const SizedBox(height: 16),
                      _buildTipRow(
                        Icons.add_circle_outline,
                        l10n?.createYourOwnTwins ?? 'Create your own digital twins by using the Create button in the bottom navigation.',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Developer twin info with animation
            SlideTransition(
              position: developerTwinAnimation,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: animationController,
                  curve: const Interval(0.5, 1.0),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.midnightPurple.withOpacity(0.7),
                        AppTheme.backgroundStart.withOpacity(0.4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.warmGold.withOpacity(0.1),
                        blurRadius: 15,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.midnightPurple.withOpacity(0.6),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.warmGold.withOpacity(0.15),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.developer_mode,
                          color: AppTheme.warmGold,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n?.chatWithDeveloperTwin ?? 'CHAT WITH DEVELOPER TWIN',
                              style: GoogleFonts.cinzel(
                                color: AppTheme.silverMist,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n?.chatWithDeveloperDescription ?? 'Chat with the developer\'s digital twin to learn more about the app and how it works.',
                              style: GoogleFonts.lato(
                                color: AppTheme.silverMist.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => _navigateToDeveloperChat(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.midnightPurple,
                                foregroundColor: AppTheme.warmGold,
                                elevation: 5,
                                shadowColor: AppTheme.warmGold.withOpacity(0.2),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                l10n?.chatWithDeveloperTwin ?? 'CHAT WITH DEVELOPER TWIN',
                                style: GoogleFonts.cinzel(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.warmGold.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.warmGold, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.lato(
              color: AppTheme.silverMist,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}