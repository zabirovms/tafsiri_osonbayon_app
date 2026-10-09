import 'package:shared_preferences/shared_preferences.dart';

class LastPlayedService {
  static const String _keyReciterId = 'last_played_reciter_id';
  static const String _keySurahNumber = 'last_played_surah_number';
  static const String _keyVerseNumber = 'last_played_verse_number';
  static const String _keyTimestamp = 'last_played_timestamp';

  // Save last played item
  Future<void> saveLastPlayed({
    required String reciterId,
    required int surahNumber,
    int? verseNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyReciterId, reciterId);
    await prefs.setInt(_keySurahNumber, surahNumber);
    if (verseNumber != null) {
      await prefs.setInt(_keyVerseNumber, verseNumber);
    } else {
      await prefs.remove(_keyVerseNumber);
    }
    await prefs.setInt(_keyTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  // Get last played reciter ID
  Future<String?> getLastPlayedReciterId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyReciterId);
  }

  // Get last played surah number
  Future<int?> getLastPlayedSurahNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySurahNumber);
  }

  // Get last played verse number
  Future<int?> getLastPlayedVerseNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyVerseNumber);
  }

  // Get last played timestamp
  Future<DateTime?> getLastPlayedTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_keyTimestamp);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  // Clear last played
  Future<void> clearLastPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyReciterId);
    await prefs.remove(_keySurahNumber);
    await prefs.remove(_keyVerseNumber);
    await prefs.remove(_keyTimestamp);
  }
}

