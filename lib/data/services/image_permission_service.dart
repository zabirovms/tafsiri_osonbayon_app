import 'package:shared_preferences/shared_preferences.dart';

class ImagePermissionService {
  static const String _permissionKey = 'image_download_permission';
  static const String _permissionAskedKey = 'image_permission_asked';

  /// Check if user has given permission to download images
  Future<bool> hasImageDownloadPermission() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionKey) ?? false;
  }

  /// Set user's permission for image downloading
  Future<void> setImageDownloadPermission(bool permission) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionKey, permission);
  }

  /// Check if permission dialog has been shown in this session
  Future<bool> hasAskedForPermission() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionAskedKey) ?? false;
  }

  /// Mark that permission dialog has been shown
  Future<void> setPermissionAsked(bool asked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionAskedKey, asked);
  }

  /// Reset permission state (for testing or user preference reset)
  Future<void> resetPermissionState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_permissionKey);
    await prefs.remove(_permissionAskedKey);
  }
}
