import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetUpdateService {
  static const String _androidAudioWidgetName = 'AudioWidgetProvider';
  static const String _iOSAudioWidgetName = 'AudioWidget';
  static const String _appGroupId = 'group.com.quran.tj.quranapp';

  /// Updates the audio widget state parameters
  static Future<void> updateAudioWidgetState({
    required bool isPlaying,
    required String surahName,
    required String qariName,
    required int surahNumber,
    required String qariId,
    required String audioState,
  }) async {
    try {
      if (kDebugMode) {
        print('WidgetUpdateService: Updating audio widget: isPlaying=$isPlaying, state=$audioState, surah=$surahName, qari=$qariName');
      }

      await HomeWidget.setAppGroupId(_appGroupId);

      // Save audio state
      await HomeWidget.saveWidgetData<bool>('audio_is_playing', isPlaying);
      await HomeWidget.saveWidgetData<String>('audio_surah_name', surahName);
      await HomeWidget.saveWidgetData<String>('audio_qari_name', qariName);
      await HomeWidget.saveWidgetData<int>('audio_surah_number', surahNumber);
      await HomeWidget.saveWidgetData<String>('audio_qari_id', qariId);
      await HomeWidget.saveWidgetData<String>('audio_state', audioState);

      // Also persist to local SharedPreferences so background callbacks can resume it
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('widget_last_surah', surahNumber);
      await prefs.setString('widget_last_qari', qariId);

      // Trigger update for Audio widget
      await HomeWidget.updateWidget(
        name: _androidAudioWidgetName,
        androidName: _androidAudioWidgetName,
        iOSName: _iOSAudioWidgetName,
      );
    } catch (e, stack) {
      if (kDebugMode) {
        print('WidgetUpdateService updateAudioWidgetState Error: $e\n$stack');
      }
    }
  }

  /// Clears the audio widget state
  static Future<void> clearAudioWidgetState() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
      await HomeWidget.saveWidgetData<bool>('audio_is_playing', false);
      await HomeWidget.saveWidgetData<String>('audio_surah_name', '');
      await HomeWidget.saveWidgetData<String>('audio_qari_name', '');
      await HomeWidget.saveWidgetData<int>('audio_surah_number', 0);
      await HomeWidget.saveWidgetData<String>('audio_qari_id', '');
      await HomeWidget.saveWidgetData<String>('audio_state', 'idle');

      await HomeWidget.updateWidget(
        name: _androidAudioWidgetName,
        androidName: _androidAudioWidgetName,
        iOSName: _iOSAudioWidgetName,
      );
    } catch (e) {
      if (kDebugMode) {
        print('WidgetUpdateService clearAudioWidgetState Error: $e');
      }
    }
  }

  /// Sets only the playing status of the audio widget
  static Future<void> setAudioWidgetPlaying(bool isPlaying) async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
      await HomeWidget.saveWidgetData<bool>('audio_is_playing', isPlaying);
      await HomeWidget.saveWidgetData<String>('audio_state', isPlaying ? 'playing' : 'paused');

      await HomeWidget.updateWidget(
        name: _androidAudioWidgetName,
        androidName: _androidAudioWidgetName,
        iOSName: _iOSAudioWidgetName,
      );
    } catch (e) {
      if (kDebugMode) {
        print('WidgetUpdateService setAudioWidgetPlaying Error: $e');
      }
    }
  }
}

