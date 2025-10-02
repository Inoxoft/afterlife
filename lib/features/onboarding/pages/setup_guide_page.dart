import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/ukrainian_font_utils.dart';
import '../../../core/widgets/api_key_input_dialog.dart';
import 'dart:io' show Platform;
import '../../settings/local_llm_settings_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SetupGuidePage extends StatelessWidget {
  final AnimationController animationController;

  const SetupGuidePage({super.key, required this.animationController});

  void _showApiKeyDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await ApiKeyInputDialog.show(
      context,
      isFromSettings: false,
      onKeyUpdated: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.apiKeySavedCanChat),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  void _navigateToLocalLLMSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocalLLMSettingsScreen()),
    );
  }

  Future<void> _openOpenRouterLink(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final uri = Uri.parse('https://openrouter.ai/keys');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // If all else fails, show a message with the URL
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseOpenBrowserVisit),
          backgroundColor: AppTheme.warmGold,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'OK',
            textColor: AppTheme.midnightPurple,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Create staggered animations
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
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
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
                      Text(
                        l10n.gettingStarted,
                        textAlign: TextAlign.center,
                        style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                          text: l10n.gettingStarted,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3.0,
                          color: AppTheme.silverMist,
                          shadows: [
                            Shadow(
                              blurRadius: 10.0,
                              color: AppTheme.warmGold.withValues(alpha: 0.8),
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.chooseYourAiExperience,
                        textAlign: TextAlign.center,
                        style: UkrainianFontUtils.latoWithUkrainianSupport(
                          text: l10n.chooseYourAiExperience,
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: AppTheme.silverMist.withValues(alpha: 0.9),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Content cards
              SlideTransition(
                position: contentAnimation,
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animationController,
                    curve: const Interval(0.2, 0.9),
                  ),
                  child: Column(
                    children: [
                      // Local/On-device option (iOS shows Apple Intelligence marketing)
                      _buildOptionCard(
                        context,
                        title: Platform.isIOS ? l10n.appleIntelligenceTitle : l10n.localAiModel,
                        subtitle: Platform.isIOS ? l10n.appleIntelligenceSubtitle : l10n.privateWorksOffline,
                        icon: Icons.offline_bolt,
                        isHighlighted: true,
                        features: Platform.isIOS
                            ? [
                                l10n.appleOnDevicePrivacy,
                                l10n.appleNoCloudCalls,
                                l10n.applePoweredByFoundationModels,
                                l10n.appleInstantSetup,
                              ]
                            : [
                                l10n.completePrivacyDataStaysLocal,
                                l10n.worksWithoutInternet,
                                l10n.hammerModelSize,
                                l10n.optimizedForMobileDevices,
                              ],
                        actionText: Platform.isIOS ? l10n.getStarted : l10n.downloadModel,
                        onTap: () {
                          if (Platform.isIOS) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.applePrivacyNote),
                                backgroundColor: AppTheme.warmGold,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          } else {
                            _navigateToLocalLLMSettings(context);
                          }
                        },
                        infoWidget: Text(
                          Platform.isIOS
                              ? l10n.applePrivacyNote
                              : l10n.freeDownloadNoAccountRequired,
                          style: TextStyle(
                            color: AppTheme.silverMist.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Cloud AI Option hidden on iOS
                      if (!Platform.isIOS)
                        _buildOptionCard(
                          context,
                          title: l10n.cloudAiModels,
                          subtitle: l10n.bestQualityRequiresInternet,
                          icon: Icons.cloud,
                          isHighlighted: false,
                          features: [
                            'Access to GPT-5, Claude, and more',
                            l10n.advancedReasoningAndKnowledge,
                            l10n.alwaysUpToDateInformation,
                            l10n.fastResponses,
                          ],
                          actionText: l10n.setUpApiKey,
                          onTap: () => _showApiKeyDialog(context),
                          infoWidget: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Bring your own key: ',
                                  style: TextStyle(
                                    color: AppTheme.silverMist.withValues(alpha: 0.8),
                                    fontSize: 12,
                                  ),
                                ),
                                TextSpan(
                                  text: 'openrouter.ai/keys',
                                  style: TextStyle(
                                    color: AppTheme.warmGold,
                                    fontSize: 12,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  recognizer: TapGestureRecognizer()..onTap = () => _openOpenRouterLink(context),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Both options info (hide on iOS where only Apple Intelligence is shown)
                      if (!Platform.isIOS)
                        Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.deepIndigo.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.etherealCyan.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppTheme.etherealCyan,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.youCanUseBoth,
                                  style:
                                      UkrainianFontUtils.latoWithUkrainianSupport(
                                        text: l10n.youCanUseBoth,
                                        color: AppTheme.etherealCyan,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.setBothOptionsAutoChoose,
                              style:
                                  UkrainianFontUtils.latoWithUkrainianSupport(
                                    text: l10n.setBothOptionsAutoChoose,
                                    color: AppTheme.silverMist.withValues(
                                      alpha: 0.9,
                                    ),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Skip for now info (hide on iOS)
                      if (!Platform.isIOS)
                        Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.midnightPurple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.silverMist.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: AppTheme.warmGold.withValues(alpha: 0.8),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                  l10n.canSetupLaterInSettings,
                                style:
                                    UkrainianFontUtils.latoWithUkrainianSupport(
                                      text: l10n.canSetupLaterInSettings,
                                      color: AppTheme.silverMist.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 12,
                                      height: 1.3,
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

              // Extra bottom padding to avoid overlap with navigation buttons
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isHighlighted,
    required List<String> features,
    required String actionText,
    required VoidCallback onTap,
    required Widget infoWidget,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            isHighlighted
                ? AppTheme.midnightPurple.withValues(alpha: 0.4)
                : AppTheme.midnightPurple.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isHighlighted
                  ? AppTheme.warmGold.withValues(alpha: 0.4)
                  : AppTheme.silverMist.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow:
            isHighlighted
                ? [
                  BoxShadow(
                    color: AppTheme.warmGold.withValues(alpha: 0.1),
                    blurRadius: 15,
                    spreadRadius: 0,
                  ),
                ]
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.midnightPurple.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.warmGold.withValues(alpha: 0.15),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color:
                      isHighlighted ? AppTheme.warmGold : AppTheme.etherealCyan,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                        text: title,
                        color: AppTheme.silverMist,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: UkrainianFontUtils.latoWithUkrainianSupport(
                        text: subtitle,
                        color: AppTheme.silverMist.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Features list
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          isHighlighted
                              ? AppTheme.warmGold
                              : AppTheme.etherealCyan,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      feature,
                      style: UkrainianFontUtils.latoWithUkrainianSupport(
                        text: feature,
                        color: AppTheme.silverMist.withValues(alpha: 0.9),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Info widget
          infoWidget,

          const SizedBox(height: 16),

          // On iOS, we don't need an action button (Apple Intelligence is default)
          if (!Platform.isIOS)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isHighlighted ? AppTheme.warmGold : AppTheme.etherealCyan,
                  foregroundColor: AppTheme.midnightPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  shadowColor: (isHighlighted
                          ? AppTheme.warmGold
                          : AppTheme.etherealCyan)
                      .withValues(alpha: 0.3),
                ),
                child: Text(
                  actionText,
                  style: UkrainianFontUtils.latoWithUkrainianSupport(
                    text: actionText,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
