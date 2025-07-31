import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/env_config.dart';
import 'core/utils/app_optimizer.dart';
import 'core/utils/app_logger.dart';
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
  final Object? originalError;
  AppInitializationError(this.message, [this.originalError]);

  @override
  String toString() =>
      'AppInitializationError: $message${originalError != null ? ' (caused by: $originalError)' : ''}';
}

class InitializationResult {
  final bool success;
  final String? errorMessage;
  final Object? error;
  final List<String> warnings;

  const InitializationResult({
    required this.success,
    this.errorMessage,
    this.error,
    this.warnings = const [],
  });

  factory InitializationResult.success([List<String> warnings = const []]) =>
      InitializationResult(success: true, warnings: warnings);

  factory InitializationResult.failure(String message, [Object? error]) =>
      InitializationResult(success: false, errorMessage: message, error: error);
}

Future<InitializationResult> _initializeApp() async {
  final warnings = <String>[];

  try {
    // Initialize all app optimizations
    await AppOptimizer.initializeApp();

    // Initialize environment configuration with proper error handling
    try {
      await EnvConfig.initialize();
    } catch (e) {
      AppLogger.serviceError('EnvConfig', 'initialization failed', e);
      warnings.add('Configuration service failed to initialize');
      // Don't fail completely - app can still work with default settings
    }

    // Initialize services with dependency management
    final serviceResults = await _initializeServices();
    warnings.addAll(serviceResults.warnings);

    if (!serviceResults.success && serviceResults.errorMessage != null) {
      return InitializationResult.failure(
        'Critical services failed to initialize: ${serviceResults.errorMessage}',
        serviceResults.error,
      );
    }

    return InitializationResult.success(warnings);
  } catch (e, stackTrace) {
    AppLogger.critical('App initialization failed', error: e);
    return InitializationResult.failure('Application failed to start', e);
  }
}

Future<InitializationResult> _initializeServices() async {
  final warnings = <String>[];
  bool hasCriticalFailure = false;
  Object? lastError;

  try {
    // Initialize hybrid chat service (this will initialize LocalLLMService)
    try {
      await HybridChatService.initialize();
    } catch (e) {
      AppLogger.serviceError('HybridChatService', 'initialization failed', e);
      warnings.add('AI chat service initialization failed');
      hasCriticalFailure = true;
      lastError = e;
    }

    // Initialize character interview chat service
    try {
      await interview_chat.ChatService.initialize();
      interview_chat.ChatService.logDiagnostics();
    } catch (e) {
      AppLogger.serviceError(
        'InterviewChatService',
        'initialization failed',
        e,
      );
      warnings.add('Character interview service failed');
      // Not critical - app can work without this
    }

    // Initialize providers chat service (if available)
    if (const bool.fromEnvironment(
      'USE_PROVIDER_CHAT_SERVICE',
      defaultValue: false,
    )) {
      try {
        await providers_chat.ChatService.initialize();
        providers_chat.ChatService.logDiagnostics();
      } catch (e) {
        if (kDebugMode) {
          print('Provider chat service initialization failed: $e');
        }
        warnings.add('Provider chat service failed');
        // Not critical
      }
    }

    // Initialize and clean famous character prompts
    try {
      FamousCharacterPrompts.initialize();
    } catch (e) {
      if (kDebugMode) {
        print('Famous character prompts initialization failed: $e');
      }
      warnings.add('Character prompts failed to load');
      // Not critical - can work without famous characters
    }

    if (hasCriticalFailure) {
      return InitializationResult.failure(
        'Essential services failed to start',
        lastError,
      );
    }

    return InitializationResult.success(warnings);
  } catch (e) {
    return InitializationResult.failure(
      'Unexpected error during service initialization',
      e,
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runZonedGuarded(
    () async {
      try {
        final initResult = await _initializeApp();

        if (!initResult.success) {
          // Show error screen with detailed information
          runApp(
            ErrorApp(
              error: initResult.errorMessage ?? 'Unknown initialization error',
              technicalDetails: initResult.error?.toString(),
              canRetry: true,
            ),
          );
          return;
        }

        // Show warnings to user if any (in debug mode or development)
        if (initResult.warnings.isNotEmpty) {
          AppLogger.warning(
            'App started with warnings: ${initResult.warnings.join(', ')}',
          );
        }

        runApp(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => CharactersProvider()),
              ChangeNotifierProvider(create: (_) => LanguageProvider()),
            ],
            child: MyApp(initializationWarnings: initResult.warnings),
          ),
        );
      } catch (e, stackTrace) {
        AppLogger.critical('Critical error in main', error: e);
        runApp(
          ErrorApp(
            error: 'Critical Application Error',
            technicalDetails: e.toString(),
            canRetry: true,
          ),
        );
      }
    },
    (error, stackTrace) {
      AppLogger.critical('Uncaught error', error: error);
      // Last resort error handler
      runApp(
        ErrorApp(
          error: 'Unexpected Error',
          technicalDetails: error.toString(),
          canRetry: false,
        ),
      );
    },
  );
}

class MyApp extends StatefulWidget {
  final List<String> initializationWarnings;

  const MyApp({super.key, this.initializationWarnings = const []});

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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          home:
              const SplashScreen(), // Use the splash screen as the home screen
        );
      },
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  final String? technicalDetails;
  final bool canRetry;

  const ErrorApp({
    super.key,
    required this.error,
    this.technicalDetails,
    this.canRetry = false,
  });

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
                if (technicalDetails != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    technicalDetails!,
                    style: const TextStyle(color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => SystemNavigator.pop(),
                  child: Text(canRetry ? 'Restart App' : 'Exit App'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
