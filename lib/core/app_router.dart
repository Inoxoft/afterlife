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
    switch (settings.name) {
      case landing:
        return MaterialPageRoute(builder: (_) => const LandingScreen());

      case gallery:
        return MaterialPageRoute(
          builder: (_) => const CharacterGalleryScreen(),
        );

      case interview:
        Map<String, dynamic>? args;
        if (settings.arguments != null) {
          args = settings.arguments as Map<String, dynamic>;
        }

        // Check if we're editing an existing character
        final editMode = args?['editMode'] ?? false;
        final existingCharacter = args?['existingCharacter'];

        return MaterialPageRoute(
          builder:
              (_) => InterviewScreen(
                editMode: editMode,
                existingCharacter: existingCharacter,
              ),
        );

      default:
        // If route not found, go to landing
        return MaterialPageRoute(builder: (_) => const LandingScreen());
    }
  }
}
