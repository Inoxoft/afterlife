import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/env_config.dart';
import 'core/utils/app_optimizer.dart';
import 'features/providers/characters_provider.dart';
import 'features/character_interview/interview_provider.dart';
import 'features/splash/splash_screen.dart';
import 'features/character_interview/chat_service.dart' as interview_chat;
import 'features/providers/chat_service.dart' as providers_chat;
import 'features/character_prompts/famous_character_prompts.dart';

class AppInitializationError extends Error {
  final String message;
  AppInitializationError(this.message);
}

Future<void> _initializeApp() async {
  // Initialize all app optimizations
  await AppOptimizer.initializeApp();

  // Initialize environment configuration
  try {
    await EnvConfig.initialize();
    print("Environment configuration initialized successfully");
  } catch (e) {
    print("Error initializing environment configuration: $e");
  }

  // Initialize services
  try {
    // Initialize character interview chat service
    await interview_chat.ChatService.initialize();
    interview_chat.ChatService.logDiagnostics();

    // Initialize providers chat service (if available)
    if (const bool.fromEnvironment(
      'USE_PROVIDER_CHAT_SERVICE',
      defaultValue: false,
    )) {
      await providers_chat.ChatService.initialize();
      providers_chat.ChatService.logDiagnostics();
    }

    // Initialize and clean famous character prompts
    FamousCharacterPrompts.initialize();
  } catch (e) {
    print("Error initializing services: $e");
  }
}

Future<void> main() async {
  runZonedGuarded(
    () async {
      try {
        // We only need to initialize the app once
        await _initializeApp();

        runApp(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => CharactersProvider()),
              ChangeNotifierProvider(create: (_) => InterviewProvider()),
            ],
            child: const MyApp(),
          ),
        );
      } catch (e, stackTrace) {
        print('Error during app initialization: $e');
        print(stackTrace);
        runApp(const ErrorApp(error: 'Initialization Error'));
      }
    },
    (error, stackTrace) {
      print('Uncaught error: $error');
      print(stackTrace);
      runApp(ErrorApp(error: error.toString()));
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Afterlife',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppTheme.etherealCyan,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.etherealCyan,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppTheme.backgroundStart,
        dialogTheme: DialogThemeData(
          backgroundColor: AppTheme.deepIndigo,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppTheme.deepIndigo,
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      home: const SplashScreen(), // Use the splash screen as the home screen
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Afterlife Error',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: AppTheme.backgroundStart,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                const Text(
                  'Initialization Error',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  error,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => SystemNavigator.pop(),
                  child: const Text('Restart App'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
