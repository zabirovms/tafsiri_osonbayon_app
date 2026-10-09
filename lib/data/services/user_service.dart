import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user sessions and preferences
class UserService {
  static const String _currentUserIdKey = 'current_user_id';
  static const String _userPreferencesKey = 'user_preferences';
  
  /// Get current user ID or create a new one
  Future<String> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString(_currentUserIdKey);
      
      if (userId == null || userId.isEmpty) {
        // Generate a new user ID
        userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString(_currentUserIdKey, userId);
      }
      
      return userId;
    } catch (e) {
      debugPrint('Error getting user ID: $e');
      // Fallback to a default user ID
      return 'user_default';
    }
  }
  
  /// Set current user ID
  Future<bool> setCurrentUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_currentUserIdKey, userId);
    } catch (e) {
      debugPrint('Error setting user ID: $e');
      return false;
    }
  }
  
  /// Get user preferences
  Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await getCurrentUserId();
      final preferencesJson = prefs.getString('$_userPreferencesKey$userId');
      
      if (preferencesJson == null) {
        return _getDefaultPreferences();
      }
      
      // Parse JSON and return preferences
      // For now, return default preferences
      return _getDefaultPreferences();
    } catch (e) {
      debugPrint('Error getting user preferences: $e');
      return _getDefaultPreferences();
    }
  }
  
  /// Save user preferences
  Future<bool> saveUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await getCurrentUserId();
      // In a real implementation, you would serialize preferences to JSON
      return await prefs.setString('$_userPreferencesKey$userId', '{}');
    } catch (e) {
      debugPrint('Error saving user preferences: $e');
      return false;
    }
  }
  
  /// Reset user data (for testing or account reset)
  Future<bool> resetUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await getCurrentUserId();
      
      // Remove all user-related data
      await prefs.remove(_currentUserIdKey);
      await prefs.remove('$_userPreferencesKey$userId');
      
      return true;
    } catch (e) {
      debugPrint('Error resetting user data: $e');
      return false;
    }
  }
  
  /// Get default user preferences
  Map<String, dynamic> _getDefaultPreferences() {
    return {
      'soundEnabled': true,
      'hapticFeedback': true,
      'darkMode': false,
    };
  }
}
