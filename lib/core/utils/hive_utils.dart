import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';

class HiveUtils {
  static bool _secondaryOpened = false;

  /// Boxes required before the first frame: home reads scheduler state synchronously;
  /// prayer times load touches this box soon after (same frame / next microtasks).
  static Future<void> initCritical() async {
    await Future.wait([
      Hive.openBox(AppConstants.schedulerBox),
      Hive.openBox(AppConstants.prayerTimesBox),
    ]);
  }

  /// Remaining boxes — open after first paint to shorten pre–runApp blocking time.
  /// Safe: no current code paths read these boxes before user navigates past home.
  static Future<void> initSecondary() async {
    if (_secondaryOpened) return;
    _secondaryOpened = true;
    await Future.wait([
      Hive.openBox(AppConstants.settingsBox),
      Hive.openBox(AppConstants.bookmarksBox),
      Hive.openBox(AppConstants.userPreferencesBox),
      Hive.openBox(AppConstants.searchHistoryBox),
      Hive.openBox(AppConstants.tasbeehBox),
      Hive.openBox(AppConstants.wordLearningBox),
      Hive.openBox(AppConstants.downloadedTranslationsBox),
      Hive.openBox(AppConstants.feedbackBox),
    ]);
  }

  // Settings Box
  static Box get settingsBox => Hive.box(AppConstants.settingsBox);

  // Bookmarks Box
  static Box get bookmarksBox => Hive.box(AppConstants.bookmarksBox);

  // User Preferences Box
  static Box get userPreferencesBox => Hive.box(AppConstants.userPreferencesBox);

  // Search History Box
  static Box get searchHistoryBox => Hive.box(AppConstants.searchHistoryBox);

  // Tasbeeh Box
  static Box get tasbeehBox => Hive.box(AppConstants.tasbeehBox);

  // Word Learning Box
  static Box get wordLearningBox => Hive.box(AppConstants.wordLearningBox);

  // Downloaded Translations Box
  static Box get downloadedTranslationsBox =>
      Hive.box(AppConstants.downloadedTranslationsBox);

  // Scheduler Box
  static Box get schedulerBox => Hive.box(AppConstants.schedulerBox);

  // Prayer Times Box
  static Box get prayerTimesBox => Hive.box(AppConstants.prayerTimesBox);

  // Generic methods for all boxes
  static Future<void> put(String boxName, String key, dynamic value) async {
    final box = Hive.box(boxName);
    await box.put(key, value);
  }

  static T? get<T>(String boxName, String key) {
    final box = Hive.box(boxName);
    return box.get(key);
  }

  static Future<void> delete(String boxName, String key) async {
    final box = Hive.box(boxName);
    await box.delete(key);
  }

  static Future<void> clear(String boxName) async {
    final box = Hive.box(boxName);
    await box.clear();
  }

  static List<dynamic> getAll(String boxName) {
    final box = Hive.box(boxName);
    return box.values.toList();
  }

  static Map<dynamic, dynamic> getAllAsMap(String boxName) {
    final box = Hive.box(boxName);
    return box.toMap();
  }
}
