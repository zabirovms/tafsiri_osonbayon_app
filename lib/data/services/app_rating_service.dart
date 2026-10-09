import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';

/// Service to manage app rating and sharing prompts
/// Follows best practices: shows after usage milestones, respects user choices
class AppRatingService {
  static final InAppReview _inAppReview = InAppReview.instance;

  static const String _keyInstallDate = 'app_rating_install_date';
  static const String _keySessionCount = 'app_rating_session_count';
  static const String _keyLastPromptDate = 'app_rating_last_prompt_date';
  static const String _keyUserRated = 'app_rating_user_rated';
  static const String _keyUserDismissed = 'app_rating_user_dismissed';
  static const String _keyDismissedUntilDate = 'app_rating_dismissed_until_date';
  static const String _keyLastActionDate = 'app_rating_last_action_date';

  // Configuration - adjust these based on your needs
  static const int minSessionsBeforePrompt = 10; // Show after 10 app sessions
  static const int minDaysAfterInstall = 7; // Wait 7 days after install
  static const int daysBetweenPrompts = 30; // Don't show again for 30 days between reviews
  static const int daysAfterDismissal = 14; // Wait 14 days after dismissal before showing again

  /// Track app session (call this when app starts or user returns)
  static Future<void> trackSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Set install date if not set
      final installDateStr = prefs.getString(_keyInstallDate);
      if (installDateStr == null) {
        await prefs.setString(_keyInstallDate, DateTime.now().toIso8601String());
      }

      // Increment session count
      final sessionCount = prefs.getInt(_keySessionCount) ?? 0;
      await prefs.setInt(_keySessionCount, sessionCount + 1);
    } catch (e) {
      debugPrint('Error tracking session: $e');
    }
  }

  /// Check if the rating prompt should be shown
  static Future<bool> shouldShowPrompt() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Don't show if user already rated
      if (prefs.getBool(_keyUserRated) == true) {
        return false;
      }

      // Check if user dismissed and we should wait
      final dismissedUntilStr = prefs.getString(_keyDismissedUntilDate);
      if (dismissedUntilStr != null) {
        final dismissedUntil = DateTime.parse(dismissedUntilStr);
        if (DateTime.now().isBefore(dismissedUntil)) {
          return false;
        }
      }

      // Check minimum days after install
      final installDateStr = prefs.getString(_keyInstallDate);
      if (installDateStr == null) {
        // First launch, set install date and return false
        await prefs.setString(_keyInstallDate, DateTime.now().toIso8601String());
        return false;
      }

      final installDate = DateTime.parse(installDateStr);
      final daysSinceInstall = DateTime.now().difference(installDate).inDays;
      if (daysSinceInstall < minDaysAfterInstall) {
        return false;
      }

      // Check minimum session count
      final sessionCount = prefs.getInt(_keySessionCount) ?? 0;
      if (sessionCount < minSessionsBeforePrompt) {
        return false;
      }

      // Check if we've shown recently (don't show too frequently)
      final lastPromptStr = prefs.getString(_keyLastPromptDate);
      if (lastPromptStr != null) {
        final lastPrompt = DateTime.parse(lastPromptStr);
        final daysSinceLastPrompt = DateTime.now().difference(lastPrompt).inDays;
        if (daysSinceLastPrompt < daysBetweenPrompts) {
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error checking if should show prompt: $e');
      return false;
    }
  }

  /// Mark that the prompt was shown
  static Future<void> markPromptShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastPromptDate, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error marking prompt shown: $e');
    }
  }

  /// Mark that user rated the app
  static Future<void> markUserRated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyUserRated, true);
      await prefs.setString(_keyLastActionDate, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error marking user rated: $e');
    }
  }

  /// Mark that user dismissed the prompt
  static Future<void> markUserDismissed({bool neverShowAgain = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (neverShowAgain) {
        // User chose "Never show again" - set a far future date
        final farFuture = DateTime.now().add(const Duration(days: 365 * 10)); // 10 years
        await prefs.setString(_keyDismissedUntilDate, farFuture.toIso8601String());
        await prefs.setBool(_keyUserDismissed, true);
      } else {
        // User dismissed temporarily - show again after daysAfterDismissal days
        final dismissUntil = DateTime.now().add(Duration(days: daysAfterDismissal));
        await prefs.setString(_keyDismissedUntilDate, dismissUntil.toIso8601String());
        await prefs.setBool(_keyUserDismissed, true);
      }
      
      await prefs.setString(_keyLastActionDate, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error marking user dismissed: $e');
    }
  }

  /// Mark that user shared the app
  static Future<void> markUserShared() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastActionDate, DateTime.now().toIso8601String());
      // Don't mark as rated, but update last prompt date to avoid showing too soon
      await prefs.setString(_keyLastPromptDate, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error marking user shared: $e');
    }
  }

  /// Reset all rating data (for testing)
  static Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyInstallDate);
      await prefs.remove(_keySessionCount);
      await prefs.remove(_keyLastPromptDate);
      await prefs.remove(_keyUserRated);
      await prefs.remove(_keyUserDismissed);
      await prefs.remove(_keyDismissedUntilDate);
      await prefs.remove(_keyLastActionDate);
    } catch (e) {
      debugPrint('Error resetting rating data: $e');
    }
  }

  /// Get current session count (for debugging)
  static Future<int> getSessionCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keySessionCount) ?? 0;
    } catch (e) {
      debugPrint('Error getting session count: $e');
      return 0;
    }
  }

  /// Check if user has already rated
  static Future<bool> hasUserRated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyUserRated) ?? false;
    } catch (e) {
      debugPrint('Error checking if user rated: $e');
      return false;
    }
  }

  /// Request the native In-App Review API flow.
  /// If native is not available or errors, falls back to opening the store listing.
  static Future<void> requestInAppReview({bool isManual = false}) async {
    try {
      final isAvailable = await _inAppReview.isAvailable();
      if (isAvailable) {
        await _inAppReview.requestReview();
        await markPromptShown();
        if (isManual) {
          await markUserRated();
        }
      } else {
        await openStoreListing();
      }
    } catch (e) {
      debugPrint('Error requesting in-app review: $e');
      await openStoreListing();
    }
  }

  /// Open the store listing (Android or iOS)
  static Future<void> openStoreListing() async {
    try {
      // replace with actual iOS appStoreId when published
      await _inAppReview.openStoreListing(
        appStoreId: '6787344485',
      );
      await markUserRated();
    } catch (e) {
      debugPrint('Error opening store listing: $e');
    }
  }
}












