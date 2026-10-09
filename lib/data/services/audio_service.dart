import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint;
import 'dart:async';
import '../../core/platform/service_registry.dart';
import '../../core/utils/audio_url_builder.dart';
import '../../core/constants/audio_constants.dart';
import 'audio_downloads_service.dart';
import 'audio_manifest_service_v2.dart';
import 'analytics_service.dart';
import 'reciter_data_service.dart';
import 'tajik_audio_service.dart';
import 'alignment_data_service.dart';
import 'widget_update_service.dart';
import '../../data/models/reciter_model.dart';


  // Removed unused ApiService import

  // Conditional import for File/Directory operations
  import 'audio_service_io.dart' if (dart.library.html) 'audio_service_web.dart';

class PlaybackStateInfo {
  final bool isPlaying;
  final ProcessingState processingState;
  final Duration position;
  final Duration bufferedPosition;
  final Duration? duration;
  final int? currentSurahNumber;
  final int? currentVerseNumber;
  final String? currentUrl;
  final String? currentEdition; // Reciter/translation edition ID
  final int? currentWordNumber; // Current word number (1-based) for highlighting during verse playback
  final bool autoPlayNextVerse;

  const PlaybackStateInfo({
    required this.isPlaying,
    required this.processingState,
    required this.position,
    required this.bufferedPosition,
    required this.duration,
    required this.currentSurahNumber,
    required this.currentVerseNumber,
    required this.currentUrl,
    this.currentEdition,
    this.currentWordNumber,
    this.autoPlayNextVerse = false,
  });
}

class QuranAudioService {
    static final QuranAudioService _instance = QuranAudioService._internal();
    late AudioPlayer _audioPlayer;
    AudioHandler? _audioHandler;
    String? _currentUrl;
    String _currentEdition = AudioConstants.defaultReciter;
    bool _isRepeating = false; // Repeat current surah when finished
    bool _autoPlayNextVerse = false; // Auto-play next verse when current verse finishes
    // Removed manifest service dependency - using hardcoded URL construction
    
    /// Check if an edition supports verse-by-verse audio (using centralized list)
    bool _supportsVerseByVerse(String edition) {
      return AudioManifestServiceV2.supportsVerseByVerse(edition);
    }
    
    /// Get the appropriate bitrate for verse-by-verse audio for a given CDN reciter ID
    /// Uses centralized method from AudioManifestServiceV2
    int _getVerseByVerseBitrate(String cdnId) {
      return AudioManifestServiceV2.getVerseByVerseBitrate(cdnId);
    }
    
    /// Get the appropriate bitrate for full surah audio for a given CDN reciter ID
    /// Uses hardcoded bitrate map from AudioManifestServiceV2 (no network dependency)
    int _getSurahBitrate(String cdnId) {
      // Get bitrate, default to default bitrate if not confirmed (for backward compatibility)
      // But this should only be called for confirmed reciters
      return AudioManifestServiceV2.getSurahBitrate(cdnId) ?? AudioConstants.defaultBitrate;
    }
    
    // Cache for surah names in Tajik (instant 0ms lookup without DB disk I/O)
    static const Map<int, String> _surahNamesTajikMap = <int, String>{
      1: 'Ал-Фотиҳа', 2: 'Ал-Бақара', 3: 'Оли Имрон', 4: 'Ан-Нисо', 5: 'Ал-Маида',
      6: 'Ал-Анъом', 7: 'Ал-Аъроф', 8: 'Ал-Анфол', 9: 'Ат-Тавба', 10: 'Юнус',
      11: 'Ҳуд', 12: 'Юсуф', 13: 'Ар-Раъд', 14: 'Иброҳим', 15: 'Ал-Ҳиҷр',
      16: 'Ан-Наҳл', 17: 'Ал-Исро', 18: 'Ал-Каҳф', 19: 'Марям', 20: 'Тоҳо',
      21: 'Ал-Анбиё', 22: 'Ал-Ҳаҷҷ', 23: 'Ал-Муъминун', 24: 'Ан-Нур', 25: 'Ал-Фурқон',
      26: 'Аш-Шуъаро', 27: 'Ан-Намл', 28: 'Ал-Қасас', 29: 'Ал-Анкабут', 30: 'Ар-Рум',
      31: 'Луқмон', 32: 'Ас-Саҷда', 33: 'Ал-Аҳзоб', 34: 'Сабаъ', 35: 'Фотир',
      36: 'Ясин', 37: 'Ас-Соффот', 38: 'Сод', 39: 'Аз-Зумар', 40: 'Ғофир',
      41: 'Фуссилат', 42: 'Аш-Шуро', 43: 'Аз-Зухруф', 44: 'Ад-Духон', 45: 'Ал-Ҷосия',
      46: 'Ал-Аҳқоф', 47: 'Муҳаммад', 48: 'Ал-Фатҳ', 49: 'Ал-Ҳуҷурот', 50: 'Қоф',
      51: 'Аз-Зориёт', 52: 'Ат-Тур', 53: 'Ан-Наҷм', 54: 'Ал-Қамар', 55: 'Ар-Раҳмон',
      56: 'Ал-Воқиа', 57: 'Ал-Ҳадид', 58: 'Ал-Муҷодала', 59: 'Ал-Ҳашр', 60: 'Ал-Мумтаҳана',
      61: 'Ас-Сафф', 62: 'Ал-Ҷумъа', 63: 'Ал-Мунофиқун', 64: 'Ат-Тағобун', 65: 'Ат-Талақ',
      66: 'Ат-Таҳрим', 67: 'Ал-Мулк', 68: 'Ал-Қалам', 69: 'Ал-Ҳоққа', 70: 'Ал-Маъориҷ',
      71: 'Нуҳ', 72: 'Ал-Ҷинн', 73: 'Ал-Муззаммил', 74: 'Ал-Муддассир', 75: 'Ал-Қиёма',
      76: 'Ал-Инсон', 77: 'Ал-Мурсалот', 78: 'Ан-Набоъ', 79: 'Ан-Назиъот', 80: 'Абаса',
      81: 'Ат-Таквир', 82: 'Ал-Инфитор', 83: 'Ал-Мутоффифин', 84: 'Ал-Иншиқоқ', 85: 'Ал-Буруҷ',
      86: 'Ат-Ториқ', 87: 'Ал-Аъло', 88: 'Ал-Ғошия', 89: 'Ал-Фаҷр', 90: 'Ал-Балад',
      91: 'Аш-Шамс', 92: 'Ал-Лайл', 93: 'Ад-Дуҳо', 94: 'Аш-Шарҳ', 95: 'Ат-Тин',
      96: 'Ал-Алақ', 97: 'Ал-Қадр', 98: 'Ал-Баййина', 99: 'Аз-Залзала', 100: 'Ал-Адиёт',
      101: 'Ал-Қориа', 102: 'Ат-Такасур', 103: 'Ал-Аср', 104: 'Ал-Ҳумаза', 105: 'Ал-Фил',
      106: 'Қурайш', 107: 'Ал-Маъун', 108: 'Ал-Кавсар', 109: 'Ал-Кафирун', 110: 'Ан-Наср',
      111: 'Ал-Масад', 112: 'Ал-Ихлос', 113: 'Ал-Фалақ', 114: 'Ан-Нас',
    };

    // Get surah name in Tajik
    Future<String> _getSurahNameTajik(int surahNumber) async {
      return _surahNamesTajikMap[surahNumber] ?? 'Сураи $surahNumber';
    }
    
    // Get Qari name in Tajik (proper name from JSON)
    // Uses ReciterDataService to get nameTajik from JSON files
    Future<String> _getQariName(String edition) async {
      final service = ReciterDataService.instance;
      // Try full surah first
      final fullSurahReciters = await service.getFullSurahReciters(confirmedOnly: false);
      final reciter = fullSurahReciters.firstWhere(
        (r) => r.id == edition,
        orElse: () {
          // If not found in full surah, try verse-by-verse
          return ReciterModel(id: edition, name: '', nameTajik: '', nameArabic: '');
        },
      );
      
      // If found, return nameTajik (preferred) or name as fallback
      if (reciter.id == edition) {
        if (reciter.nameTajik.isNotEmpty && reciter.nameTajik != reciter.id) {
          return reciter.nameTajik;
        }
        if (reciter.name.isNotEmpty && reciter.name != reciter.id) {
          return reciter.name;
        }
      }
      
      // Try verse-by-verse
      final verseReciters = await service.getVerseByVerseReciters();
      final verseReciter = verseReciters.firstWhere(
        (r) => r.id == edition,
        orElse: () => ReciterModel(id: edition, name: '', nameTajik: '', nameArabic: ''),
      );
      
      // Return nameTajik (preferred) or name as fallback
      if (verseReciter.nameTajik.isNotEmpty && verseReciter.nameTajik != verseReciter.id) {
        return verseReciter.nameTajik;
      }
      if (verseReciter.name.isNotEmpty && verseReciter.name != verseReciter.id) {
        return verseReciter.name;
      }
      
      // Last resort: return empty string (will be handled by caller)
      return '';
    }
  
  // Unified UI state stream to keep widgets in sync
  final StreamController<PlaybackStateInfo> _uiStateController = StreamController<PlaybackStateInfo>.broadcast();
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _bufferedSub;
  StreamSubscription<Duration?>? _durationSub;
    
    // Track current playing verse
    int? _currentSurahNumber;
    int? _currentVerseNumber;

    // Number of verses per surah (1..114)
    static const List<int> _versesPerSurah = <int>[
      7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128, 111,
      110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73, 54, 45,
      83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60, 49, 62, 55,
      78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52, 44, 28, 28, 20,
      56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21,
      11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6
    ];

    static int _globalAyahNumber(int surahNumber, int verseNumber) {
      int offset = 0;
      for (int i = 0; i < surahNumber - 1; i++) {
        offset += _versesPerSurah[i];
      }
      return offset + verseNumber;
    }

    QuranAudioService._internal() {
      _audioPlayer = AudioPlayer();
      // Handler will be set after AudioService.init in main.dart
      // We'll get it lazily when needed
      // Keep internal state in sync with player lifecycle (release safety)
    _playerStateSub = _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          // Only handle completion for verse/surah playback, not word audio
          if (_currentUrl != null) {
            // Check if repeat is enabled
            if (_isRepeating && _currentSurahNumber != null && _currentVerseNumber == null) {
              // Replay the current surah from the beginning
              debugPrint('[Audio] Playback completed - repeating surah $_currentSurahNumber');
              playSurah(_currentSurahNumber!, edition: _currentEdition, userInitiated: false);
            } else if (_autoPlayNextVerse && _currentSurahNumber != null && _currentVerseNumber != null) {
              // Auto-play next verse when current verse finishes
              debugPrint('[Audio] Verse completed - auto-playing next verse');
              playNextVerse(edition: _currentEdition, userInitiated: false);
            } else {
              // Autoplay disabled - just stop at the end
              debugPrint('[Audio] Playback completed - stopping (autoplay disabled)');
            }
          } else if (_currentWordAudioUrl != null) {
            // Word audio completed - clear word audio state silently
            _currentWordAudioUrl = null;
            _currentWordSurah = null;
            _currentWordVerse = null;
            _currentWordNumber = null;
          }
        }
        if (state.processingState == ProcessingState.idle) {
          // Player was stopped/released; clear URL reference
          if (_currentUrl != null) {
            _currentUrl = null;
            _emitUiState();
          }
          // Also clear word audio state
          if (_currentWordAudioUrl != null) {
            _currentWordAudioUrl = null;
            _currentWordSurah = null;
            _currentWordVerse = null;
            _currentWordNumber = null;
          }
        } else if (_currentUrl != null) {
          // Only emit UI state for verse/surah playback (not word audio)
          _emitUiState();
        }
      });

    // Forward core streams into a single UI state stream
    // Position updates frequently - only emit UI state, don't update handler
    _positionSub = _audioPlayer.positionStream.listen((position) {
      // Only emit UI state if we have verse playback (not word audio)
      // Word audio doesn't have _currentUrl set, so we can check that
      if (_currentUrl != null) {
        _emitUiStateOnly();
        // Update current word if we have alignment data (for verse playback highlighting)
        if (_currentSurahNumber != null && _currentVerseNumber != null) {
          _updateCurrentWord(position.inMilliseconds);
        }
      }
    });
    _bufferedSub = _audioPlayer.bufferedPositionStream.listen((_) {
      // Only emit UI state for verse/surah playback (not word audio)
      if (_currentUrl != null) {
        _emitUiStateOnly();
      }
    });
    // Duration changes are less frequent - can update handler
    _durationSub = _audioPlayer.durationStream.listen((_) {
      // Only emit UI state for verse/surah playback (not word audio)
      if (_currentUrl != null) {
        _emitUiState();
      }
    });
    // Seed initial UI state so subscribers have an immediate snapshot
    _emitUiState();
    }

    factory QuranAudioService() => _instance;

    // Removed unused _ensureInitialized method

    // Play surah audio using AlQuran Cloud CDN or local file if downloaded
    // Returns a result message for UI display, or null if successful
    Future<String?> playSurah(int surahNumber, {String edition = AudioConstants.defaultReciter, bool userInitiated = true}) async {
      String? audioUrl; // Declare outside try block for error logging
      try {
        if (surahNumber < 1 || surahNumber > 114) {
          throw Exception('Invalid surah number: $surahNumber');
        }
        await _ensureBindingReady();
        
        // Check if downloaded file exists
        final downloadsService = AudioDownloadsService();
        final downloadedPath = await downloadsService.getDownloadPath(edition, surahNumber);
        
        if (downloadedPath != null) {
          // Use downloaded file
          audioUrl = downloadedPath;
          debugPrint('[Audio] Using downloaded file for surah $surahNumber edition=$edition -> $audioUrl');
        } else {
          // Check if this is Tajik translation audio (uses separate API)
          if (edition == 'tg.akmal_mansurov' || edition == 'tg.abuabdurrahman') {
            final tajikAudioService = TajikAudioService();
            final tajikUrl = await tajikAudioService.getAudioUrlForSurah(surahNumber);
            if (tajikUrl != null) {
              audioUrl = tajikUrl;
              debugPrint('[Audio] Using Tajik translation API URL for surah $surahNumber -> $audioUrl');
            } else {
              throw Exception('Tajik audio not available for surah $surahNumber');
            }
          } else {
            // Use centralized URL construction (no manifest dependency)
            // Edition is already a CDN ID, no conversion needed
            final cdnEdition = edition;
            // Get appropriate bitrate for this reciter (most use 128, but some use 192 or 64)
            final bitrate = _getSurahBitrate(cdnEdition);
            audioUrl = AudioUrlBuilder.buildSurahUrl(cdnEdition, surahNumber, bitrate: bitrate);
            debugPrint('[Audio] Using centralized URL for surah $surahNumber edition=$edition (CDN: $cdnEdition, bitrate: $bitrate) -> $audioUrl');
          }
        }
        
        if (_currentUrl == audioUrl && _audioPlayer.playing) {
          return null; // already playing this track
        }
        _currentUrl = audioUrl;
        _currentSurahNumber = surahNumber;
        _currentVerseNumber = null; // Clear verse number for surah playback
        _currentEdition = edition;
        // Clear alignment data for full surah mode
        _currentAlignment = null;
        _isLoadingAlignment = false;
        _currentVerseWordNumber = null;
        
        if (audioUrl.isEmpty) {
          throw Exception('Failed to construct audio URL for surah $surahNumber');
        }
        debugPrint('[Audio] Setting URL: $audioUrl');
        if (audioUrl.startsWith('http://') || audioUrl.startsWith('https://')) {
          await _audioPlayer.setUrl(audioUrl);
        } else {
          await _audioPlayer.setFilePath(audioUrl);
        }
        debugPrint('[Audio] URL set, starting playback...');
        await _audioPlayer.play();
        debugPrint('[Audio] Playback started successfully');
        if (userInitiated) {
          AnalyticsService().logAudioPlay(reciterId: edition, surahNumber: surahNumber, source: 'surah');
        }
        _emitUiState();
        return null; // Success
      } catch (e, stackTrace) {
        debugPrint('[Audio][Error] playSurah failed for edition=$edition: $e');
        debugPrint('[Audio][Error] Stack trace: $stackTrace');
        if (audioUrl != null) {
          debugPrint('[Audio][Error] URL was: $audioUrl');
        } else {
          debugPrint('[Audio][Error] URL was not constructed (error occurred before URL creation)');
        }
        
        // Update widget with error state
        _emitErrorState(surahNumber, edition);
        
        // Determine user-friendly error message using constants
        String errorMessage;
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('unknownhostexception') ||
            errStr.contains('socketexception') ||
            errStr.contains('no address associated with hostname') ||
            errStr.contains('network') ||
            errStr.contains('connection')) {
          errorMessage = AudioConstants.errorNetworkConnection;
        } else if (errStr.contains('404') || errStr.contains('not found')) {
          errorMessage = AudioConstants.errorReciterNotAvailable;
        } else {
          errorMessage = AudioConstants.errorPlaybackFailed;
        }
        
        return errorMessage;
      }
    }
    
    // Ensure handler is connected for notification controls
    // This gets the handler instance that AudioService.init() created
    // The static instance is set in QuranAudioHandler constructor, which is called by AudioService.init()
    void _ensureHandlerConnected() {
      if (_audioHandler == null) {
        _audioHandler = QuranAudioHandler.instance;
        if (_audioHandler != null) {
          debugPrint('[Audio] Handler connected: ${_audioHandler.runtimeType}');
          debugPrint('[Audio] Handler instance hash: ${identityHashCode(_audioHandler)}');
          debugPrint('[Audio] This is the same instance Android uses for notification controls');
        } else {
          debugPrint('[Audio] Warning: Handler not yet available - call QuranAudioBinding.ensureInitialized() before playback');
        }
      }
    }

    /// Binds `audio_service` (Android foreground service + media session) on first use only.
    Future<void> _ensureBindingReady() async {
      await QuranAudioBinding.ensureInitialized();
      _ensureHandlerConnected();
    }
    
    // Play previous surah
    Future<void> playPreviousSurah({String edition = AudioConstants.defaultReciter}) async {
      _currentEdition = edition;
      if (_currentSurahNumber == null) return;
      
      int prevSurah = _currentSurahNumber! - 1;
      if (prevSurah < 1) {
        return; // Already at first surah
      }
      
      await playSurah(prevSurah, edition: _currentEdition);
    }
    
    // Play next surah
    Future<void> playNextSurah({String edition = AudioConstants.defaultReciter}) async {
      _currentEdition = edition;
      if (_currentSurahNumber == null) return;
      
      int nextSurah = _currentSurahNumber! + 1;
      if (nextSurah > AudioConstants.totalSurahs) {
        return; // Already at last surah
      }
      
      await playSurah(nextSurah, edition: _currentEdition);
    }

    // Play verse audio using AlQuran Cloud CDN
    Future<void> playVerse(int surahNumber, int verseNumber, {String edition = AudioConstants.defaultReciter, Duration? startPosition, bool userInitiated = true}) async {
      try {
        if (surahNumber < 1 || surahNumber > 114) {
          throw Exception('Invalid surah number: $surahNumber');
        }
        final maxVerses = _versesPerSurah[surahNumber - 1];
        if (verseNumber < 1 || verseNumber > maxVerses) {
          throw Exception('Invalid verse number $verseNumber for surah $surahNumber (max: $maxVerses)');
        }
        await _ensureBindingReady();
        
        // Check if this edition supports verse-by-verse audio (using centralized list)
        if (!_supportsVerseByVerse(edition)) {
          throw Exception(
            AudioConstants.errorVerseByVerseNotSupported.replaceAll('%s', edition)
          );
        }
        
        final global = _globalAyahNumber(surahNumber, verseNumber);
        // Build URL using centralized URL builder (no manifest dependency for verse-by-verse)
        // Edition is already a CDN ID, no conversion needed
        final cdnEdition = edition;
        // Get bitrate for this reciter (most use 128, but some use 192, 64, or 32)
        final bitrate = _getVerseByVerseBitrate(cdnEdition);
        final audioUrl = AudioUrlBuilder.buildVerseUrl(cdnEdition, global, bitrate: bitrate);
        debugPrint('[Audio] Play verse $surahNumber:$verseNumber edition=$edition (CDN: $cdnEdition, bitrate: $bitrate) -> $audioUrl');
        if (_currentUrl == audioUrl && _audioPlayer.playing && startPosition == null) {
          return; // already playing this ayah
        }
        _currentUrl = audioUrl;
        _currentSurahNumber = surahNumber;
        _currentVerseNumber = verseNumber;
        _currentEdition = edition;
        // Clear previous alignment data
        _currentAlignment = null;
        _isLoadingAlignment = false;
        _currentVerseWordNumber = null; // Reset word tracking
        debugPrint('[Audio] Play verse $surahNumber:$verseNumber edition=$edition -> $audioUrl');
        await _audioPlayer.setUrl(audioUrl);
        if (startPosition != null) {
          // Wait for audio to load, then seek to position
          await _audioPlayer.play();
          // Wait a bit for the audio to start loading
          await Future.delayed(const Duration(milliseconds: 100));
          await _audioPlayer.seek(startPosition);
        } else {
          await _audioPlayer.play();
        }
        if (userInitiated) {
          AnalyticsService().logAudioPlay(reciterId: edition, surahNumber: surahNumber, source: 'verse');
        }
      _emitUiState();
      } catch (e) {
        debugPrint('[Audio][Error] playVerse failed: $e');
        _emitErrorState(surahNumber, edition);
        throw Exception('Failed to play verse audio: $e');
      }
    }

    /// Play verse from a specific word position
    /// If verse is already playing, seeks to word position
    /// If verse is not playing, starts playing from word position
    Future<void> playVerseFromWord(int surahNumber, int verseNumber, int wordNumber, {String edition = AudioConstants.defaultReciter}) async {
      try {
        debugPrint('[Audio] playVerseFromWord called: surah=$surahNumber, verse=$verseNumber, word=$wordNumber, edition=$edition');
        
        // Get alignment data for this reciter and verse
        final alignment = await _alignmentService.getAlignmentForVerse(
          edition,
          surahNumber,
          verseNumber,
        );
        
        if (alignment == null) {
          // No alignment data, fall back to regular verse playback
          debugPrint('[Audio] No alignment data for $surahNumber:$verseNumber, playing from start');
          await playVerse(surahNumber, verseNumber, edition: edition);
          return;
        }
        
        // Get word start time
        final wordStartTimeSeconds = _alignmentService.getWordStartTime(alignment, wordNumber);
        
        if (wordStartTimeSeconds == null) {
          // Word not found in alignment, fall back to regular verse playback
          debugPrint('[Audio] Word $wordNumber not found in alignment for $surahNumber:$verseNumber, playing from start');
          await playVerse(surahNumber, verseNumber, edition: edition);
          return;
        }
        
        final startPosition = Duration(milliseconds: (wordStartTimeSeconds * 1000).round());
        debugPrint('[Audio] Word $wordNumber start time: ${startPosition.inMilliseconds}ms (${wordStartTimeSeconds}s)');
        
        // Check if this verse is already playing (same logic as web-static)
        final isSameVerse = _currentSurahNumber == surahNumber && 
                           _currentVerseNumber == verseNumber &&
                           _currentUrl != null;
        final isPlaying = _audioPlayer.playing;
        
        debugPrint('[Audio] playVerseFromWord: isSameVerse=$isSameVerse, isPlaying=$isPlaying, currentSurah=$_currentSurahNumber, currentVerse=$_currentVerseNumber, currentUrl=$_currentUrl');
        
        if (isSameVerse) {
          // Same verse is loaded - seek to word position
          if (isPlaying) {
            // Verse is currently playing - just seek to word position (same as web-static)
            debugPrint('[Audio] Seeking to word $wordNumber position: ${startPosition.inMilliseconds}ms');
            await seekTo(startPosition);
            debugPrint('[Audio] Seek completed');
          } else if (_audioPlayer.playerState.processingState == ProcessingState.ready) {
            // Verse is loaded but paused - seek and resume
            debugPrint('[Audio] Verse paused, seeking to word $wordNumber and resuming: ${startPosition.inMilliseconds}ms');
            await seekTo(startPosition);
            await _audioPlayer.play();
            _emitUiState();
            debugPrint('[Audio] Seek and resume completed');
          } else {
            // Verse is loaded but not ready - wait a bit and try again, or just start from position
            debugPrint('[Audio] Verse loaded but not ready, starting from word position');
            await playVerse(surahNumber, verseNumber, edition: edition, startPosition: startPosition);
          }
        } else {
          // Different verse or no verse loaded - start playing verse from word position
          debugPrint('[Audio] Playing verse $surahNumber:$verseNumber from word $wordNumber position: ${startPosition.inMilliseconds}ms');
          await playVerse(surahNumber, verseNumber, edition: edition, startPosition: startPosition);
          debugPrint('[Audio] Verse playback started from word position');
        }
      } catch (e, stackTrace) {
        debugPrint('[Audio][Error] playVerseFromWord failed: $e');
        debugPrint('[Audio][Error] Stack trace: $stackTrace');
        // Fall back to regular verse playback
        await playVerse(surahNumber, verseNumber, edition: edition);
      }
    }

    // Play by direct URL (from AlQuran Cloud per-ayah audio)
    Future<void> playUrl(String url) async {
      try {
        await _ensureBindingReady();
        if (url.startsWith('http://') || url.startsWith('https://')) {
          await _audioPlayer.setUrl(url);
        } else {
          await _audioPlayer.setFilePath(url);
        }
        await _audioPlayer.play();
      } catch (e) {
        throw Exception('Failed to play audio url: $e');
      }
    }

    // Pause audio
    Future<void> pause() async {
      try {
        await _audioPlayer.pause();
        AnalyticsService().logAudioPause(reciterId: _currentEdition, surahNumber: _currentSurahNumber);
      _emitUiState();
      } catch (e) {
        debugPrint('[Audio][Error] pause failed: $e');
        if (_currentSurahNumber != null) {
          _emitErrorState(_currentSurahNumber!, _currentEdition);
        }
      }
    }

    // Resume audio
    Future<void> resume() async {
      try {
        await _audioPlayer.play();
      _emitUiState();
      } catch (e) {
        debugPrint('[Audio][Error] resume failed: $e');
        if (_currentSurahNumber != null) {
          _emitErrorState(_currentSurahNumber!, _currentEdition);
        }
      }
    }

    // Stop audio
    Future<void> stop() async {
      try {
        await _audioPlayer.stop();
        // Clear verse/surah playback state
        _currentUrl = null;
        _currentSurahNumber = null;
        _currentVerseNumber = null;
        _currentEdition = AudioConstants.defaultReciter; // Reset to default when stopping
        // Clear alignment data
        _currentAlignment = null;
        _isLoadingAlignment = false;
        _currentVerseWordNumber = null;
        _isRepeating = false; // Reset repeat when stopping
        _autoPlayNextVerse = false; // Reset auto-play when stopping
        // Clear word audio state
        _currentWordAudioUrl = null;
        _currentWordSurah = null;
        _currentWordVerse = null;
        _currentWordNumber = null;
        _emitUiState();
      } catch (e) {
        debugPrint('[Audio][Error] stop failed: $e');
      }
    }

    // Seek to position
    Future<void> seekTo(Duration position) async {
      try {
        await _audioPlayer.seek(position);
        // Emit UI state after seek to update position
        if (_currentUrl != null) {
          _emitUiStateOnly();
        }
      } catch (e) {
        debugPrint('[Audio][Error] seekTo failed: $e');
        rethrow;
      }
    }

    // Seek by delta (e.g., +/- 10 seconds)
    Future<void> seekBy(Duration delta) async {
      final current = _audioPlayer.position;
      final target = current + delta;
      final clip = target < Duration.zero ? Duration.zero : target;
      await _audioPlayer.seek(clip);
    }

    // Set volume
    Future<void> setVolume(double volume) async {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
    _emitUiState();
    }

    // Set playback speed
    Future<void> setSpeed(double speed) async {
      await _audioPlayer.setSpeed(speed.clamp(AudioConstants.minPlaybackSpeed, AudioConstants.maxPlaybackSpeed));
    _emitUiState();
    }

    // Get current playing verse
    int? get currentSurahNumber => _currentSurahNumber;
    int? get currentVerseNumber => _currentVerseNumber;
    String get currentEdition => _currentEdition;
    
    // Check if miniplayer is active (any verse/surah is loaded)
    // When miniplayer is open, word clicks should seek, not play individual word audio
    bool get hasActivePlayback => _currentUrl != null && _currentWordAudioUrl == null;
    
    // Check if a specific verse is currently playing (or loaded, even if paused)
    // This allows word clicks to seek even if the verse is paused
    bool isPlayingVerse(int surahNumber, int verseNumber) {
      final isSameVerse = _currentSurahNumber == surahNumber && 
                         _currentVerseNumber == verseNumber &&
                         _currentUrl != null; // Must have a verse URL loaded (not word audio)
      // Return true if same verse is loaded (playing or paused), but not if word audio is playing
      return isSameVerse && _currentWordAudioUrl == null;
    }
    
    // Check if current playback is this surah (full surah mode)
    bool isPlayingSurah(int surahNumber) {
      return _currentSurahNumber == surahNumber && _currentVerseNumber == null && _audioPlayer.playing;
    }
    
    // Play previous verse
    Future<void> playPreviousVerse({String edition = AudioConstants.defaultReciter}) async {
      _currentEdition = edition;
      if (_currentSurahNumber == null || _currentVerseNumber == null) {
        debugPrint('[Audio] playPreviousVerse: not in verse mode');
        return;
      }
      
      int prevSurah = _currentSurahNumber!;
      int prevVerse = _currentVerseNumber! - 1;
      
      if (prevVerse < 1) {
        // Go to previous surah
        if (prevSurah > 1) {
          prevSurah--;
          prevVerse = _versesPerSurah[prevSurah - 1];
        } else {
          debugPrint('[Audio] playPreviousVerse: already at first verse');
          return; // Already at first verse
        }
      }
      
      debugPrint('[Audio] playPreviousVerse: playing $prevSurah:$prevVerse');
      await playVerse(prevSurah, prevVerse, edition: _currentEdition);
    }
    
    // Play next verse
    Future<void> playNextVerse({String edition = AudioConstants.defaultReciter, bool userInitiated = true}) async {
      _currentEdition = edition;
      if (_currentSurahNumber == null || _currentVerseNumber == null) {
        debugPrint('[Audio] playNextVerse: not in verse mode');
        return;
      }
      
      int nextSurah = _currentSurahNumber!;
      int nextVerse = _currentVerseNumber! + 1;
      
      if (nextVerse > _versesPerSurah[nextSurah - 1]) {
        // Reached end of surah - stop auto-play
        debugPrint('[Audio] playNextVerse: reached end of surah $nextSurah, stopping auto-play');
        _autoPlayNextVerse = false;
        await stop();
        return;
      }
      
      debugPrint('[Audio] playNextVerse: playing $nextSurah:$nextVerse');
      await playVerse(nextSurah, nextVerse, edition: _currentEdition, userInitiated: userInitiated);
    }

    // Play surah verse-by-verse starting from verse 1 with auto-play
    Future<void> playSurahVerseByVerse(int surahNumber, {String edition = AudioConstants.defaultReciter}) async {
      try {
        // Check if edition supports verse-by-verse
        if (!_supportsVerseByVerse(edition)) {
          throw Exception(
            AudioConstants.errorVerseByVerseNotSupported.replaceAll('%s', edition)
          );
        }
        
        // Enable auto-play
        _autoPlayNextVerse = true;
        
        // Start playing from verse 1
        await playVerse(surahNumber, 1, edition: edition);
      } catch (e) {
        _autoPlayNextVerse = false;
        debugPrint('[Audio][Error] playSurahVerseByVerse failed: $e');
        rethrow;
      }
    }

    // Get current position
    Duration get position => _audioPlayer.position;

    // Get duration
    Duration? get duration => _audioPlayer.duration;

    // Get player state
    PlayerState get playerState => _audioPlayer.playerState;

    // Get processing state
    ProcessingState get processingState => _audioPlayer.processingState;

    // Listen to position changes
    Stream<Duration> get positionStream => _audioPlayer.positionStream;

    // Listen to buffered position changes (for smooth progress UI)
    Stream<Duration> get bufferedPositionStream => _audioPlayer.bufferedPositionStream;

    // Listen to player state changes
    Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

    // Listen to processing state changes
    Stream<ProcessingState> get processingStateStream => _audioPlayer.processingStateStream;

    // Listen to duration changes
    Stream<Duration?> get durationStream => _audioPlayer.durationStream;

    // Word-by-word audio playback
    String? _currentWordAudioUrl;
    int? _currentWordSurah;
    int? _currentWordVerse;
    int? _currentWordNumber; // For individual word audio playback
    
    // Word-by-word highlighting during verse playback
    int? _currentVerseWordNumber; // Current word number (1-based) for highlighting during verse playback
    dynamic _currentAlignment; // Current verse alignment data (VerseAlignment from alignment_data_service)
    final AlignmentDataService _alignmentService = AlignmentDataService();
    bool _isLoadingAlignment = false; // Flag to prevent concurrent alignment loads

    /// Play word-by-word audio for a specific word
    /// Note: This does NOT register to miniplayer (doesn't set _currentUrl)
    /// IMPORTANT: This will stop any current verse playback since it uses the same audio player
    Future<void> playWordAudio(int surahNumber, int verseNumber, int wordNumber) async {
      try {
        await _ensureBindingReady();
        // Build word audio URL (same pattern as web-static)
        final surah = surahNumber.toString().padLeft(3, '0');
        final verse = verseNumber.toString().padLeft(3, '0');
        final word = wordNumber.toString().padLeft(3, '0');
        final audioUrl = 'https://cdn.quran.tj/quran-audio-wbw/$surah/${surah}_${verse}_${word}.mp3';
        
        debugPrint('[Audio] Play word $surahNumber:$verseNumber:$wordNumber -> $audioUrl');
        
        // If already playing the same word, stop it
        if (_currentWordAudioUrl == audioUrl && _audioPlayer.playing) {
          await _audioPlayer.stop();
          _currentWordAudioUrl = null;
          _currentWordSurah = null;
          _currentWordVerse = null;
          _currentWordNumber = null;
          return;
        }
        
        // IMPORTANT: Don't clear _currentUrl, _currentSurahNumber, _currentVerseNumber
        // We want to preserve verse state so that when word audio finishes,
        // the verse can resume if needed. But we also don't want miniplayer to show.
        
        // Store word audio info (but don't set _currentUrl - this prevents miniplayer from showing)
        _currentWordAudioUrl = audioUrl;
        _currentWordSurah = surahNumber;
        _currentWordVerse = verseNumber;
        _currentWordNumber = wordNumber;
        
        // Note: setUrl will stop current playback, but we preserve verse state above
        await _audioPlayer.setUrl(audioUrl);
        await _audioPlayer.play();
        // Don't emit UI state - word audio shouldn't trigger miniplayer
      } catch (e) {
        debugPrint('[Audio][Error] playWordAudio failed: $e');
        // Silently fail - word audio may not be available for all words
        _currentWordAudioUrl = null;
        _currentWordSurah = null;
        _currentWordVerse = null;
        _currentWordNumber = null;
      }
    }

  /// Update current word based on playback position and alignment data
  Future<void> _updateCurrentWord(int currentTimeMs) async {
    // Only update if we're in verse-by-verse mode
    if (_currentSurahNumber == null || _currentVerseNumber == null) {
      return;
    }

    // Check if alignment data is available for this reciter
    // The edition is typically a CDN ID (like 'ar.alafasy'), which should match alignment map keys
    final reciterId = _currentEdition;
    
    if (!_alignmentService.hasAlignmentData(reciterId)) {
      // No alignment data for this reciter, clear word tracking
      if (_currentVerseWordNumber != null) {
        _currentVerseWordNumber = null;
        _emitUiStateOnly();
      }
      if (kDebugMode) {
        debugPrint('[AudioService] No alignment data for reciter: $reciterId');
      }
      return;
    }

    // Load alignment data if not already loaded (and not currently loading)
    if (_currentAlignment == null && !_isLoadingAlignment) {
      _isLoadingAlignment = true;
      try {
        final alignment = await _alignmentService.getAlignmentForVerse(
          reciterId,
          _currentSurahNumber!,
          _currentVerseNumber!,
        );
        _currentAlignment = alignment;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[AudioService] Failed to load alignment data: $e');
        }
        // Silently fail - alignment data is optional
      } finally {
        _isLoadingAlignment = false;
      }
    }

    // Get current word index from alignment (only if we have alignment data)
    if (_currentAlignment != null) {
      final wordIndex = _alignmentService.getCurrentWordIndex(_currentAlignment, currentTimeMs);
      final wordNumber = _alignmentService.wordIndexToWordNumber(wordIndex);
      
      // Only update if word number changed
      if (_currentVerseWordNumber != wordNumber) {
        if (kDebugMode && wordNumber != null) {
          debugPrint('[AudioService] Highlighting word $wordNumber at ${currentTimeMs}ms for verse ${_currentSurahNumber}:${_currentVerseNumber}');
        }
        _currentVerseWordNumber = wordNumber;
        _emitUiStateOnly();
      }
    } else if (kDebugMode) {
      debugPrint('[AudioService] No alignment data loaded for verse ${_currentSurahNumber}:${_currentVerseNumber}');
    }
  }

    /// Check if a specific word is currently playing
    bool isWordPlaying(int surahNumber, int verseNumber, int wordNumber) {
      return _audioPlayer.playing &&
          _currentWordSurah == surahNumber &&
          _currentWordVerse == verseNumber &&
          _currentWordNumber == wordNumber;
    }

    // Get current playback state snapshot
    PlaybackStateInfo get currentPlaybackState {
      final processingState = _audioPlayer.processingState;
      final isPlaying = _audioPlayer.playing && processingState != ProcessingState.completed;
      return PlaybackStateInfo(
        isPlaying: isPlaying,
        processingState: processingState,
        position: _audioPlayer.position,
        bufferedPosition: _audioPlayer.bufferedPosition,
        duration: _audioPlayer.duration,
        currentSurahNumber: _currentSurahNumber,
        currentVerseNumber: _currentVerseNumber,
        currentUrl: _currentUrl,
        currentEdition: _currentEdition,
        currentWordNumber: _currentVerseWordNumber,
        autoPlayNextVerse: _autoPlayNextVerse,
      );
    }

    // Auto-play next verse functionality
    bool get autoPlayNextVerse => _autoPlayNextVerse;

    void setAutoPlayNextVerse(bool value) {
      _autoPlayNextVerse = value;
      _emitUiState();
    }

    void toggleAutoPlayNextVerse() {
      _autoPlayNextVerse = !_autoPlayNextVerse;
      _emitUiState();
    }

    // Check if playing
    bool get isPlaying => _audioPlayer.playing;

    // Check if paused
    bool get isPaused => !_audioPlayer.playing && _audioPlayer.playerState.processingState == ProcessingState.ready;

    // Check if stopped
    bool get isStopped => _audioPlayer.playerState.processingState == ProcessingState.idle;
    
    // Repeat functionality
    bool get isRepeating => _isRepeating;
    
    void setRepeat(bool repeat) {
      _isRepeating = repeat;
      _emitUiState();
    }
    
    void toggleRepeat() {
      _isRepeating = !_isRepeating;
      _emitUiState();
    }

    // Get available reciters (AlQuran Cloud editions)
    // Note: This is now primarily fetched from API via recitersProvider
    // Keeping minimal fallback list for compatibility
    List<String> getAvailableReciters() {
      return [
        'ar.alafasy',        // Mishary Alafasy
        'ar.husary',         // Mahmoud Khalil Al-Husary
        'ar.minshawi',       // Muhammad Siddiq Al-Minshawi
      ];
    }

    // Get available translation audio editions
    // Note: This is now primarily fetched from API via translationAudioEditionsProvider
    // Keeping empty as translations are fetched dynamically
    List<String> getAvailableTranslationAudio() {
      return [];
    }

    // Toggle play/pause for current or target item
    Future<void> togglePlayPause({int? surahNumber, int? verseNumber, String? edition}) async {
      try {
        if (_audioPlayer.playing) {
          await _audioPlayer.pause();
          _emitUiState();
          return;
        }

        // If specific target provided, start that
        if (surahNumber != null) {
          // Use provided edition or current edition, fallback to default only if no current track
          final targetEdition = edition ?? _currentEdition;
          
          // If resuming the same loaded track, just play without resetting URL
          final isSameSurah = _currentSurahNumber == surahNumber && _currentVerseNumber == null;
          final isSameVerse = _currentSurahNumber == surahNumber && _currentVerseNumber == verseNumber;
          if (_currentUrl != null && (verseNumber == null ? isSameSurah : isSameVerse)) {
            await _audioPlayer.play();
            _emitUiState();
            return;
          }
          if (verseNumber == null) {
            await playSurah(surahNumber, edition: targetEdition);
          } else {
            await playVerse(surahNumber, verseNumber, edition: targetEdition);
          }
          return;
        }

        // Otherwise resume current track (preserve current edition)
        if (_currentUrl != null) {
          await _audioPlayer.play();
          _emitUiState();
        }
      } catch (e) {
        debugPrint('[Audio][Error] togglePlayPause failed: $e');
      }
    }

  // Unified UI state stream
  Stream<PlaybackStateInfo> get uiStateStream => _uiStateController.stream;

  // Emit UI state only (for frequent position updates) - don't update handler
  void _emitUiStateOnly() {
    final processingState = _audioPlayer.processingState;
    final isPlaying = _audioPlayer.playing && processingState != ProcessingState.completed;
    
    final info = PlaybackStateInfo(
      isPlaying: isPlaying,
      processingState: processingState,
      position: _audioPlayer.position,
      bufferedPosition: _audioPlayer.bufferedPosition,
      duration: _audioPlayer.duration,
      currentSurahNumber: _currentSurahNumber,
      currentVerseNumber: _currentVerseNumber,
      currentUrl: _currentUrl,
      currentEdition: _currentEdition,
      currentWordNumber: _currentVerseWordNumber, // Word number for verse playback highlighting
      autoPlayNextVerse: _autoPlayNextVerse,
    );
    if (!_uiStateController.isClosed) {
      _uiStateController.add(info);
    }
  }

  // Emits an error state specifically targeting home widget updates
  void _emitErrorState(int surahNumber, String edition) {
    _getSurahNameTajik(surahNumber).then((surahName) {
      _getQariName(edition).then((qariName) {
        unawaited(
          WidgetUpdateService.updateAudioWidgetState(
            isPlaying: false,
            surahName: 'Сураи $surahName',
            qariName: qariName.isNotEmpty ? qariName : 'Қорӣ',
            surahNumber: surahNumber,
            qariId: edition,
            audioState: 'error',
          )
        );
      }).catchError((_) {
        unawaited(
          WidgetUpdateService.updateAudioWidgetState(
            isPlaying: false,
            surahName: 'Сураи $surahName',
            qariName: 'Қорӣ',
            surahNumber: surahNumber,
            qariId: edition,
            audioState: 'error',
          )
        );
      });
    }).catchError((_) {
      unawaited(
        WidgetUpdateService.updateAudioWidgetState(
          isPlaying: false,
          surahName: 'Сураи $surahNumber',
          qariName: 'Қорӣ',
          surahNumber: surahNumber,
          qariId: edition,
          audioState: 'error',
        )
      );
    });
  }

  // Emit UI state and update handler (for significant state changes)
  void _emitUiState() {
    // When playback completes, isPlaying should be false even if _audioPlayer.playing is still true
    final processingState = _audioPlayer.processingState;
    final isPlaying = _audioPlayer.playing && processingState != ProcessingState.completed;
    
    final info = PlaybackStateInfo(
      isPlaying: isPlaying,
      processingState: processingState,
      position: _audioPlayer.position,
      bufferedPosition: _audioPlayer.bufferedPosition,
      duration: _audioPlayer.duration,
      currentSurahNumber: _currentSurahNumber,
      currentVerseNumber: _currentVerseNumber,
      currentUrl: _currentUrl,
      currentEdition: _currentEdition,
      currentWordNumber: _currentVerseWordNumber, // Word number for verse playback highlighting
      autoPlayNextVerse: _autoPlayNextVerse,
    );
    if (!_uiStateController.isClosed) {
      _uiStateController.add(info);
    }

    // Mirror state into system notification (lazy AudioService.init on first need)
    unawaited(_mirrorStateToMediaNotification());
  }

  Future<void> _mirrorStateToMediaNotification() async {
    if (_currentSurahNumber == null) {
      unawaited(WidgetUpdateService.clearAudioWidgetState());
      return;
    }
    await QuranAudioBinding.ensureInitialized();
    _ensureHandlerConnected();
    final handler = _audioHandler;
    if (handler == null) return;
    final quranHandler = handler as QuranAudioHandler?;
    if (quranHandler == null) return;

    final currentIsPlaying = _audioPlayer.playing && _audioPlayer.processingState != ProcessingState.completed;
    final String audioState;
    if (_audioPlayer.processingState == ProcessingState.loading ||
        _audioPlayer.processingState == ProcessingState.buffering) {
      audioState = 'loading';
    } else if (currentIsPlaying) {
      audioState = 'playing';
    } else {
      audioState = 'paused';
    }

    _getSurahNameTajik(_currentSurahNumber!).then((surahName) {
      final String title;
      if (_currentVerseNumber == null) {
        title = 'Сураи $surahName';
      } else {
        title = '$surahName - Ояти ${_currentVerseNumber}';
      }

      _getQariName(_currentEdition).then((qariName) {
        final artistName = qariName.isNotEmpty ? qariName : 'Қорӣ';
        final media = MediaItem(
          id: _currentUrl ?? 'quran_stream',
          album: 'Қуръон',
          title: title,
          artist: artistName,
          duration: _audioPlayer.duration,
        );
        quranHandler.updateFromExternal(
          isPlaying: _audioPlayer.playing,
          processingState: _audioPlayer.processingState,
          position: _audioPlayer.position,
          item: media,
        );
        
        // Sync to home widget (low frequency updates)
        unawaited(
          WidgetUpdateService.updateAudioWidgetState(
            isPlaying: currentIsPlaying,
            surahName: 'Сураи $surahName',
            qariName: artistName,
            surahNumber: _currentSurahNumber!,
            qariId: _currentEdition,
            audioState: audioState,
          )
        );
      }).catchError((e2) {
        debugPrint('[Audio] Error getting qari name: $e2');
        final media = MediaItem(
          id: _currentUrl ?? 'quran_stream',
          album: 'Қуръон',
          title: title,
          artist: 'Қорӣ',
          duration: _audioPlayer.duration,
        );
        quranHandler.updateFromExternal(
          isPlaying: _audioPlayer.playing,
          processingState: _audioPlayer.processingState,
          position: _audioPlayer.position,
          item: media,
        );

        // Sync to home widget (low frequency updates)
        unawaited(
          WidgetUpdateService.updateAudioWidgetState(
            isPlaying: currentIsPlaying,
            surahName: 'Сураи $surahName',
            qariName: 'Қорӣ',
            surahNumber: _currentSurahNumber!,
            qariId: _currentEdition,
            audioState: audioState,
          )
        );
      });
    }).catchError((e) {
      debugPrint('[Audio] Error loading surah name: $e');
      final String title;
      if (_currentVerseNumber == null) {
        title = 'Сураи ${_currentSurahNumber}';
      } else {
        title = 'Сураи ${_currentSurahNumber} - Ояти ${_currentVerseNumber}';
      }

      _getQariName(_currentEdition).then((qariName) {
        final artistName = qariName.isNotEmpty ? qariName : 'Қорӣ';
        final media = MediaItem(
          id: _currentUrl ?? 'quran_stream',
          album: 'Қуръон',
          title: title,
          artist: artistName,
          duration: _audioPlayer.duration,
        );
        quranHandler.updateFromExternal(
          isPlaying: _audioPlayer.playing,
          processingState: _audioPlayer.processingState,
          position: _audioPlayer.position,
          item: media,
        );
      }).catchError((e2) {
        debugPrint('[Audio] Error getting qari name in fallback: $e2');
        final media = MediaItem(
          id: _currentUrl ?? 'quran_stream',
          album: 'Қуръон',
          title: title,
          artist: 'Қорӣ',
          duration: _audioPlayer.duration,
        );
        quranHandler.updateFromExternal(
          isPlaying: _audioPlayer.playing,
          processingState: _audioPlayer.processingState,
          position: _audioPlayer.position,
          item: media,
        );
      });
    });
  }

  // Download audio file for offline use (not supported on web)
  Future<String> downloadAudioFile(String url, String fileName) async {
      if (kIsWeb) {
        // On web, we can't download files for offline use
        // Just return the URL for streaming
        return url;
      }
      
      try {
        final directory = await getApplicationDocumentsDirectory();
        final audioDir = Directory('${directory.path}/audio');
        if (!await audioDir.exists()) {
          await audioDir.create(recursive: true);
        }
        
        final filePath = '${audioDir.path}/$fileName';
        final file = File(filePath);
        
        if (await file.exists()) {
          return filePath; // File already exists
        }
        
        // Download the file
        await _audioPlayer.setUrl(url);
        // Note: This is a simplified implementation
        // In a real app, you'd use a proper download manager
        
        return filePath;
      } catch (e) {
        throw Exception('Failed to download audio file: $e');
      }
    }

  // Check if audio file exists locally (not supported on web)
  Future<bool> isAudioFileCached(String fileName) async {
      if (kIsWeb) {
        return false; // No caching on web
      }
      
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/audio/$fileName');
        return await file.exists();
      } catch (e) {
        return false;
      }
    }

  // Get cached audio file path (not supported on web)
  Future<String?> getCachedAudioPath(String fileName) async {
      if (kIsWeb) {
        return null; // No local files on web
      }
      
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/audio/$fileName');
        if (await file.exists()) {
          return file.path;
        }
        return null;
      } catch (e) {
        return null;
      }
    }

  // Dispose resources
  Future<void> dispose() async {
    try {
      _playerStateSub?.cancel();
      _positionSub?.cancel();
      _bufferedSub?.cancel();
      _durationSub?.cancel();
      await _audioPlayer.dispose();
      await _audioHandler?.stop();
      _uiStateController.close();
    } catch (e) {
      debugPrint('[Audio] Exception during dispose: $e');
    }
  }
}

// Audio handler for background playback
class QuranAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
    static QuranAudioHandler? _instance;
    StreamSubscription<Duration>? _positionSubscription;
    Timer? _positionUpdateTimer;
    
    QuranAudioHandler() {
      _instance = this;
      // Initialize empty queue - will be populated when playback starts
      queue.add([]);
      debugPrint('[AudioHandler] ========== QuranAudioHandler instance created ==========');
      debugPrint('[AudioHandler] Instance hash: ${identityHashCode(this)}');
      debugPrint('[AudioHandler] This is the instance that AudioService.init() created');
      debugPrint('[AudioHandler] Android will use THIS instance for notification controls');
      
      // Initialize playbackState with idle state
      // This ensures the service is ready to receive commands
      playbackState.add(PlaybackState(
        controls: [],
        systemActions: const {},
        processingState: AudioProcessingState.idle,
        playing: false,
        updatePosition: Duration.zero,
        speed: 1.0,
        queueIndex: 0,
      ));
      debugPrint('[AudioHandler] Initial playbackState set to idle');
      
      // Set up continuous position updates from the audio player
      _setupPositionUpdates();
    }
    
    @override
    Future<void> onTaskRemoved() async {
      debugPrint('[AudioHandler] onTaskRemoved called - stopping playback');
      await stop();
      await super.onTaskRemoved();
    }
    
    static QuranAudioHandler? get instance => _instance;
    
    void _setupPositionUpdates() {
      final audioService = QuranAudioService();
      // Subscribe to position stream for continuous updates
      _positionSubscription = audioService.positionStream.listen((position) {
        // Only update if we have an active media item
        final currentMediaItem = mediaItem.value;
        if (currentMediaItem != null && 
            currentMediaItem.id.isNotEmpty && 
            (audioService.isPlaying || audioService.isPaused)) {
          playbackState.add(playbackState.value.copyWith(
            updatePosition: position,
          ));
        }
      });
      
      // Also use a timer as a backup for position updates
      // This ensures the notification bar always has up-to-date position
      _positionUpdateTimer = Timer.periodic(const Duration(milliseconds: AudioConstants.positionUpdateIntervalMs), (timer) {
        final audioService = QuranAudioService();
        final currentMediaItem = mediaItem.value;
        if (currentMediaItem != null && 
            currentMediaItem.id.isNotEmpty && 
            (audioService.isPlaying || audioService.isPaused)) {
          final currentPosition = audioService.position;
          // CRITICAL: Always include controls when updating position
          // This ensures controls remain active even during position updates
          final currentState = playbackState.value;
          playbackState.add(currentState.copyWith(
            updatePosition: currentPosition,
            // Keep existing controls - don't lose them during position updates
            controls: currentState.controls,
            systemActions: currentState.systemActions,
          ));
        }
      });
    }
    
    void dispose() {
      debugPrint('[AudioHandler] dispose() called - cleaning up');
      _positionSubscription?.cancel();
      _positionUpdateTimer?.cancel();
    }

    void updateFromExternal({
      required bool isPlaying,
      required ProcessingState processingState,
      required Duration position,
      required MediaItem item,
    }) {
      debugPrint('[AudioHandler] updateFromExternal called: ${item.title}, isPlaying=$isPlaying');
      
      // CRITICAL: Update queue FIRST - this ensures proper service binding
      if (queue.value.isEmpty || queue.value.length != 1 || queue.value.first.id != item.id) {
        queue.add([item]);
        debugPrint('[AudioHandler] Queue updated with item: ${item.id}');
      }
      
      // Determine processing state and controls BEFORE setting mediaItem
      AudioProcessingState audioProc;
      switch (processingState) {
        case ProcessingState.idle:
          audioProc = AudioProcessingState.idle;
          break;
        case ProcessingState.loading:
          audioProc = AudioProcessingState.loading;
          break;
        case ProcessingState.buffering:
          audioProc = AudioProcessingState.buffering;
          break;
        case ProcessingState.ready:
          audioProc = AudioProcessingState.ready;
          break;
        case ProcessingState.completed:
          audioProc = AudioProcessingState.completed;
          break;
      }
      
      // Determine if we're in verse mode or surah mode (both support previous/next)
      final audioService = QuranAudioService();
      final isVerseMode = audioService.currentVerseNumber != null;
      final isSurahMode = audioService.currentSurahNumber != null && audioService.currentVerseNumber == null;
      
      // Build controls list with previous/next for both verse and surah mode
      final List<MediaControl> controls;
      if (isVerseMode || isSurahMode) {
        controls = isPlaying
            ? const [
                MediaControl.skipToPrevious,
                MediaControl.pause,
                MediaControl.skipToNext,
                MediaControl.stop,
              ]
            : const [
                MediaControl.skipToPrevious,
                MediaControl.play,
                MediaControl.skipToNext,
                MediaControl.stop,
              ];
      } else {
        controls = isPlaying
            ? const [MediaControl.pause, MediaControl.stop]
            : const [MediaControl.play, MediaControl.stop];
      }
      
      // Build system actions - include skip actions for both verse and surah mode
      // CRITICAL: systemActions must include ALL actions that correspond to controls
      final Set<MediaAction> systemActions = {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        // Always include play/pause actions
        MediaAction.play,
        MediaAction.pause,
        MediaAction.stop,
      };
      
      if (isVerseMode || isSurahMode) {
        systemActions.add(MediaAction.skipToNext);
        systemActions.add(MediaAction.skipToPrevious);
      }
      
      // CRITICAL: Set mediaItem and playbackState together
      // The audio_service package needs both set for proper MediaSession binding
      final wasIdle = playbackState.value.processingState == AudioProcessingState.idle;
      
      // Set mediaItem first to start the service
      mediaItem.add(item);
      debugPrint('[AudioHandler] MediaItem set: ${item.title}');
      
      // Set playbackState immediately after with all controls and actions
      // This ensures the MediaSession is fully configured
      final newState = PlaybackState(
        controls: controls,
        systemActions: systemActions,
        processingState: audioProc,
        playing: isPlaying,
        updatePosition: position,
        speed: 1.0,
        queueIndex: 0,
      );
      playbackState.add(newState);
      debugPrint('[AudioHandler] SystemActions include: play=${systemActions.contains(MediaAction.play)}, pause=${systemActions.contains(MediaAction.pause)}, skipNext=${systemActions.contains(MediaAction.skipToNext)}, skipPrev=${systemActions.contains(MediaAction.skipToPrevious)}');
      debugPrint('[AudioHandler] PlaybackState set: playing=$isPlaying, processingState=$audioProc');
      debugPrint('[AudioHandler] Controls: ${controls.length} controls, systemActions: ${systemActions.length} actions');
      debugPrint('[AudioHandler] MediaSession should now be active with all controls registered');
      
      // Log if this is the first time starting the service
      if (wasIdle && audioProc != AudioProcessingState.idle) {
        debugPrint('[AudioHandler] ========== Service starting with media item: ${item.title} ==========');
        debugPrint('[AudioHandler] Service should now be bound and ready for notification controls');
      }
    }

    @override
    Future<void> play() async {
      // Log to console AND system log for visibility
      debugPrint('[AudioHandler] ========== play() called from notification ==========');
      debugPrint('[AudioHandler] Instance hash: ${identityHashCode(this)}');
      debugPrint('[AudioHandler] Current playbackState.playing: ${playbackState.value.playing}');
      try {
        // Update state immediately for responsive UI
        final currentState = playbackState.value;
        final updatedControls = _updateControlsForState(currentState.controls, true);
        playbackState.add(currentState.copyWith(
          playing: true,
          controls: updatedControls,
        ));
        debugPrint('[AudioHandler] Updated playbackState.playing to: true');
        final audioService = QuranAudioService();
        await audioService.resume();
        debugPrint('[AudioHandler] play() completed successfully');
      } catch (e, stackTrace) {
        debugPrint('[AudioHandler] play() error: $e');
        debugPrint('[AudioHandler] stackTrace: $stackTrace');
        // Revert state on error
        playbackState.add(playbackState.value.copyWith(playing: false));
      }
    }

    @override
    Future<void> pause() async {
      // Log to console AND system log for visibility
      debugPrint('[AudioHandler] ========== pause() called from notification ==========');
      debugPrint('[AudioHandler] Instance hash: ${identityHashCode(this)}');
      debugPrint('[AudioHandler] Current playbackState.playing: ${playbackState.value.playing}');
      try {
        // Update state immediately for responsive UI
        final currentState = playbackState.value;
        final updatedControls = _updateControlsForState(currentState.controls, false);
        playbackState.add(currentState.copyWith(
          playing: false,
          controls: updatedControls,
        ));
        debugPrint('[AudioHandler] Updated playbackState.playing to: false');
        final audioService = QuranAudioService();
        await audioService.pause();
        debugPrint('[AudioHandler] pause() completed successfully');
      } catch (e, stackTrace) {
        debugPrint('[AudioHandler] pause() error: $e');
        debugPrint('[AudioHandler] stackTrace: $stackTrace');
        // Revert state on error
        playbackState.add(playbackState.value.copyWith(playing: true));
      }
    }
    
    // Helper method to update controls based on playing state
    List<MediaControl> _updateControlsForState(List<MediaControl> currentControls, bool isPlaying) {
      // Check if we have skip controls (verse or surah mode)
      final hasSkipControls = currentControls.contains(MediaControl.skipToPrevious) || 
                             currentControls.contains(MediaControl.skipToNext);
      
      if (hasSkipControls) {
        return isPlaying
            ? const [
                MediaControl.skipToPrevious,
                MediaControl.pause,
                MediaControl.skipToNext,
                MediaControl.stop,
              ]
            : const [
                MediaControl.skipToPrevious,
                MediaControl.play,
                MediaControl.skipToNext,
                MediaControl.stop,
              ];
      } else {
        return isPlaying
            ? const [MediaControl.pause, MediaControl.stop]
            : const [MediaControl.play, MediaControl.stop];
      }
    }

    @override
    Future<void> stop() async {
      debugPrint('[AudioHandler] stop() called from notification');
      // Update state immediately
      playbackState.add(playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.idle,
      ));
      await QuranAudioService().stop();
    }

    @override
    Future<void> seek(Duration position) async {
      debugPrint('[AudioHandler] seek() called from notification: $position');
      // Update position immediately
      playbackState.add(playbackState.value.copyWith(updatePosition: position));
      await QuranAudioService().seekTo(position);
    }
    
    // Override skipToQueueItem to handle custom navigation
    @override
    Future<void> skipToQueueItem(int index) async {
      debugPrint('[AudioHandler] skipToQueueItem called with index: $index');
      // For our use case, we handle navigation via skipToNext/Previous
      // This method is called when queue navigation is used
      // We'll let the default behavior handle it, but log it
      return super.skipToQueueItem(index);
    }

    @override
    Future<void> skipToNext() async {
      debugPrint('[AudioHandler] ========== skipToNext() called from notification ==========');
      debugPrint('[AudioHandler] Instance hash: ${identityHashCode(this)}');
      try {
        final audioService = QuranAudioService();
        // Update to loading state immediately
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.loading,
        ));
        
        if (audioService.currentVerseNumber != null) {
          // Verse mode - play next verse
          debugPrint('[AudioHandler] skipToNext: verse mode, playing next verse');
          await audioService.playNextVerse(edition: audioService.currentEdition);
        } else if (audioService.currentSurahNumber != null) {
          // Surah mode - play next surah
          debugPrint('[AudioHandler] skipToNext: surah mode, playing next surah');
          await audioService.playNextSurah(edition: audioService.currentEdition);
        } else {
          debugPrint('[AudioHandler] skipToNext: no active playback');
          // Revert loading state if no playback
          playbackState.add(playbackState.value.copyWith(
            processingState: AudioProcessingState.idle,
          ));
        }
      } catch (e) {
        debugPrint('[AudioHandler] skipToNext error: $e');
        // Revert to previous state on error
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.ready,
        ));
      }
    }

    @override
    Future<void> skipToPrevious() async {
      debugPrint('[AudioHandler] ========== skipToPrevious() called from notification ==========');
      debugPrint('[AudioHandler] Instance hash: ${identityHashCode(this)}');
      try {
        final audioService = QuranAudioService();
        // Update to loading state immediately
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.loading,
        ));
        
        if (audioService.currentVerseNumber != null) {
          // Verse mode - play previous verse
          debugPrint('[AudioHandler] skipToPrevious: verse mode, playing previous verse');
          await audioService.playPreviousVerse(edition: audioService.currentEdition);
        } else if (audioService.currentSurahNumber != null) {
          // Surah mode - play previous surah
          debugPrint('[AudioHandler] skipToPrevious: surah mode, playing previous surah');
          await audioService.playPreviousSurah(edition: audioService.currentEdition);
        } else {
          debugPrint('[AudioHandler] skipToPrevious: no active playback');
          // Revert loading state if no playback
          playbackState.add(playbackState.value.copyWith(
            processingState: AudioProcessingState.idle,
          ));
        }
      } catch (e) {
        debugPrint('[AudioHandler] skipToPrevious error: $e');
        // Revert to previous state on error
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.ready,
        ));
      }
    }
  }

/// Lazily runs [AudioService.init] on first Quran playback (Android/iOS) to avoid
/// `AudioService.onCreate` during app startup (ANR risk). Web: no-op.
class QuranAudioBinding {
  QuranAudioBinding._();

  static Future<void>? _initFuture;

  static Future<void> ensureInitialized() {
    if (kIsWeb) return Future.value();
    if (!ServiceRegistry().featureFlags.systemMediaControlsEnabled) {
      return Future.value(); // Bypass audio_service on platforms without media controls support
    }
    if (QuranAudioHandler.instance != null) return Future.value();
    if (_initFuture != null) return _initFuture!;
    _initFuture = _init();
    return _initFuture!;
  }

  static Future<void> _init() async {
    try {
      // Configure AVAudioSession on iOS so playback is not silenced by the hardware mute switch.
      if (!kIsWeb) {
        try {
          final session = await AudioSession.instance;
          await session.configure(const AudioSessionConfiguration.music());
        } catch (_) {}
      }
      await AudioService.init(
        builder: () => QuranAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.quran.tj.audio',
          androidNotificationChannelName: 'Quran Playback',
          androidNotificationOngoing: true,
        ),
      );
    } catch (e, st) {
      if (e.toString().contains('_cacheManager == null') || QuranAudioHandler.instance != null) {
        debugPrint('[QuranAudioBinding] AudioService already initialized: $e');
        return;
      }
      _initFuture = null;
      debugPrint('[QuranAudioBinding] AudioService.init failed: $e');
      debugPrint('$st');
      // Do not rethrow so playback fallback via AudioPlayer can proceed without crashing
    }
  }
}
