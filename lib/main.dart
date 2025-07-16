import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/env_config.dart';
import 'core/utils/app_optimizer.dart';
import 'features/providers/characters_provider.dart';
import 'features/providers/language_provider.dart';
import 'features/splash/splash_screen.dart';
import 'features/character_interview/chat_service.dart' as interview_chat;
import 'features/providers/chat_service.dart' as providers_chat;
import 'features/character_prompts/famous_character_prompts.dart';
import 'l10n/app_localizations.dart';
import 'core/services/hybrid_chat_service.dart';
import 'core/utils/ukrainian_font_utils.dart';

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
  } catch (e) {
  }

  // Initialize services
  try {
    // Initialize hybrid chat service (this will initialize LocalLLMService)
    await HybridChatService.initialize();
    
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
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the hybrid chat service
  await HybridChatService.initialize();
  
  runZonedGuarded(
    () async {
      try {
        // We only need to initialize the app once
        await _initializeApp();

        runApp(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => CharactersProvider()),
              ChangeNotifierProvider(create: (_) => LanguageProvider()),
            ],
            child: const MyApp(),
          ),
        );
      } catch (e, stackTrace) {
        runApp(const ErrorApp(error: 'Initialization Error'));
      }
    },
    (error, stackTrace) {
      runApp(ErrorApp(error: error.toString()));
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize language on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LanguageProvider>().initializeLanguage();
    });
  }

  /// Creates a TextTheme with Cyrillic font support (Ukrainian and Russian)
  TextTheme _buildTextThemeWithUkrainianSupport(TextTheme baseTheme) {
    // Get platform-appropriate font fallbacks for Cyrillic text
    final fontFallbacks = UkrainianFontUtils.getMobileFontFallbacks();
    final serifFontFallbacks = UkrainianFontUtils.getMobileSerifFontFallbacks();
    
    return baseTheme.copyWith(
      // Display styles (large text)
      displayLarge: baseTheme.displayLarge?.copyWith(
        fontFamilyFallback: serifFontFallbacks,
      ),
      displayMedium: baseTheme.displayMedium?.copyWith(
        fontFamilyFallback: serifFontFallbacks,
      ),
      displaySmall: baseTheme.displaySmall?.copyWith(
        fontFamilyFallback: serifFontFallbacks,
      ),
      
      // Headline styles
      headlineLarge: baseTheme.headlineLarge?.copyWith(
        fontFamilyFallback: serifFontFallbacks,
      ),
      headlineMedium: baseTheme.headlineMedium?.copyWith(
        fontFamilyFallback: serifFontFallbacks,
      ),
      headlineSmall: baseTheme.headlineSmall?.copyWith(
        fontFamilyFallback: serifFontFallbacks,
      ),
      
      // Title styles
      titleLarge: baseTheme.titleLarge?.copyWith(
        fontFamilyFallback: serifFontFallbacks,
      ),
      titleMedium: baseTheme.titleMedium?.copyWith(
        fontFamilyFallback: fontFallbacks,
      ),
      titleSmall: baseTheme.titleSmall?.copyWith(
        fontFamilyFallback: fontFallbacks,
      ),
      
      // Body text styles
      bodyLarge: baseTheme.bodyLarge?.copyWith(
        fontFamilyFallback: fontFallbacks,
      ),
      bodyMedium: baseTheme.bodyMedium?.copyWith(
        fontFamilyFallback: fontFallbacks,
      ),
      bodySmall: baseTheme.bodySmall?.copyWith(
        fontFamilyFallback: fontFallbacks,
      ),
      
      // Label styles (buttons, tabs, etc.)
      labelLarge: baseTheme.labelLarge?.copyWith(
        fontFamilyFallback: fontFallbacks,
      ),
      labelMedium: baseTheme.labelMedium?.copyWith(
        fontFamilyFallback: fontFallbacks,
      ),
      labelSmall: baseTheme.labelSmall?.copyWith(
        fontFamilyFallback: fontFallbacks,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp(
          title: 'Afterlife',
          debugShowCheckedModeBanner: false,
          
          // Add localization support
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: languageProvider.currentLocale,
          
          theme: ThemeData(
            useMaterial3: true,
            primaryColor: AppTheme.etherealCyan,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppTheme.etherealCyan,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: AppTheme.backgroundStart,
            
            // Global text theme with Cyrillic font support (Ukrainian and Russian)
            textTheme: _buildTextThemeWithUkrainianSupport(
              ThemeData.dark().textTheme,
            ),
            
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
      },
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
