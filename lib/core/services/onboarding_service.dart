import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class OnboardingService {
  static const String _onboardingCompleteKey = 'onboarding_completed';

  /// Check if the user has completed onboarding
  static Future<bool> hasCompletedOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingCompleteKey) ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('OnboardingService: Error checking onboarding status: $e');
      }
      return false;
    }
  }

  /// Mark onboarding as complete
  static Future<bool> markOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setBool(_onboardingCompleteKey, true);
      if (kDebugMode) {
        print('OnboardingService: Onboarding marked as complete: $success');
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('OnboardingService: Error marking onboarding complete: $e');
      }
      return false;
    }
  }

  /// Reset onboarding (for testing or user preference)
  static Future<bool> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setBool(_onboardingCompleteKey, false);
      if (kDebugMode) {
        print('OnboardingService: Onboarding reset: $success');
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('OnboardingService: Error resetting onboarding: $e');
      }
      return false;
    }
  }

  /// Clear onboarding preference entirely
  static Future<bool> clearOnboardingPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.remove(_onboardingCompleteKey);
      if (kDebugMode) {
        print('OnboardingService: Onboarding preference cleared: $success');
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('OnboardingService: Error clearing onboarding preference: $e');
      }
      return false;
    }
  }
}
