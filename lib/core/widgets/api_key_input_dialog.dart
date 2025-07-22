import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../utils/env_config.dart';

/// A dialog that allows users to input their API key manually
class ApiKeyInputDialog extends StatefulWidget {
  final VoidCallback? onKeyUpdated;
  final bool isFromSettings;

  const ApiKeyInputDialog({
    Key? key,
    this.onKeyUpdated,
    this.isFromSettings = false,
  }) : super(key: key);

  /// Shows the dialog to enter an API key
  static Future<bool> show(
    BuildContext context, {
    VoidCallback? onKeyUpdated,
    bool isFromSettings = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: isFromSettings,
          builder:
              (context) => ApiKeyInputDialog(
                onKeyUpdated: onKeyUpdated,
                isFromSettings: isFromSettings,
              ),
        ) ??
        false;
  }

  @override
  State<ApiKeyInputDialog> createState() => _ApiKeyInputDialogState();
}

class _ApiKeyInputDialogState extends State<ApiKeyInputDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isObscured = true;
  bool _isSubmitting = false;
  bool _isLoading = true;
  String? _errorText;
  String? _currentKey;

  @override
  void initState() {
    super.initState();
    _loadCurrentApiKey();
  }

  Future<void> _loadCurrentApiKey() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Make sure environment is initialized
      await EnvConfig.initialize();

      _currentKey = EnvConfig.get('OPENROUTER_API_KEY');

      // Don't display placeholder as a real key
      if (_currentKey == 'your_api_key_here') {
        _currentKey = null;
      }

      // If we have a key, pre-fill part of it
      if (_currentKey != null && _currentKey!.isNotEmpty) {
        // Only show first 4 and last 4 characters of the API key
        final maskedKey =
            _currentKey!.length > 8
                ? '${_currentKey!.substring(0, 4)}...${_currentKey!.substring(_currentKey!.length - 4)}'
                : '****';
        _controller.text = maskedKey;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveApiKey(String apiKey) async {
    if (apiKey.trim().isEmpty) {
      setState(() {
        _errorText = 'API key cannot be empty';
        _isSubmitting = false;
      });
      return;
    }

    // Skip validation if the field contains masked key (user didn't change it)
    bool skipValidation = apiKey.contains('...');

    // Only validate format if it's a new key (not masked)
    if (!skipValidation && !apiKey.startsWith('sk-')) {
      setState(() {
        _errorText = 'API key should start with "sk-"';
        _isSubmitting = false;
      });
      return;
    }

    try {
      setState(() => _isSubmitting = true);

      // If the input contains the masked key, don't update it
      if (skipValidation) {
        // No changes to save, but consider it a successful close if from settings
        if (widget.isFromSettings) {
          Navigator.of(context).pop(false);
        }
        return;
      }

      // Instead of writing to .env file, save to SharedPreferences
      final success = await EnvConfig.setUserApiKey(apiKey);

      if (!success) {
        throw Exception('Failed to save API key to preferences');
      }

      // Re-initialize env config with force reload
      await EnvConfig.forceReload();

      // Verify the key was properly saved
      final savedKey = EnvConfig.get('OPENROUTER_API_KEY');
      print(
        'Verification - Retrieved key: ${savedKey != null ? '${savedKey.substring(0, 4)}...' : 'null'}',
      );

      if (savedKey != apiKey) {
        print('Warning: Saved key does not match input key');
      }

      // Call the callback if provided
      if (widget.onKeyUpdated != null) {
        widget.onKeyUpdated!();
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorText = 'Error saving API key: $e';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.deepIndigo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.warmGold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      title: Text(
        widget.isFromSettings ? 'OpenRouter API Key' : 'API Key Required',
        style: const TextStyle(color: Colors.white),
      ),
      content:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.warmGold),
                ),
              )
              : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isFromSettings
                        ? 'Update your OpenRouter API key for AI functionality:'
                        : 'The application requires an OpenRouter API key to function. '
                            'Please enter your API key below:',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    obscureText: _isObscured,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.midnightPurple.withValues(alpha: 0.3),
                      hintText: 'Enter API Key (sk-...)',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      errorText: _errorText,
                      prefixIcon:
                          widget.isFromSettings && _currentKey != null
                              ? IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                tooltip: 'Clear current key',
                                onPressed: () async {
                                  setState(() {
                                    _controller.text = '';
                                    // Clear current key reference so we don't trigger mask validation
                                    _currentKey = null;
                                    // Show loading while we update the input field
                                    _isLoading = true;
                                  });

                                  try {
                                    // Use the new removeUserApiKey method
                                    await EnvConfig.removeUserApiKey();

                                    // Reinitialize config to reflect changes with force reload
                                    await EnvConfig.forceReload();

                                    if (widget.onKeyUpdated != null) {
                                      widget.onKeyUpdated!();
                                    }
                                  } catch (e) {
                                  } finally {
                                    if (mounted) {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                    }
                                  }
                                },
                              )
                              : null,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscured ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            _isObscured = !_isObscured;
                          });
                        },
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppTheme.warmGold.withValues(alpha: 0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppTheme.warmGold,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  if (widget.isFromSettings && _currentKey != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 12,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'To replace with a different key, clear the field first and enter new key',
                              style: TextStyle(
                                color: Colors.amber.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.warmGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.warmGold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 16,
                              color: AppTheme.warmGold,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'How to get your API key:',
                              style: TextStyle(
                                color: AppTheme.warmGold,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '1. Visit openrouter.ai and sign up/login',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '2. Go to "Keys" section in your dashboard',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '3. Create a new API key',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final uri = Uri.parse('https://openrouter.ai/keys');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '→ Get your API key here: ',
                                  style: TextStyle(
                                    color: Colors.white70,
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
                                  recognizer:
                                      TapGestureRecognizer()
                                        ..onTap = () async {
                                          final uri = Uri.parse(
                                            'https://openrouter.ai/keys',
                                          );
                                          if (await canLaunchUrl(uri)) {
                                            await launchUrl(
                                              uri,
                                              mode:
                                                  LaunchMode
                                                      .externalApplication,
                                            );
                                          }
                                        },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Show API key source indicator if we have a key
                  if (_currentKey != null && _currentKey!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 14,
                            color: Colors.green.shade300,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Using your custom API key',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade300,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      actions: [
        TextButton(
          onPressed:
              _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: Text(
            widget.isFromSettings ? 'Cancel' : 'Skip for now',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        if (widget.isFromSettings && _currentKey != null)
          TextButton(
            onPressed:
                _isSubmitting
                    ? null
                    : () async {
                      setState(() => _isSubmitting = true);

                      try {
                        // Use the new removeUserApiKey method
                        final success = await EnvConfig.removeUserApiKey();
                        if (!success) {
                          throw Exception('Failed to remove API key');
                        }

                        // Re-initialize env config with force reload
                        await EnvConfig.forceReload();

                        // Call the callback if provided
                        if (widget.onKeyUpdated != null) {
                          widget.onKeyUpdated!();
                        }

                        if (mounted) {
                          Navigator.of(context).pop(true);
                        }
                      } catch (e) {
                        setState(() {
                          _errorText = 'Error removing API key: $e';
                          _isSubmitting = false;
                        });
                      }
                    },
            child: Text(
              'Remove Key',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : () => _saveApiKey(_controller.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.warmGold,
            foregroundColor: Colors.black87,
            disabledBackgroundColor: AppTheme.warmGold.withValues(alpha: 0.3),
          ),
          child:
              _isSubmitting
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
                    ),
                  )
                  : Text(
                    widget.isFromSettings && _currentKey != null
                        ? 'Update Key'
                        : 'Save Key',
                  ),
        ),
      ],
    );
  }
}
