import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:afterlife/core/theme/app_theme.dart';
import 'package:afterlife/features/landing_page/landing_screen.dart';
import 'package:afterlife/features/providers/characters_provider.dart';
import 'package:afterlife/features/character_gallery/character_gallery_screen.dart';
import 'package:afterlife/features/character_interview/interview_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/app_router.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env").catchError((e) {
    print("Warning: Failed to load .env file: $e");
    // Continue anyway, we have fallback in ChatService
  });

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style (status bar, navigation bar)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.backgroundEnd,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Run app wrapped in error handler
  runZonedGuarded(
    () async {
      try {
        // Run the app with providers initialized
        runApp(
          MultiProvider(
            providers: [
              // Character storage provider - will auto-load characters in constructor
              ChangeNotifierProvider(create: (_) => CharactersProvider()),
              // Interview provider
              ChangeNotifierProvider(create: (_) => InterviewProvider()),
            ],
            child: const MyApp(),
          ),
        );
      } catch (e, stackTrace) {
        print('Error during app initialization: $e');
        print(stackTrace);
        // Run a minimal app that displays the error
        runApp(
          MaterialApp(
            title: 'Afterlife Error',
            theme: ThemeData.dark(),
            home: Scaffold(
              backgroundColor: AppTheme.backgroundStart,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 60,
                      ),
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
                        'Error: ${e.toString()}',
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          // Try to restart the app
                          SystemNavigator.pop();
                        },
                        child: const Text('Restart App'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    },
    (error, stackTrace) {
      print('Uncaught error: $error');
      print(stackTrace);
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // CharactersProvider is already initialized in its constructor
    // No need to call any initialization method explicitly

    return MaterialApp(
      title: 'Afterlife AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Colors
        colorScheme: AppTheme.colorScheme,

        // App bar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTheme.backgroundStart,
          foregroundColor: Colors.white,
          elevation: 0,
        ),

        // Button themes
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

        // Text themes
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

        // Input decoration
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
      ),
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.landing,
    );
  }
}

// A minimal fallback app to show if something goes wrong during initialization
class FallbackApp extends StatelessWidget {
  const FallbackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Afterlife',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Container(
          color: const Color(0xFF121212),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'AFTERLIFE',
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2.0,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'App initialization error',
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 24),
                CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
