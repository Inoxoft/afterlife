import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:afterlife/core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoSaveChats = true;
  bool _darkMode = true;
  String _apiKeyStatus = 'Not set';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _autoSaveChats = prefs.getBool('autoSaveChats') ?? true;
        _darkMode = prefs.getBool('darkMode') ?? true;
        final apiKey = prefs.getString('apiKey');
        _apiKeyStatus = apiKey != null && apiKey.isNotEmpty ? 'Set' : 'Not set';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoSaveChats', _autoSaveChats);
    await prefs.setBool('darkMode', _darkMode);
  }

  void _showApiKeyDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.deepIndigo,
          title: const Text('API Key', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter your API key',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('apiKey', controller.text);
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                setState(() {
                  _apiKeyStatus =
                      controller.text.isNotEmpty ? 'Set' : 'Not set';
                });
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.backgroundStart,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // General Settings Section
                    _buildSectionHeader('General'),
                    SwitchListTile(
                      title: const Text(
                        'Auto-save Chats',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Automatically save your conversations',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      value: _autoSaveChats,
                      onChanged: (value) {
                        setState(() {
                          _autoSaveChats = value;
                        });
                        _saveSettings();
                      },
                      activeColor: Colors.white,
                      activeTrackColor: Colors.white.withOpacity(0.5),
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: Colors.grey.withOpacity(0.5),
                    ),
                    SwitchListTile(
                      title: const Text(
                        'Dark Mode',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Toggle between light and dark themes',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      value: _darkMode,
                      onChanged: (value) {
                        setState(() {
                          _darkMode = value;
                        });
                        _saveSettings();
                      },
                      activeColor: Colors.white,
                      activeTrackColor: Colors.white.withOpacity(0.5),
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: Colors.grey.withOpacity(0.5),
                    ),
                    const Divider(color: Colors.white24),

                    // API Settings Section
                    _buildSectionHeader('API Settings'),
                    ListTile(
                      title: const Text(
                        'API Key',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Status: $_apiKeyStatus',
                        style: TextStyle(
                          color:
                              _apiKeyStatus == 'Set'
                                  ? Colors.green[300]
                                  : Colors.orange[300],
                          fontSize: 12,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: _showApiKeyDialog,
                      ),
                    ),
                    const Divider(color: Colors.white24),

                    // About Section
                    _buildSectionHeader('About'),
                    ListTile(
                      title: const Text(
                        'Version',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        '1.0.0',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                    ListTile(
                      title: const Text(
                        'Privacy Policy',
                        style: TextStyle(color: Colors.white),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white54,
                        size: 16,
                      ),
                      onTap: () {
                        // Navigate to privacy policy
                      },
                    ),
                    ListTile(
                      title: const Text(
                        'Terms of Service',
                        style: TextStyle(color: Colors.white),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white54,
                        size: 16,
                      ),
                      onTap: () {
                        // Navigate to terms of service
                      },
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
