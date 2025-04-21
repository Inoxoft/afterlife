import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';
import '../utils/env_config.dart';

/// A dialog that allows users to input their API key manually
class ApiKeyInputDialog extends StatefulWidget {
  final VoidCallback? onKeyUpdated;

  const ApiKeyInputDialog({Key? key, this.onKeyUpdated}) : super(key: key);

  /// Shows the dialog to enter an API key
  static Future<bool> show(
    BuildContext context, {
    VoidCallback? onKeyUpdated,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => ApiKeyInputDialog(onKeyUpdated: onKeyUpdated),
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
  String? _errorText;

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

    if (!apiKey.startsWith('sk-')) {
      setState(() {
        _errorText = 'API key should start with "sk-"';
        _isSubmitting = false;
      });
      return;
    }

    try {
      setState(() => _isSubmitting = true);

      // Save to .env file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/.env');

      await file.writeAsString('OPENROUTER_API_KEY=$apiKey');

      // Re-initialize env config
      await EnvConfig.initialize();

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
      title: const Text(
        'API Key Required',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'The application requires an OpenRouter API key to function. '
            'Please enter your API key below:',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: _isObscured,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.backgroundEnd.withOpacity(0.3),
              hintText: 'Enter API Key (sk-...)',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              errorText: _errorText,
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
                  color: AppTheme.etherealCyan.withOpacity(0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.etherealCyan, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'You can get an API key from openrouter.ai',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : () => _saveApiKey(_controller.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.etherealCyan,
            foregroundColor: Colors.black87,
            disabledBackgroundColor: AppTheme.etherealCyan.withOpacity(0.3),
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
                  : const Text('Save'),
        ),
      ],
    );
  }
}
