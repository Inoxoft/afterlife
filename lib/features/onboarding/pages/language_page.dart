import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../features/providers/language_provider.dart';
import '../../../l10n/app_localizations.dart';

class LanguagePage extends StatelessWidget {
  final AnimationController animationController;

  const LanguagePage({Key? key, required this.animationController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final titleAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
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

    final localizations = AppLocalizations.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    final languages = [
      {'code': 'en', 'name': localizations.languageEnglish},
      {'code': 'es', 'name': localizations.languageSpanish},
      {'code': 'fr', 'name': localizations.languageFrench},
      {'code': 'de', 'name': localizations.languageGerman},
      {'code': 'ja', 'name': localizations.languageJapanese},
      {'code': 'ko', 'name': localizations.languageKorean},
      {'code': 'zh', 'name': localizations.languageChinese},
      {'code': 'pt', 'name': localizations.languagePortuguese},
      {'code': 'ru', 'name': localizations.languageRussian},
      {'code': 'hi', 'name': localizations.languageHindi},
      {'code': 'it', 'name': localizations.languageItalian},
      {'code': 'uk', 'name': localizations.languageUkrainian},
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
                      localizations.language.toUpperCase(),
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
                      localizations.languageDescription,
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
            const SizedBox(height: 32),
            Expanded(
              child: SlideTransition(
                position: contentAnimation,
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animationController,
                    curve: const Interval(0.3, 1.0),
                  ),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: languages.length,
                    itemBuilder: (context, index) {
                      final language = languages[index];
                      final isSelected = languageProvider.currentLanguageCode == language['code'];
                      
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            languageProvider.setLanguage(language['code']!);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppTheme.warmGold : AppTheme.warmGold.withOpacity(0.3),
                                width: isSelected ? 2 : 1,
                              ),
                              color: isSelected 
                                ? AppTheme.warmGold.withOpacity(0.1)
                                : AppTheme.midnightPurple.withOpacity(0.3),
                            ),
                            child: Center(
                              child: Text(
                                language['name']!,
                                style: GoogleFonts.lato(
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppTheme.warmGold : AppTheme.silverMist,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 