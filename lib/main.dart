import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:afterlife/core/theme/app_theme.dart';
import 'package:afterlife/features/welcome/welcome_screen.dart';
import 'package:afterlife/features/providers/characters_provider.dart';
import 'package:afterlife/features/character_interview/interview_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/app_router.dart';

class AppInitializationError extends Error {
  final String message;
  AppInitializationError(this.message);
}

Future<void> _initializeApp() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Warning: Failed to load .env file: $e");
    // Continue anyway, we have fallback in ChatService
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.backgroundEnd,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
}

void main() {
  runZonedGuarded(
    () async {
      try {
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
      title: 'Afterlife AI',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const WelcomeScreen(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      colorScheme: AppTheme.colorScheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTheme.backgroundStart,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.etherealCyan,
          foregroundColor: Colors.black87,
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.white.withOpacity(0.1),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
      ),
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
