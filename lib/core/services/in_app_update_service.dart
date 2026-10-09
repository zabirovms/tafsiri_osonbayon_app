import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service to check for app updates.
/// Android: Uses Google Play In-App Update API.
/// iOS: Uses iTunes Lookup API and prompts the user to redirect to the App Store.
class InAppUpdateService {
  InAppUpdateService._();
  static final InAppUpdateService _instance = InAppUpdateService._();
  factory InAppUpdateService() => _instance;

  static const String _lastCheckKey = 'in_app_update_last_check';
  // Reduced throttle to 4 hours for faster detection of new updates
  static const Duration _checkThrottle = Duration(hours: 4);

  // App Store ID used for iOS updates (same as configured in AppRatingService)
  static const String _appStoreId = '6787344485';

  /// Checks for an update if we're on Android or iOS and haven't checked recently.
  /// Call this when the main screen is visible (e.g. after MainMenuPage loads).
  Future<void> checkForUpdateIfNeeded(BuildContext context) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt(_lastCheckKey);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (lastCheck != null && (now - lastCheck) < _checkThrottle.inMilliseconds) {
      return;
    }
    await prefs.setInt(_lastCheckKey, now);

    if (!context.mounted) return;

    if (Platform.isAndroid) {
      await _checkAndPromptUpdateAndroid(context);
    } else if (Platform.isIOS) {
      await _checkAndPromptUpdateIOS(context);
    }
  }

  /// Performs the actual check and starts flexible or immediate update flow for Android.
  Future<void> _checkAndPromptUpdateAndroid(BuildContext context) async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (!context.mounted) return;

      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        if (kDebugMode) {
          debugPrint('[InAppUpdate] No update available (${info.updateAvailability})');
        }
        return;
      }

      // Prefer flexible update so user can keep using the app while update downloads.
      try {
        await InAppUpdate.startFlexibleUpdate();
        if (!context.mounted) return;
        // Download completed – prompt to install (restart).
        await _showCompleteUpdateDialog(context);
      } catch (e) {
        if (kDebugMode) debugPrint('[InAppUpdate] Flexible update failed: $e');
        // Fallback to immediate update (full-screen).
        if (!context.mounted) return;
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[InAppUpdate] Check failed: $e');
        // e.g. ERROR_API_NOT_AVAILABLE when not installed from Play Store
      }
    }
  }

  /// Performs version check via iTunes Search API and prompts user for update on iOS.
  Future<void> _checkAndPromptUpdateIOS(BuildContext context) async {
    try {
      final url = Uri.parse('https://itunes.apple.com/lookup?id=$_appStoreId');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('[InAppUpdate] iTunes Lookup failed with status: ${response.statusCode}');
        }
        return;
      }

      final data = json.decode(response.body);
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) {
        if (kDebugMode) {
          debugPrint('[InAppUpdate] No App Store results found for ID: $_appStoreId');
        }
        return;
      }

      final result = results.first as Map<String, dynamic>;
      final storeVersion = result['version'] as String?;
      final trackViewUrl = result['trackViewUrl'] as String?;

      if (storeVersion == null || trackViewUrl == null) return;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (_isVersionNewer(currentVersion, storeVersion)) {
        if (!context.mounted) return;
        await _showIOSUpdateDialog(context, trackViewUrl, storeVersion);
      } else {
        if (kDebugMode) {
          debugPrint('[InAppUpdate] App is up to date on iOS: $currentVersion vs App Store: $storeVersion');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[InAppUpdate] iOS Update Check failed: $e');
      }
    }
  }

  /// Helper to compare semantic version strings (e.g. "1.3.2" vs "1.3.3")
  bool _isVersionNewer(String current, String store) {
    try {
      final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final storeParts = store.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      final maxLength = currentParts.length > storeParts.length ? currentParts.length : storeParts.length;
      for (var i = 0; i < maxLength; i++) {
        final currentVal = i < currentParts.length ? currentParts[i] : 0;
        final storeVal = i < storeParts.length ? storeParts[i] : 0;

        if (storeVal > currentVal) return true;
        if (storeVal < currentVal) return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[InAppUpdate] Error parsing versions: $e');
      }
    }
    return false;
  }

  Future<void> _showCompleteUpdateDialog(BuildContext context) async {
    final shouldInstall = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Версияи нав дастрас аст'),
        content: const Text(
          'Версияи нави барнома зеркашӣ карда шуд. Барои насби версияи нав «ОК»-ро пахш кунед. Барнома аз нав оғоз мешавад.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Баъдтар'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
    if (shouldInstall == true) {
      await InAppUpdate.completeFlexibleUpdate();
    }
  }

  /// Custom iOS prompt dialog redirecting user to App Store
  Future<void> _showIOSUpdateDialog(BuildContext context, String appStoreUrl, String newVersion) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Версияи нав дастрас аст'),
          content: Text(
            'Версияи нави барнома ($newVersion) дар App Store дастрас аст. Лутфан барномаро навсозӣ кунед, то аз имкониятҳои нав истифода баред.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Баъдтар', style: TextStyle(color: cs.onSurfaceVariant)),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final uri = Uri.parse(appStoreUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text('Навсозӣ'),
            ),
          ],
        );
      },
    );
  }
}
