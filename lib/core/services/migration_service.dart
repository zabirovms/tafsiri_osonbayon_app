import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/services/settings_service.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/audio_downloads_service.dart';

/// Service to handle app version migrations
/// Checks version on app startup and runs necessary migrations
class MigrationService {
  static final MigrationService _instance = MigrationService._internal();
  factory MigrationService() => _instance;
  MigrationService._internal();

  final SettingsService _settingsService = SettingsService();

  /// Check app version and run migrations if needed
  /// Should be called during app initialization in main.dart
  Future<void> checkAndRunMigrations() async {
    try {
      await _settingsService.init();
      
      final currentVersion = AppConstants.appVersion;
      final storedVersion = _settingsService.getAppVersion();
      
      debugPrint('[MigrationService] Current version: $currentVersion');
      debugPrint('[MigrationService] Stored version: ${storedVersion ?? "null (first launch)"}');
      
      if (storedVersion == null) {
        // First launch - just set the version
        await _settingsService.setAppVersion(currentVersion);
        debugPrint('[MigrationService] First launch - version set to $currentVersion');
        return;
      }
      
      if (storedVersion == currentVersion) {
        // Already on current version - no migration needed
        debugPrint('[MigrationService] Already on current version - no migration needed');
        return;
      }
      
      // Version changed - run migrations
      debugPrint('[MigrationService] Version changed from $storedVersion to $currentVersion - running migrations');
      await runMigrations(storedVersion, currentVersion);
      
      // Update stored version after successful migration
      await _settingsService.setAppVersion(currentVersion);
      debugPrint('[MigrationService] Migrations completed successfully');
      
    } catch (e, stackTrace) {
      debugPrint('[MigrationService] Error during migration: $e');
      debugPrint('[MigrationService] Stack trace: $stackTrace');
      // Don't throw - allow app to continue even if migration fails
      // Log error for debugging
    }
  }

  /// Run version-specific migrations
  /// Add new migration cases here when app version changes
  Future<void> runMigrations(String fromVersion, String toVersion) async {
    debugPrint('[MigrationService] Running migrations from $fromVersion to $toVersion');
    
    // Parse version strings (format: "major.minor.patch")
    final fromParts = _parseVersion(fromVersion);
    final toParts = _parseVersion(toVersion);
    
    // Run migrations incrementally for each version step
    for (int major = fromParts[0]; major <= toParts[0]; major++) {
      for (int minor = (major == fromParts[0] ? fromParts[1] : 0); 
           minor <= (major == toParts[0] ? toParts[1] : 99); 
           minor++) {
        for (int patch = (major == fromParts[0] && minor == fromParts[1] ? fromParts[2] : 0);
             patch <= (major == toParts[0] && minor == toParts[1] ? toParts[2] : 99);
             patch++) {
          if (major == fromParts[0] && minor == fromParts[1] && patch == fromParts[2]) {
            continue; // Skip current version
          }
          
          final version = '$major.$minor.$patch';
          await _runVersionMigration(version);
        }
      }
    }
  }

  /// Run migration for a specific version
  Future<void> _runVersionMigration(String version) async {
    debugPrint('[MigrationService] Running migration for version $version');
    
    // Version 1.1.0 migrations
    if (version == '1.1.0') {
      await _migrateTo110();
    }
    
    // Version 1.1.1 migrations
    if (version == '1.1.1') {
      await _migrateTo111();
    }
    
    // Version 1.1.2 migrations
    if (version == '1.1.2') {
      await _migrateTo112();
    }
    
    // Version 1.1.3 migrations
    if (version == '1.1.3') {
      await _migrateTo113();
    }
    
    // Version 1.1.4 migrations
    if (version == '1.1.4') {
      await _migrateTo114();
    }
    
    // Version 1.1.5 migrations
    if (version == '1.1.5') {
      await _migrateTo115();
    }
    
    // Version 1.1.6 migrations
    if (version == '1.1.6') {
      await _migrateTo116();
    }
    
    // Version 1.1.7 migrations
    if (version == '1.1.7') {
      await _migrateTo117();
    }
    
    // Version 1.1.8 migrations
    if (version == '1.1.8') {
      await _migrateTo118();
    }
    
    // Version 1.1.9 migrations
    if (version == '1.1.9') {
      await _migrateTo119();
    }
    
    // Version 1.2.0 migrations
    if (version == '1.2.0') {
      await _migrateTo120();
    }

    // Version 1.2.1 migrations
    if (version == '1.2.1') {
      await _migrateTo121();
    }

    // Version 1.2.2 migrations
    if (version == '1.2.2') {
      await _migrateTo122();
    }

    // Version 1.2.3 migrations
    if (version == '1.2.3') {
      await _migrateTo123();
    }

    // Version 1.2.4 migrations
    if (version == '1.2.4') {
      await _migrateTo124();
    }

    // Version 1.3.0 migrations
    if (version == '1.3.0') {
      await _migrateTo130();
    }

    // Version 1.3.1 migrations
    if (version == '1.3.1') {
      await _migrateTo131();
    }

    // Version 1.3.2 migrations
    if (version == '1.3.2') {
      await _migrateTo132();
    }

    // Version 1.3.3 migrations
    if (version == '1.3.3') {
      await _migrateTo133();
    }

    // Version 1.3.4 migrations
    if (version == '1.3.4') {
      await _migrateTo134();
    }

    // Version 1.3.5 migrations
    if (version == '1.3.5') {
      await _migrateTo135();
    }

    // Add future version migrations here
  }

  /// Migration to version 1.1.0
  Future<void> _migrateTo110() async {
    debugPrint('[MigrationService] Running migration to 1.1.0');
    
    // Verify audio downloads files exist
    // This is a one-time migration to clean up orphaned metadata
    await _verifyAudioDownloads();
    
    // Add other 1.1.0 migrations here
  }

  /// Migration to version 1.1.1
  Future<void> _migrateTo111() async {
    debugPrint('[MigrationService] Running migration to 1.1.1');
    
    // Verify audio downloads files exist (re-verify for safety)
    // This ensures any files that became orphaned between versions are cleaned up
    await _verifyAudioDownloads();
    
    // Add other 1.1.1 migrations here
  }

  /// Migration to version 1.1.2
  Future<void> _migrateTo112() async {
    debugPrint('[MigrationService] Running migration to 1.1.2');
    
    // Verify audio downloads files exist
    await _verifyAudioDownloads();
    
    // Add other 1.1.2 migrations here
  }

  /// Migration to version 1.1.3
  Future<void> _migrateTo113() async {
    debugPrint('[MigrationService] Running migration to 1.1.3');
    
    // Verify audio downloads files exist
    await _verifyAudioDownloads();
    
    // Add other 1.1.3 migrations here
  }

  /// Migration to version 1.1.4
  Future<void> _migrateTo114() async {
    debugPrint('[MigrationService] Running migration to 1.1.4');
    
    // Verify audio downloads files exist
    await _verifyAudioDownloads();
    
    // Version 1.1.4 adds Share and Rate prompt feature
    // No data migration needed - AppRatingService will initialize on first use
    
    // Add other 1.1.4 migrations here
  }

  /// Migration to version 1.1.5
  Future<void> _migrateTo115() async {
    debugPrint('[MigrationService] Running migration to 1.1.5');
    
    // Verify audio downloads files exist
    await _verifyAudioDownloads();
    
    // Version 1.1.5 - Production release
    // No data migration needed - all user data will persist
    
    // Add other 1.1.5 migrations here
  }

  /// Migration to version 1.1.6
  Future<void> _migrateTo116() async {
    debugPrint('[MigrationService] Running migration to 1.1.6');
    
    // Verify audio downloads files exist
    await _verifyAudioDownloads();
    
    // Initialize prayer times Hive box (new feature in 1.1.6)
    await _initializePrayerTimesBox();
    
    // Version 1.1.6 - Production update
    // No data migration needed - all user data will persist
    
    // Add other 1.1.6 migrations here
  }

  /// Migration to version 1.1.7
  Future<void> _migrateTo117() async {
    debugPrint('[MigrationService] Running migration to 1.1.7');
    
    // Verify audio downloads files exist
    await _verifyAudioDownloads();
    
    // Version 1.1.7 - Production update
    // No data migration needed - all user data will persist
    
    // Add other 1.1.7 migrations here
  }

  /// Migration to version 1.1.8
  Future<void> _migrateTo118() async {
    debugPrint('[MigrationService] Running migration to 1.1.8');
    
    // Verify audio downloads files exist
    await _verifyAudioDownloads();
    
    // Version 1.1.8 - Production update (startup/ANR improvements, quoted-verses wallpapers, init order)
    // No data migration needed - all user data will persist
  }

  /// Migration to version 1.1.9
  Future<void> _migrateTo119() async {
    debugPrint('[MigrationService] Running migration to 1.1.9');
    
    // Verify audio downloads files exist
    await _verifyAudioDownloads();
    
    // Version 1.1.9 - Production update
    // No data migration needed - all user data will persist
  }

  /// Migration to version 1.2.0
  Future<void> _migrateTo120() async {
    debugPrint('[MigrationService] Running migration to 1.2.0');
    
    // Verify audio downloads files exist
    await _verifyAudioDownloads();
    
    // Version 1.2.0 - Production update (asset reorg, Tajweed, categorized duas, Play Store description)
    // No data migration needed - all user data will persist
  }

  /// Migration to version 1.2.1
  Future<void> _migrateTo121() async {
    debugPrint('[MigrationService] Running migration to 1.2.1');

    // Verify audio downloads files exist
    await _verifyAudioDownloads();

    // Version 1.2.1 - Production maintenance update
    // No data migration needed - all user data will persist
  }

  /// Migration to version 1.2.2
  Future<void> _migrateTo122() async {
    debugPrint('[MigrationService] Running migration to 1.2.2');

    // Verify audio downloads files exist
    await _verifyAudioDownloads();

    // Version 1.2.2 - Production release
    // No data migration needed - all user data will persist
  }

  /// Migration to version 1.2.3
  Future<void> _migrateTo123() async {
    debugPrint('[MigrationService] Running migration to 1.2.3');

    // Verify audio downloads files exist
    await _verifyAudioDownloads();

    // Version 1.2.3 - Android App Links / HTTPS deep links (no schema changes)
    // No data migration needed - all user data will persist
  }

  /// Migration to version 1.2.4
  Future<void> _migrateTo124() async {
    debugPrint('[MigrationService] Running migration to 1.2.4');

    // Verify audio downloads files exist
    await _verifyAudioDownloads();

    // Version 1.2.4 - FCM hardening, external URL notifications, Masnavi menu updates
    // No data migration needed - all user data will persist
  }

  /// Migration to version 1.3.0
  Future<void> _migrateTo130() async {
    debugPrint('[MigrationService] Running migration to 1.3.0');

    // Verify audio downloads files exist
    await _verifyAudioDownloads();

    // Version 1.3.0 - Hadis (Bukhari) navigation/menu restructuring & edge-to-edge transparent UI theme updates
    // No data migration needed - all user data will persist
  }

  /// Migration to version 1.3.1
  Future<void> _migrateTo131() async {
    debugPrint('[MigrationService] Running migration to 1.3.1');

    // Verify audio downloads files exist
    await _verifyAudioDownloads();

    // Version 1.3.1 - Production maintenance update
    // No data migration needed - all user data will persist
  }

  /// Migration to version 1.3.2
  Future<void> _migrateTo132() async {
    debugPrint('[MigrationService] Running migration to 1.3.2');

    // Verify audio downloads files exist
    await _verifyAudioDownloads();

    // Version 1.3.2 - Production maintenance update
    // No data migration needed - all user data will persist
  }

  /// Migration to version 1.3.3
  Future<void> _migrateTo133() async {
    debugPrint('[MigrationService] Running migration to 1.3.3');

    // Verify audio downloads files exist
    await _verifyAudioDownloads();

    // Version 1.3.3 - Hero section redesign, settings version display, Farzi Ayn badge removal
    // No data migration needed - all user data will persist
  }

  /// Migration to version 1.3.4
  Future<void> _migrateTo134() async {
    debugPrint('[MigrationService] Running migration to 1.3.4');

    // Verify audio downloads files exist
    await _verifyAudioDownloads();

    // Version 1.3.4 - verified QUL Hafs database migration & home screen UI layout alignment
    // No data migration needed - all user data will persist
  }

  /// Migration to version 1.3.5
  Future<void> _migrateTo135() async {
    debugPrint('[MigrationService] Running migration to 1.3.5');

    // Verify audio downloads files exist
    await _verifyAudioDownloads();

    // Version 1.3.5 - iOS minimum deployment target upgrade & Qibla / Support page enhancements
    // No data migration needed - all user data will persist
  }

  /// Initialize prayer times Hive box for offline caching
  Future<void> _initializePrayerTimesBox() async {
    try {
      // Box is opened in HiveUtils.initCritical() before runApp
      // This migration ensures the box exists for users updating from older versions
      // The box will be created automatically if it doesn't exist
      if (!Hive.isBoxOpen(AppConstants.prayerTimesBox)) {
        await Hive.openBox(AppConstants.prayerTimesBox);
        debugPrint('[MigrationService] Prayer times box opened');
      } else {
        debugPrint('[MigrationService] Prayer times box already open');
      }
    } catch (e) {
      debugPrint('[MigrationService] Error initializing prayer times box: $e');
      // Don't throw - box will be created automatically when first accessed
    }
  }

  /// Helper method to verify audio downloads (shared between migrations)
  Future<void> _verifyAudioDownloads() async {
    try {
      final audioDownloadsService = AudioDownloadsService();
      await audioDownloadsService.verifyDownloadedFiles();
      debugPrint('[MigrationService] Audio downloads verified');
    } catch (e) {
      debugPrint('[MigrationService] Error verifying audio downloads: $e');
      // Don't throw - allow migration to continue
    }
  }

  /// Parse version string into [major, minor, patch]
  List<int> _parseVersion(String version) {
    final parts = version.split('.');
    return [
      int.tryParse(parts[0]) ?? 0,
      int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      int.tryParse(parts.length > 2 ? parts[2] : '0') ?? 0,
    ];
  }
}


