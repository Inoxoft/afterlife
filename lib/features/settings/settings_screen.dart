import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../providers/characters_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'themed_icon.dart';
import '../../core/widgets/api_key_input_dialog.dart';
import '../../core/utils/env_config.dart';
import '../providers/chat_service.dart';
import '../character_chat/chat_service.dart' as character_chat;
import '../character_interview/chat_service.dart' as character_interview;

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
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, _isDarkModeEnabled);
      await prefs.setBool(_notificationsKey, _isNotificationsEnabled);
      await prefs.setBool(_animationsKey, _isAnimationsEnabled);
      await prefs.setDouble(_fontSizeKey, _chatFontSize);
    } catch (e) {
      print('Error saving settings: $e');
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
                            color: AppTheme.warmGold.withOpacity(0.3),
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
                            'Settings',
                            style: AppTheme.titleStyle.copyWith(fontSize: 28),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Customize your Afterlife experience',
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
                    _buildSectionHeader('Appearance'),
                    _buildSettingCard(
                      title: 'Dark Mode',
                      subtitle:
                          'Enhance your viewing experience in low light conditions(soon)',
                      icon: Icons.dark_mode,
                      trailing: Switch(
                        value: _isDarkModeEnabled,
                        onChanged: (value) {
                          setState(() {
                            _isDarkModeEnabled = value;
                          });
                          _saveSettings();
                        },
                        activeColor: AppTheme.warmGold,
                        activeTrackColor: AppTheme.warmGold.withOpacity(0.5),
                      ),
                    ),

                    _buildSettingCard(
                      title: 'Chat Font Size',
                      subtitle: 'Adjust the text size in chat conversations',
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
                              activeColor: AppTheme.warmGold,
                              inactiveColor: AppTheme.warmGold.withOpacity(0.3),
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
                      title: 'Enable Animations',
                      subtitle:
                          'Toggle interface animations and visual effects',
                      icon: Icons.animation,
                      trailing: Switch(
                        value: _isAnimationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _isAnimationsEnabled = value;
                          });
                          _saveSettings();
                        },
                        activeColor: AppTheme.warmGold,
                        activeTrackColor: AppTheme.warmGold.withOpacity(0.5),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Notifications section
                    _buildSectionHeader('Notifications'),
                    _buildSettingCard(
                      title: 'Enable Notifications',
                      subtitle:
                          'Get notified when your digital twins want to chat',
                      icon: Icons.notifications,
                      trailing: Switch(
                        value: _isNotificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _isNotificationsEnabled = value;
                          });
                          _saveSettings();
                        },
                        activeColor: AppTheme.warmGold,
                        activeTrackColor: AppTheme.warmGold.withOpacity(0.5),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Data management section
                    _buildSectionHeader('Data Management'),
                    _buildSettingCard(
                      title: 'Export All Characters',
                      subtitle: 'Save your digital twins to a file',
                      icon: Icons.download,
                      onTap: () => _exportAllCharacters(context),
                    ),

                    _buildSettingCard(
                      title: 'Clear All Data',
                      subtitle:
                          'Delete all characters and reset app (caution: cannot be undone)',
                      icon: Icons.delete_forever,
                      iconColor: Colors.redAccent,
                      onTap: () => _showClearDataDialog(context),
                    ),

                    const SizedBox(height: 16),

                    // About section
                    _buildSectionHeader('About'),
                    _buildSettingCard(
                      title: 'App Version',
                      subtitle: 'Afterlife v1.0.0',
                      icon: Icons.info_outline,
                    ),

                    _buildSettingCard(
                      title: 'Privacy Policy',
                      subtitle: 'Read how your data is used and protected',
                      icon: Icons.privacy_tip_outlined,
                      onTap: () {
                        // Open privacy policy
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Privacy Policy not available in this version',
                            ),
                            backgroundColor: AppTheme.deepIndigo,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // API & Connectivity section
                    _buildSectionHeader('API & Connectivity'),
                    _buildSettingCard(
                      title: 'Custom OpenRouter API Key',
                      subtitle:
                          'Set or update your personal API key',
                      icon: Icons.vpn_key,
                      onTap: () => _showApiKeyDialog(context),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      child: Text(
                        'Note: The default API key from .env file will be used as a fallback if no custom key is provided.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
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
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.warmGold,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.cinzel(
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
        side: BorderSide(color: AppTheme.warmGold.withOpacity(0.3), width: 1),
      ),
      color: AppTheme.midnightPurple.withOpacity(0.5),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ThemedIcon(
          icon: icon,
          color: iconColor ?? AppTheme.etherealCyan,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: AppTheme.silverMist,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              color: AppTheme.silverMist.withOpacity(0.7),
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
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Clear All Data',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'This will permanently delete all your characters and reset the app to its default state. This action cannot be undone.',
              style: TextStyle(color: Colors.white70),
            ),
            backgroundColor: AppTheme.deepIndigo,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Colors.redAccent.withOpacity(0.5),
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
                        content: Text('All data has been cleared'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error clearing data: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text(
                  'Delete Everything',
                  style: TextStyle(color: Colors.redAccent),
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
        print('API key updated, reinitializing services...');
        EnvConfig.forceReload().then((_) {
          // Force refresh all chat services to use the new key
          // Reinitialize all chat services
          ChatService.initialize();
          character_chat.ChatService.initialize();
          character_interview.ChatService.initialize();
          
          // Force a refresh of API keys in each service
          try {
            ChatService.refreshApiKey();
            character_chat.ChatService.refreshApiKey();
            character_interview.ChatService.refreshApiKey();
          } catch (e) {
            print('Error refreshing API keys: $e');
          }
          
          print('All chat services reinitialized with new API key');

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
}
