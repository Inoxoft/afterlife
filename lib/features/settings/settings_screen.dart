import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ukrainian_font_utils.dart';
import '../providers/characters_provider.dart';
import '../providers/language_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/env_config.dart';
import '../../../core/widgets/api_key_input_dialog.dart';
import 'themed_icon.dart';
import '../providers/chat_service.dart';
import '../character_chat/chat_service.dart' as character_chat;
import '../character_interview/chat_service.dart' as interview_chat;
import '../developer_chat/developer_chat_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkModeEnabled = true;
  bool _isNotificationsEnabled = true;
  bool _isAnimationsEnabled = true;
  double _chatFontSize = 15.0;

  // We'll use these keys for shared preferences
  static const String _darkModeKey = 'dark_mode_enabled';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _animationsKey = 'animations_enabled';
  static const String _fontSizeKey = 'chat_font_size';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isDarkModeEnabled = prefs.getBool(_darkModeKey) ?? true;
        _isNotificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
        _isAnimationsEnabled = prefs.getBool(_animationsKey) ?? true;
        _chatFontSize = prefs.getDouble(_fontSizeKey) ?? 15.0;
      });
    } catch (e) {}
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, _isDarkModeEnabled);
      await prefs.setBool(_notificationsKey, _isNotificationsEnabled);
      await prefs.setBool(_animationsKey, _isAnimationsEnabled);
      await prefs.setDouble(_fontSizeKey, _chatFontSize);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
              Container(
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

              Expanded(
                child: ListView(
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

                    _buildSettingCard(
                      title: localizations.darkMode,
                      subtitle: localizations.darkModeDescription,
                      icon: Icons.dark_mode,
                      trailing: Switch(
                        value: _isDarkModeEnabled,
                        onChanged: (value) {
                          setState(() {
                            _isDarkModeEnabled = value;
                          });
                          _saveSettings();
                        },
                        thumbColor: MaterialStateProperty.resolveWith<Color?>((
                          states,
                        ) {
                          if (states.contains(MaterialState.selected)) {
                            return AppTheme.warmGold;
                          }
                          return null; // Use default
                        }),
                        trackColor: MaterialStateProperty.resolveWith<Color?>((
                          states,
                        ) {
                          if (states.contains(MaterialState.selected)) {
                            return AppTheme.warmGold.withValues(alpha: 0.5);
                          }
                          return null; // Use default
                        }),
                      ),
                    ),

                    _buildSettingCard(
                      title: localizations.chatFontSize,
                      subtitle: localizations.chatFontSizeDescription,
                      icon: Icons.text_fields,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_chatFontSize.toInt()}',
                            style: TextStyle(
                              color: AppTheme.silverMist,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(
                            width: 150,
                            child: Slider(
                              value: _chatFontSize,
                              min: 12.0,
                              max: 20.0,
                              divisions: 8,
                              thumbColor: AppTheme.warmGold,
                              activeColor: AppTheme.warmGold,
                              inactiveColor: AppTheme.warmGold.withValues(
                                alpha: 0.3,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _chatFontSize = value;
                                });
                              },
                              onChangeEnd: (value) {
                                _saveSettings();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    _buildSettingCard(
                      title: localizations.enableAnimations,
                      subtitle: localizations.enableAnimationsDescription,
                      icon: Icons.animation,
                      trailing: Switch(
                        value: _isAnimationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _isAnimationsEnabled = value;
                          });
                          _saveSettings();
                        },
                        thumbColor: MaterialStateProperty.resolveWith<Color?>((
                          states,
                        ) {
                          if (states.contains(MaterialState.selected)) {
                            return AppTheme.warmGold;
                          }
                          return null; // Use default
                        }),
                        trackColor: MaterialStateProperty.resolveWith<Color?>((
                          states,
                        ) {
                          if (states.contains(MaterialState.selected)) {
                            return AppTheme.warmGold.withValues(alpha: 0.5);
                          }
                          return null; // Use default
                        }),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Notifications section
                    _buildSectionHeader(localizations.notifications),
                    _buildSettingCard(
                      title: localizations.enableNotifications,
                      subtitle: localizations.enableNotificationsDescription,
                      icon: Icons.notifications,
                      trailing: Switch(
                        value: _isNotificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _isNotificationsEnabled = value;
                          });
                          _saveSettings();
                        },
                        thumbColor: MaterialStateProperty.resolveWith<Color?>((
                          states,
                        ) {
                          if (states.contains(MaterialState.selected)) {
                            return AppTheme.warmGold;
                          }
                          return null; // Use default
                        }),
                        trackColor: MaterialStateProperty.resolveWith<Color?>((
                          states,
                        ) {
                          if (states.contains(MaterialState.selected)) {
                            return AppTheme.warmGold.withValues(alpha: 0.5);
                          }
                          return null; // Use default
                        }),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Data management section
                    _buildSectionHeader(localizations.dataManagement),
                    _buildSettingCard(
                      title: localizations.exportAllCharacters,
                      subtitle: localizations.exportAllCharactersDescription,
                      icon: Icons.download,
                      onTap: () => _exportAllCharacters(context),
                    ),

                    _buildSettingCard(
                      title: localizations.clearAllData,
                      subtitle: localizations.clearAllDataDescription,
                      icon: Icons.delete_forever,
                      iconColor: Colors.redAccent,
                      onTap: () => _showClearDataDialog(context),
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
                        // Open privacy policy
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              localizations.privacyPolicyNotAvailable,
                            ),
                            backgroundColor: AppTheme.deepIndigo,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // API & Connectivity section
                    _buildSectionHeader(localizations.apiConnectivity),
                    _buildSettingCard(
                      title: localizations.customApiKey,
                      subtitle: localizations.customApiKeyDescription,
                      icon: Icons.vpn_key,
                      onTap: () => _showApiKeyDialog(context),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 16,
                      ),
                      child: Text(
                        localizations.apiKeyNote,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Developer Chat section
                    _buildSectionHeader(localizations.developerConnection),
                    _buildSettingCard(
                      title: localizations.chatWithDeveloper,
                      subtitle: localizations.chatWithDeveloperDescription,
                      icon: Icons.developer_mode,
                      onTap: () => _navigateToDeveloperChat(context),
                    ),
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

  Future<void> _exportAllCharacters(BuildContext context) async {
    try {
      final charactersProvider = Provider.of<CharactersProvider>(
        context,
        listen: false,
      );

      if (charactersProvider.characters.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("No characters to export"),
            backgroundColor: AppTheme.deepIndigo,
          ),
        );
        return;
      }

      // In a real app, we would implement export functionality here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Exporting ${charactersProvider.characters.length} characters...',
          ),
          backgroundColor: AppTheme.deepIndigo,
        ),
      );

      // Simulate export delay
      await Future.delayed(const Duration(seconds: 2));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Characters exported successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting characters: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();

                    // Reload settings after clearing
                    _loadSettings();

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

  void _navigateToDeveloperChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DeveloperChatScreen()),
    );
  }

  void _showLanguageSelectionDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context);

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
}
