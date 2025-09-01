import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/ukrainian_font_utils.dart';
import '../../core/utils/responsive_utils.dart';
import '../../l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  Future<String> _loadPolicy(BuildContext context) async {
    final localeCode = Localizations.localeOf(context).languageCode;
    final Map<String, String> mapping = {
      'en': 'assets/privacy/privacy_policy_en.md',
      'es': 'assets/privacy/privacy_policy_es.md',
      'fr': 'assets/privacy/privacy_policy_fr.md',
      'de': 'assets/privacy/privacy_policy_de.md',
      'it': 'assets/privacy/privacy_policy_it.md',
      'ja': 'assets/privacy/privacy_policy_ja.md',
      'ko': 'assets/privacy/privacy_policy_ko.md',
      'uk': 'assets/privacy/privacy_policy_uk.md',
      'ru': 'assets/privacy/privacy_policy_ru.md',
    };

    final String fallback = mapping['en']!;
    final String? candidate = mapping[localeCode];

    try {
      if (candidate != null) {
        return await rootBundle.loadString(candidate);
      }
    } catch (_) {}

    return rootBundle.loadString(fallback);
  }

  MarkdownStyleSheet _markdownStyles(BuildContext context) {
    final baseColor = AppTheme.silverMist;
    final titleColor = AppTheme.warmGold;
    final fontScale = ResponsiveUtils.getFontSizeScale(context);

    final base = UkrainianFontUtils.latoWithUkrainianSupport(
      text: 'markdown',
      color: baseColor,
      fontSize: 14 * fontScale,
      height: 1.5,
    );
    final header = UkrainianFontUtils.cinzelWithUkrainianSupport(
      text: 'header',
      color: titleColor,
      fontWeight: FontWeight.bold,
    );

    return MarkdownStyleSheet(
      p: base,
      listBullet: base,
      blockquote: base.copyWith(color: baseColor.withValues(alpha: 0.8)),
      h1: header.copyWith(fontSize: 28 * fontScale),
      h2: header.copyWith(fontSize: 22 * fontScale),
      h3: header.copyWith(fontSize: 18 * fontScale),
      strong: base.copyWith(fontWeight: FontWeight.w700),
      a: base.copyWith(color: AppTheme.etherealCyan),
      code: base.copyWith(
        fontFamily: 'SpaceMono',
        backgroundColor: AppTheme.deepNavy.withValues(alpha: 0.4),
      ),
      blockSpacing: 16,
      listIndent: 24,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final padding = ResponsiveUtils.getScreenPadding(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button
              Container(
                padding: EdgeInsets.fromLTRB(padding.left, 16, padding.right, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.warmGold.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(Icons.arrow_back, color: AppTheme.warmGold, size: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.privacyPolicy,
                            style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                              text: localizations.privacyPolicy,
                              color: AppTheme.warmGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            localizations.privacyPolicyDescription,
                            style: UkrainianFontUtils.latoWithUkrainianSupport(
                              text: localizations.privacyPolicyDescription,
                              color: AppTheme.silverMist.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: FutureBuilder<String>(
                  future: _loadPolicy(context),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppTheme.warmGold),
                      );
                    }

                    return Padding(
                      padding: EdgeInsets.fromLTRB(padding.left, 8, padding.right, 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.midnightPurple.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.warmGold.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Markdown(
                          data: snapshot.data!,
                          selectable: false,
                          styleSheet: _markdownStyles(context),
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                          physics: const BouncingScrollPhysics(),
                          onTapLink: (text, href, title) {},
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


