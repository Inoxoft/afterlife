import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../core/services/preferences_service.dart';
import '../../../core/utils/ukrainian_font_utils.dart';
import '../../../core/services/onboarding_service.dart';
import '../providers/characters_provider.dart';
import '../providers/language_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/env_config.dart';
import '../../../core/widgets/api_key_input_dialog.dart';
import 'themed_icon.dart';
import '../providers/chat_service.dart';
import '../character_chat/chat_service.dart' as character_chat;
import '../character_interview/chat_service.dart' as interview_chat;

import 'local_llm_settings_screen.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  // Remove the _chatFontSize variable and _fontSizeKey
  // Remove all code related to chat font size loading, saving, and UI
  // Remove the _buildSettingCard for chatFontSize

  // Scroll + header animation for smooth hide-on-scroll behavior
  late final ScrollController _scrollController;
  late final AnimationController _headerAnimationController;
  late final Animation<double> _headerOpacityAnimation;
  late final Animation<double> _headerHeightAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize scroll + header animation
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _headerOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _headerHeightAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    const double hideRange = 120.0;
    final double clampedOffset = _scrollController.offset.clamp(0.0, hideRange);
    final double targetValue = (clampedOffset / hideRange).clamp(0.0, 1.0);
    _headerAnimationController.animateTo(
      targetValue,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  // Remove the _loadSettings() function
  // Remove the _saveSettings() function

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Settings header with back button
              AnimatedBuilder(
                animation: _headerAnimationController,
                builder: (context, child) {
                  return ClipRect(
                    child: SizeTransition(
                      sizeFactor: _headerHeightAnimation,
                      axisAlignment: -1.0,
                      child: FadeTransition(
                        opacity: _headerOpacityAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          width: double.infinity,
                          child: Row(
                            children: [
                              // Back button with themed styling
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
                                  child: Icon(
                                    Icons.arrow_back,
                                    color: AppTheme.warmGold,
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Title and subtitle
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      localizations.settings,
                                      style: AppTheme.titleStyle.copyWith(fontSize: 28),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      localizations.settingsDescription,
                                      style: AppTheme.captionStyle,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Appearance section
                    _buildSectionHeader(localizations.appearance),

                    // Language selection
                    Consumer<LanguageProvider>(
                      builder: (context, languageProvider, child) {
                        return _buildSettingCard(
                          title: localizations.language,
                          subtitle: localizations.languageDescription,
                          icon: Icons.language,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                languageProvider.currentLanguageName,
                                style: TextStyle(
                                  color: AppTheme.silverMist,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: AppTheme.silverMist,
                                size: 16,
                              ),
                            ],
                          ),
                          onTap: () => _showLanguageSelectionDialog(context),
                        );
                      },
                    ),

                    // Remove the _buildSettingCard for chatFontSize
                    const SizedBox(height: 16),

                    // Data management section
                    _buildSectionHeader(localizations.dataManagement),

                    _buildSettingCard(
                      title: localizations.clearAllData,
                      subtitle: localizations.clearAllDataDescription,
                      icon: Icons.delete_forever,
                      iconColor: Colors.redAccent,
                      onTap: () => _showClearDataDialog(context),
                    ),

                    _buildSettingCard(
                      title: 'Reset Onboarding',
                      subtitle:
                          'Show the onboarding tutorial again on next app start',
                      icon: Icons.refresh,
                      iconColor: Colors.orangeAccent,
                      onTap: () => _showResetOnboardingDialog(context),
                    ),

                    const SizedBox(height: 16),

                    // About section
                    _buildSectionHeader(localizations.about),
                    _buildSettingCard(
                      title: localizations.appVersion,
                      subtitle: 'Afterlife v1.0.0',
                      icon: Icons.info_outline,
                    ),

                    _buildSettingCard(
                      title: localizations.privacyPolicy,
                      subtitle: localizations.privacyPolicyDescription,
                      icon: Icons.privacy_tip_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // API & Connectivity section
                    _buildSectionHeader(localizations.apiConnectivity),
                    _buildSettingCard(
                      title: 'OpenRouter API Key',
                      subtitle: localizations.customApiKeyDescription,
                      icon: Icons.vpn_key,
                      onTap: () => _showApiKeyDialog(context),
                    ),

                    _buildSettingCard(
                      title: localizations.localAiSettings,
                      subtitle: localizations.localAiSettingsDescription,
                      icon: Icons.offline_bolt,
                      onTap: () => _navigateToLocalLLMSettings(context),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.warmGold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: UkrainianFontUtils.cinzelWithUkrainianSupport(
              text: title,
              color: AppTheme.warmGold,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.warmGold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      color: AppTheme.midnightPurple.withValues(alpha: 0.5),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ThemedIcon(
          icon: icon,
          color: iconColor ?? AppTheme.etherealCyan,
        ),
        title: Text(
          title,
          style: UkrainianFontUtils.latoWithUkrainianSupport(
            text: title,
            color: AppTheme.silverMist,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: UkrainianFontUtils.latoWithUkrainianSupport(
              text: subtitle,
              color: AppTheme.silverMist.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              localizations.clearAllData,
              style: UkrainianFontUtils.latoWithUkrainianSupport(
                text: localizations.clearAllData,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              localizations.clearAllDataConfirmation,
              style: UkrainianFontUtils.latoWithUkrainianSupport(
                text: localizations.clearAllDataConfirmation,
                color: Colors.white70,
              ),
            ),
            backgroundColor: AppTheme.deepIndigo,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Colors.redAccent.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  localizations.cancel,
                  style: UkrainianFontUtils.latoWithUkrainianSupport(
                    text: localizations.cancel,
                    color: AppTheme.silverMist,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    final charactersProvider = Provider.of<CharactersProvider>(
                      context,
                      listen: false,
                    );
                    await charactersProvider.clearAll();

                    // Also clear settings
                    final prefs = await PreferencesService.getPrefs();
                    await prefs.clear();

                    // Reload settings after clearing
                    // _loadSettings(); // This line is removed

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(localizations.dataCleared),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(localizations.errorClearingData),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text(
                  localizations.deleteEverything,
                  style: UkrainianFontUtils.latoWithUkrainianSupport(
                    text: localizations.deleteEverything,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showResetOnboardingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Reset Onboarding',
              style: UkrainianFontUtils.latoWithUkrainianSupport(
                text: 'Reset Onboarding',
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'This will reset the onboarding status and show the tutorial again on next app start. Continue?',
              style: UkrainianFontUtils.latoWithUkrainianSupport(
                text:
                    'This will reset the onboarding status and show the tutorial again on next app start. Continue?',
                color: Colors.white70,
              ),
            ),
            backgroundColor: AppTheme.deepIndigo,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Colors.orangeAccent.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: UkrainianFontUtils.latoWithUkrainianSupport(
                    text: 'Cancel',
                    color: AppTheme.silverMist,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await OnboardingService.resetOnboarding();
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Onboarding reset successfully! Tutorial will show on next app start.',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Error resetting onboarding. Please try again.',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text(
                  'Reset',
                  style: UkrainianFontUtils.latoWithUkrainianSupport(
                    text: 'Reset',
                    color: Colors.orangeAccent,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showApiKeyDialog(BuildContext context) async {
    // Add diagnostic logging to see what's happening with the API key
    await EnvConfig.dumpApiKeyInfo();

    bool apiKeyUpdated = await ApiKeyInputDialog.show(
      context,
      isFromSettings: true,
      onKeyUpdated: () {
        // Re-initialize env config and all services that use the API key
        EnvConfig.forceReload().then((_) {
          // Force refresh all chat services to use the new key
          // Reinitialize all chat services
          ChatService.initialize();
          character_chat.ChatService.initialize();
          interview_chat.ChatService.initialize();

          // Force a refresh of API keys in each service
          try {
            ChatService.refreshApiKey();
            character_chat.ChatService.refreshApiKey();
            interview_chat.ChatService.refreshApiKey();
          } catch (e) {}

          // Dump diagnostics after updating
          EnvConfig.dumpApiKeyInfo();
        });
      },
    );

    if (apiKeyUpdated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API key updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showLanguageSelectionDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    final languages = [
      {'code': 'en', 'name': localizations.languageEnglish},
      {'code': 'es', 'name': localizations.languageSpanish},
      {'code': 'fr', 'name': localizations.languageFrench},
      {'code': 'de', 'name': localizations.languageGerman},
      {'code': 'it', 'name': localizations.languageItalian},
      {'code': 'ja', 'name': localizations.languageJapanese},
      {'code': 'ko', 'name': localizations.languageKorean},
      {'code': 'uk', 'name': localizations.languageUkrainian},
      {'code': 'ru', 'name': localizations.languageRussian},
    ];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Select Language',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final language = languages[index];
                  final languageProvider = Provider.of<LanguageProvider>(
                    context,
                    listen: false,
                  );
                  final isSelected =
                      languageProvider.currentLanguageCode == language['code'];

                  return ListTile(
                    title: Text(
                      language['name']!,
                      style: TextStyle(
                        color: isSelected ? AppTheme.warmGold : Colors.white,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing:
                        isSelected
                            ? Icon(Icons.check, color: AppTheme.warmGold)
                            : null,
                    onTap: () {
                      languageProvider.setLanguage(language['code']!);
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Language changed to ${language['name']}',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            backgroundColor: AppTheme.deepIndigo,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: AppTheme.warmGold.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.silverMist),
                ),
              ),
            ],
          ),
    );
  }

  void _navigateToLocalLLMSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocalLLMSettingsScreen()),
    );
  }
}
