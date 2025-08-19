import 'package:shared_preferences/shared_preferences.dart';
import 'preferences_service.dart';
import 'package:flutter/foundation.dart';
import '../utils/app_logger.dart';

class OnboardingService {
  static const String _onboardingCompleteKey = 'onboarding_completed';

  /// Check if the user has completed onboarding
  static Future<bool> hasCompletedOnboarding() async {
    try {
      final prefs = await PreferencesService.getPrefs();
      return prefs.getBool(_onboardingCompleteKey) ?? false;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('Error checking onboarding status', tag: 'OnboardingService', error: e);
      }
      return false;
    }
  }

  /// Mark onboarding as complete
  static Future<bool> markOnboardingComplete() async {
    try {
      final prefs = await PreferencesService.getPrefs();
      final success = await prefs.setBool(_onboardingCompleteKey, true);
      if (kDebugMode) {
        AppLogger.debug('Onboarding marked as complete: $success', tag: 'OnboardingService');
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('Error marking onboarding complete', tag: 'OnboardingService', error: e);
      }
      return false;
    }
  }

  /// Reset onboarding (for testing or user preference)
  static Future<bool> resetOnboarding() async {
    try {
      final prefs = await PreferencesService.getPrefs();
      final success = await prefs.setBool(_onboardingCompleteKey, false);
      if (kDebugMode) {
        AppLogger.debug('Onboarding reset: $success', tag: 'OnboardingService');
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('Error resetting onboarding', tag: 'OnboardingService', error: e);
      }
      return false;
    }
  }

  /// Clear onboarding preference entirely
  static Future<bool> clearOnboardingPreference() async {
    try {
      final prefs = await PreferencesService.getPrefs();
      final success = await prefs.remove(_onboardingCompleteKey);
      if (kDebugMode) {
        AppLogger.debug('Onboarding preference cleared: $success', tag: 'OnboardingService');
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('Error clearing onboarding preference', tag: 'OnboardingService', error: e);
      }
      return false;
    }
  }
}
