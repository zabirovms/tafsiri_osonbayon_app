import 'package:flutter/foundation.dart' show debugPrint, ChangeNotifier;

import '../../../data/datasources/remote/alquran_cloud_api.dart';
import '../../../data/datasources/remote/api_service.dart';
import '../../../data/models/alquran_cloud_models.dart';
import '../../../data/models/surah_model.dart';
import '../../../data/models/verse_model.dart';
import '../../../data/repositories/integrated_quran_repository.dart';
import '../../../data/models/word_by_word_model.dart';
import '../../../core/constants/audio_constants.dart';

class SurahViewState {
  SurahViewState({
    required this.loading,
    this.error,
    this.surah,
    this.verses = const [],
    this.arabic = const [],
    this.audio = const [],
    this.audioEdition = AudioConstants.defaultReciter,
    this.juzStarts = const [],
    this.hizbStarts = const [],
    this.rukuStarts = const [],
    this.manzilStarts = const [],
    this.pageStarts = const [],
    this.wordByWord = const {},
    this.currentAyahIndex = 0,
    this.repeatMode = RepeatMode.off,
    this.repeatRange,
    this.wordByWordAvailable = true,
    this.showWordByWordError = false,
  });

  final bool loading;
  final String? error;
  final SurahModel? surah;
  final List<VerseModel> verses;
  final List<AqcAyah> arabic;
  final List<AqcAyah> audio;
  final String audioEdition;
  final List<int> juzStarts;
  final List<int> hizbStarts;
  final List<int> rukuStarts;
  final List<int> manzilStarts;
  final List<int> pageStarts;
  final Map<String, List<WordByWordModel>> wordByWord;
  final int currentAyahIndex; // 0-based
  final RepeatMode repeatMode;
  final (int, int)? repeatRange; // inclusive 1-based
  final bool wordByWordAvailable;
  final bool showWordByWordError;

  SurahViewState copyWith({
    bool? loading,
    String? error,
    SurahModel? surah,
    List<VerseModel>? verses,
    List<AqcAyah>? arabic,
    List<AqcAyah>? audio,
    String? audioEdition,
    List<int>? juzStarts,
    List<int>? hizbStarts,
    List<int>? rukuStarts,
    List<int>? manzilStarts,
    List<int>? pageStarts,
    Map<String, List<WordByWordModel>>? wordByWord,
    int? currentAyahIndex,
    RepeatMode? repeatMode,
    (int, int)? repeatRange,
    bool? wordByWordAvailable,
    bool? showWordByWordError,
  }) {
    return SurahViewState(
      loading: loading ?? this.loading,
      error: error,
      surah: surah ?? this.surah,
      verses: verses ?? this.verses,
      arabic: arabic ?? this.arabic,
      audio: audio ?? this.audio,
      audioEdition: audioEdition ?? this.audioEdition,
      juzStarts: juzStarts ?? this.juzStarts,
      hizbStarts: hizbStarts ?? this.hizbStarts,
      rukuStarts: rukuStarts ?? this.rukuStarts,
      manzilStarts: manzilStarts ?? this.manzilStarts,
      pageStarts: pageStarts ?? this.pageStarts,
      wordByWord: wordByWord ?? this.wordByWord,
      currentAyahIndex: currentAyahIndex ?? this.currentAyahIndex,
      repeatMode: repeatMode ?? this.repeatMode,
      repeatRange: repeatRange ?? this.repeatRange,
      wordByWordAvailable: wordByWordAvailable ?? this.wordByWordAvailable,
      showWordByWordError: showWordByWordError ?? this.showWordByWordError,
    );
  }
}

class SurahController extends ChangeNotifier {
  SurahController({required ApiService apiService, required AlQuranCloudApi aqc})
      : _repo = IntegratedQuranRepository(apiService: apiService, aqc: aqc);

  final IntegratedQuranRepository _repo;
  SurahViewState state = SurahViewState(loading: false);

  // Set audio edition without loading data (optimized - no network calls)
  void setAudioEdition(String audioEdition) {
    state = state.copyWith(audioEdition: audioEdition);
    notifyListeners();
  }

  // Load word-by-word data lazily (only when user enables word-by-word mode)
  // Uses local verses to get keys - no need to load from Supabase
  Future<void> loadWordByWord(List<VerseModel> localVerses) async {
    // If already loaded, don't reload
    if (state.wordByWord.isNotEmpty) {
      return;
    }

    state = state.copyWith(loading: true);
    notifyListeners();

    try {
      // Use local verses to get keys (same format as Supabase)
      final keys = localVerses.map((v) => v.uniqueKey).toList();
      final wbw = await _repo.getWordByWordByKeys(keys);
      
      state = state.copyWith(
        loading: false,
        wordByWord: wbw,
        wordByWordAvailable: wbw.isNotEmpty,
        showWordByWordError: false,
      );
      notifyListeners();
    } catch (e) {
      // Check if it's a network error
      final isNetworkError = e.toString().contains('NETWORK_ERROR');
      state = state.copyWith(
        loading: false,
        wordByWordAvailable: !isNetworkError,
        showWordByWordError: isNetworkError,
      );
      notifyListeners();
      
      if (isNetworkError) {
        debugPrint('Word-by-word data unavailable (network error): $e');
      } else {
        debugPrint('Word-by-word data unavailable: $e');
      }
    }
  }

  // Legacy method for compatibility (no longer loads data)
  Future<void> changeAudioEdition({required int surahNumber, required String audioEdition}) async {
    setAudioEdition(audioEdition);
  }

  void setCurrentAyahIndex(int index) {
    state = state.copyWith(currentAyahIndex: index);
    notifyListeners();
  }

  void showWordByWordError() {
    state = state.copyWith(showWordByWordError: true);
    notifyListeners();
  }

  void hideWordByWordError() {
    state = state.copyWith(showWordByWordError: false);
    notifyListeners();
  }
}

enum RepeatMode { off, ayah, range, ruku, hizbQuarter }

