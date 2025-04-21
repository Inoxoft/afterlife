import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';

/// A utility class for managing environment configuration
class EnvConfig {
  static bool _isInitialized = false;
  static final Map<String, String> _envVars = {};

  /// Initialize environment configuration
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Try to load using dotenv first
      bool dotenvLoaded = false;
      try {
        await dotenv.load();
        dotenvLoaded = true;
        print('Dotenv loaded successfully');
      } catch (e) {
        print('Error loading .env using dotenv: $e');
      }

      // If dotenv loaded successfully, copy values to our map
      if (dotenvLoaded) {
        dotenv.env.forEach((key, value) {
          _envVars[key] = value;
        });
      }

      // If we don't have any env vars yet, try manual file loading
      if (_envVars.isEmpty) {
        await _loadEnvManually();
      }

      _isInitialized = true;
      _logLoadedVars();
    } catch (e) {
      print('Error initializing environment: $e');
      _isInitialized = true; // Mark as initialized to prevent repeated attempts
    }
  }

  /// Get an environment variable value
  static String? get(String key) {
    if (!_isInitialized) {
      print('Warning: EnvConfig not initialized before access');
    }
    return _envVars[key];
  }

  /// Check if a key exists and has a non-empty value
  static bool hasValue(String key) {
    final value = get(key);
    return value != null && value.isNotEmpty;
  }

  /// Create a .env file with sample values if it doesn't exist
  static Future<void> createSampleEnvFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/.env');

      if (!file.existsSync()) {
        await file.writeAsString('''
# Afterlife API Configuration
# Replace with your actual API key from https://openrouter.ai
OPENROUTER_API_KEY=your_api_key_here
''');
        print('Created sample .env file at ${file.path}');
      }
    } catch (e) {
      print('Error creating sample .env file: $e');
    }
  }

  /// Load environment variables manually from assets or file system
  static Future<void> _loadEnvManually() async {
    // Try to load from assets bundle
    try {
      final envString = await rootBundle.loadString('.env');
      _parseEnvString(envString);
      print('Loaded .env from assets');
      return;
    } catch (e) {
      print('Could not load .env from assets: $e');
    }

    // Try to load from app documents directory
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/.env');

      if (file.existsSync()) {
        final envString = await file.readAsString();
        _parseEnvString(envString);
        print('Loaded .env from ${file.path}');
        return;
      }
    } catch (e) {
      print('Could not load .env from file system: $e');
    }

    print('No .env file found. Creating sample file...');
    await createSampleEnvFile();
  }

  /// Parse environment variables from a string
  static void _parseEnvString(String envString) {
    final envLines = envString.split('\n');

    for (final line in envLines) {
      // Skip comments and empty lines
      if (line.trim().startsWith('#') || line.trim().isEmpty) continue;

      // Parse key=value format
      final parts = line.split('=');
      if (parts.length >= 2) {
        final key = parts[0].trim();
        final value = parts.sublist(1).join('=').trim();
        _envVars[key] = value;
      }
    }
  }

  /// Log loaded environment variables (with obfuscation for sensitive data)
  static void _logLoadedVars() {
    print('=== Environment Variables ===');
    _envVars.forEach((key, value) {
      if (key.toLowerCase().contains('key') ||
          key.toLowerCase().contains('secret') ||
          key.toLowerCase().contains('password')) {
        // Mask sensitive values
        final masked =
            value.length > 8
                ? '${value.substring(0, 4)}...${value.substring(value.length - 4)}'
                : '****';
        print('$key: $masked');
      } else {
        print('$key: $value');
      }
    });
    print('============================');
  }
}
