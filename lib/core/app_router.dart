import 'package:flutter/material.dart';
import '../features/landing_page/landing_screen.dart';
import '../features/character_gallery/character_gallery_screen.dart';
import '../features/character_interview/interview_screen.dart';

class AppRouter {
  // Define route names as constants
  static const String landing = '/';
  static const String gallery = '/gallery';
  static const String interview = '/interview';

  // Handle route generation
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    try {
      switch (settings.name) {
        case landing:
          return _buildRoute(const LandingScreen());

        case gallery:
          return _buildRoute(const CharacterGalleryScreen());

        case interview:
          final args = settings.arguments as Map<String, dynamic>?;
          return _buildRoute(
            InterviewScreen(
              editMode: args?['editMode'] ?? false,
              existingCharacter: args?['existingCharacter'],
            ),
          );

        default:
          return _buildRoute(const LandingScreen());
      }
    } catch (e) {
      // Handle any errors during route generation
      return _buildErrorRoute(e);
    }
  }

  static MaterialPageRoute<T> _buildRoute<T>(Widget page) {
    return MaterialPageRoute<T>(
      builder: (context) => page,
      settings: RouteSettings(name: page.toString()),
    );
  }

  static MaterialPageRoute<T> _buildErrorRoute<T>(Object error) {
    return MaterialPageRoute<T>(
      builder:
          (context) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Navigation Error',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
