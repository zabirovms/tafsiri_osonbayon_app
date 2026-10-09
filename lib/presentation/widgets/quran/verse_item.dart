import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/html_utils.dart';
import '../../../core/utils/share_helper.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../data/models/verse_model.dart';
import '../../../core/platform/service_registry.dart';
import '../../../data/services/settings_service.dart';
import '../../../data/services/audio_service.dart';
import '../../../data/services/word_by_word_data_service.dart';
import '../../../data/services/tajweed_service.dart';
import 'tajweed_parser.dart';
import '../../providers/quran_provider.dart';
import '../../pages/settings/settings_page.dart';



class VerseItem extends ConsumerStatefulWidget {
  final VerseModel verse;
  final bool showTransliteration;
  final bool showTafsir;
  final bool isWordByWordMode;
  final List<Map<String, String>>? wordByWordTokens; // [{arabic, meaning}]
  final String? translationTextOverride;
  final String? selectedTranslationKey;
  final ValueChanged<String>? onTranslationChanged;
  final VoidCallback? onTap;
  final VoidCallback? onBookmark;
  final VoidCallback? onPlayAudio;
  final VoidCallback? onToggleActions;
  final bool isBookmarked;
  final bool isHighlighted;
  final bool? isTafsirOpen;
  final VoidCallback? onToggleTafsir;
  final String? selectedTafsirSourceKey;
  final ValueChanged<String>? onTafsirSourceChanged;
  final bool isPlaying;
  final bool showExtraActions;
  final bool showArabic;
  final bool showOnlyArabic;
  final bool showTranslation;
  final bool plainCardsMode;
  final double? arabicTextSize;
  final double? translationTextSize;
  final double? transliterationTextSize;
  final bool showBookmarkAction;

  const VerseItem({
    super.key,
    required this.verse,
    this.showArabic = true,
    this.showTransliteration = true,
    this.showTafsir = true,
    this.isWordByWordMode = false,
    this.wordByWordTokens,
    this.translationTextOverride,
    this.selectedTranslationKey,
    this.onTranslationChanged,
    this.onTap,
    this.onBookmark,
    this.onPlayAudio,
    this.onToggleActions,
    this.isBookmarked = false,
    this.isHighlighted = false,
    this.isTafsirOpen,
    this.onToggleTafsir,
    this.selectedTafsirSourceKey,
    this.onTafsirSourceChanged,
    this.isPlaying = false,
    this.showExtraActions = false,
    this.showOnlyArabic = false,
    this.showTranslation = true,
    this.plainCardsMode = false,
    this.arabicTextSize,
    this.translationTextSize,
    this.transliterationTextSize,
    this.showBookmarkAction = true,
  });

  @override
  ConsumerState<VerseItem> createState() => _VerseItemState();
}

class _VerseItemState extends ConsumerState<VerseItem> {
  final bool _isExpanded = false;
  late bool _isBookmarked;
  final _audioService = QuranAudioService();
  int? _playingWordNumber; // For clicked word audio
  int? _highlightedWordNumber; // For verse playback highlighting
  StreamSubscription? _playerStateSubscription;
  StreamSubscription<PlaybackStateInfo>? _uiStateSubscription;
  late final WordByWordDataService _wordByWordService;
  List<Map<String, dynamic>>? _standardModeWords;
  bool _isLoadingWords = false;
  final List<TapGestureRecognizer> _gestureRecognizers = [];
  // ignore: unused_field
  PlaybackStateInfo? _currentPlaybackState;
  Timer? _wordHighlightTimer; // Timer to clear word highlight after brief duration



  /// Renders [text] with paragraph support: splits on \n, renders each
  /// non-empty paragraph as a separate [Text] widget with 8 dp gap between them.
  /// Falls back to a single [Text] when no newlines are present.
  Widget _buildParagraphText(String text, {TextStyle? style}) {
    final paragraphs = text
        .split('\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (paragraphs.length <= 1) {
      return Text(text, style: style);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < paragraphs.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          Text(paragraphs[i], style: style),
        ],
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _wordByWordService = ref.read(wordByWordDataServiceProvider);
    _isBookmarked = widget.isBookmarked;
    TajweedService().addListener(_onTajweedUpdated);

    // Preload Tajweed service if Tajweed mode is selected
    if (ref.read(settingsProvider).arabicFont == 'QPC_Hafs_Tajweed') {
      TajweedService().init();
    }
    
    // Listen to audio player state to track word playback
    _playerStateSubscription = _audioService.playerStateStream.listen((state) {
      if (mounted && _playingWordNumber != null) {
        // Check if word audio is still playing for THIS specific word
        final isWordPlaying = _audioService.isWordPlaying(
          widget.verse.surahId,
          widget.verse.verseNumber,
          _playingWordNumber!,
        );
        
        // Only clear if audio completed or a different word started
        // The timer will handle clearing after 600ms regardless of audio state
        if (state.processingState == ProcessingState.completed) {
          // Audio completed - clear highlight (timer will also clear it, but this is a backup)
          _clearWordHighlight();
        } else if (!isWordPlaying && state.processingState == ProcessingState.ready) {
          // Word stopped and player is ready (likely a different word started or playback stopped)
          // Clear highlight to ensure it doesn't persist
          _clearWordHighlight();
        }
      }
    });
    
    // Listen to UI state stream for verse playback word highlighting
    _uiStateSubscription = _audioService.uiStateStream.listen((state) {
      if (mounted) {
        // Store current playback state for word click handling (always update)
        _currentPlaybackState = state;
        
        // IMPORTANT: Check if our highlighted word is still playing
        // Only clear if a different word is playing (not just if this word stopped)
        // The timer will handle clearing after 600ms regardless
        if (_playingWordNumber != null) {
          // Check if a different word is playing (by checking if isWordPlaying returns false
          // AND there's another word playing)
          final isOurWordPlaying = _audioService.isWordPlaying(
            widget.verse.surahId,
            widget.verse.verseNumber,
            _playingWordNumber!,
          );
          
          // Only clear if our word is not playing AND the player is actually playing something
          // This means a different word started, not just that our word stopped
          if (!isOurWordPlaying && state.isPlaying && state.currentWordNumber != null) {
            // A different word is playing - clear our highlight
            _clearWordHighlight();
          }
        }
        
        // Check if verse is playing and matches current verse
        final isVersePlaying = 
          state.isPlaying &&
          state.currentSurahNumber == widget.verse.surahId &&
          state.currentVerseNumber == widget.verse.verseNumber;
        
        if (isVersePlaying && state.currentWordNumber != null) {
          // Verse is playing - clear clicked word highlight and use playback highlight
          if (_highlightedWordNumber != state.currentWordNumber) {
            _clearWordHighlight(); // Clear any clicked word highlight (includes timer)
            setState(() {
              _highlightedWordNumber = state.currentWordNumber;
            });
          }
        } else if (_highlightedWordNumber != null) {
          // Verse is not playing - clear playback highlight
          setState(() {
            _highlightedWordNumber = null;
          });
        }
      }
    });
    
    // Get initial state immediately (don't wait for first stream event)
    // Note: Stream doesn't have a synchronous value getter, so we'll rely on the listener
    // But we can try to get it from the audio service if available
    
    // Load word-by-word data for standard mode (to make words clickable)
    if (!widget.isWordByWordMode) {
      _loadWordsForStandardMode();
    }
  }

  Future<void> _loadWordsForStandardMode() async {
    if (_isLoadingWords || _standardModeWords != null) return;
    
    setState(() {
      _isLoadingWords = true;
    });
    
    try {
      final font = ref.read(settingsProvider).arabicFont;
      if (font == 'QPC_Hafs_Tajweed') {
        await TajweedService().init();
      }
      final words = await _wordByWordService.getWordsForVerse(
        widget.verse.surahId,
        widget.verse.verseNumber,
      );
      if (mounted) {
        setState(() {
          _standardModeWords = words;
          _isLoadingWords = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWords = false;
        });
      }
      // Silently fail - words just won't be clickable
    }
  }

  void _clearWordHighlight() {
    _wordHighlightTimer?.cancel();
    _wordHighlightTimer = null;
    if (mounted) {
      setState(() {
        _playingWordNumber = null;
      });
    }
  }
  
  void _setWordHighlight(int wordNumber) {
    // Clear any existing highlight first (only one word highlighted at a time)
    _clearWordHighlight();
    
    // Set new highlight
    if (mounted) {
      setState(() {
        _playingWordNumber = wordNumber;
      });
    }
    
    // Auto-clear highlight after 1800ms (brief highlight)
    // This ensures it doesn't stay highlighted for long
    _wordHighlightTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        _clearWordHighlight();
      }
    });
  }



  void _onTajweedUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    TajweedService().removeListener(_onTajweedUpdated);
    _wordHighlightTimer?.cancel();
    _playerStateSubscription?.cancel();
    _uiStateSubscription?.cancel();
    // Dispose all gesture recognizers
    for (final recognizer in _gestureRecognizers) {
      recognizer.dispose();
    }
    _gestureRecognizers.clear();
    super.dispose();
  }

  @override
  void didUpdateWidget(VerseItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync bookmark state when widget prop changes
    if (oldWidget.isBookmarked != widget.isBookmarked) {
      _isBookmarked = widget.isBookmarked;
    }
    
    // Load words if switching from word-by-word mode to standard mode
    if (oldWidget.isWordByWordMode && !widget.isWordByWordMode) {
      _loadWordsForStandardMode();
    }
  }

  void _toggleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    if (widget.onBookmark != null) {
      widget.onBookmark!();
    }
  }

  String _getArabicTextWithEndSymbol() {
    final text = widget.verse.arabicText.trim();
    // Strip trailing \u06dd and trailing Arabic-Indic numerals from raw DB string so end circle symbol is never duplicated
    return text.replaceAll(RegExp(r'[\u06dd\u0660-\u0669]+\s*$'), '').trim();
  }

  String _convertToArabicNumerals(int number) {
    const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    
    if (number == 0) return arabicNumerals[0];
    
    String result = '';
    while (number > 0) {
      result = arabicNumerals[number % 10] + result;
      number ~/= 10;
    }
    
    return result;
  }

  /// Build clickable Arabic text for standard mode (seamless appearance)
  Widget _buildClickableArabicText(ThemeData theme, ColorScheme colorScheme) {
    final selectedFont = ref.watch(settingsProvider).arabicFont;
    final isTajweed = selectedFont == 'QPC_Hafs_Tajweed';
    final effectiveFontFamily = AppConstants.getEffectiveFontFamily(selectedFont);

    if (isTajweed && !TajweedService().isLoaded) {
      TajweedService().init();
    }

    List<Map<String, dynamic>>? verseWordsList = _standardModeWords;
    if ((verseWordsList == null || verseWordsList.isEmpty) &&
        widget.wordByWordTokens != null &&
        widget.wordByWordTokens!.isNotEmpty) {
      verseWordsList = widget.wordByWordTokens!.asMap().entries.map((entry) {
        final idx = entry.key;
        final item = entry.value;
        return <String, dynamic>{
          'word': idx + 1,
          'text': item['arabic'] ?? '',
          'farsi': item['meaning'] ?? '',
        };
      }).toList();
    }

    if (verseWordsList == null || verseWordsList.isEmpty) {
      final arabicVerseNumber = _convertToArabicNumerals(widget.verse.verseNumber);
      final tajweedWords = isTajweed
          ? TajweedService().getTajweedWordsSync(widget.verse.surahId, widget.verse.verseNumber)
          : null;

      if (isTajweed && tajweedWords != null && tajweedWords.isNotEmpty) {
        final baseStyle = theme.textTheme.titleLarge?.copyWith(
          height: 1.4,
          fontSize: widget.arabicTextSize ?? AppConstants.defaultArabicTextSize,
          fontFamily: 'QPC_Hafs',
          letterSpacing: 0.0,
        );
        final spans = <TextSpan>[];
        for (int i = 0; i < tajweedWords.length; i++) {
          spans.add(
            parseTajweedWord(
              wordText: tajweedWords[i],
              baseStyle: baseStyle ?? const TextStyle(),
              context: context,
            ),
          );
          if (i < tajweedWords.length - 1) {
            spans.add(const TextSpan(text: ' '));
          }
        }
        spans.add(
          TextSpan(
            text: ' $arabicVerseNumber',
            style: const TextStyle(fontFamily: 'QPC_Hafs'),
          ),
        );

        return Text.rich(
          TextSpan(style: baseStyle, children: spans),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
        );
      }

      return Text.rich(
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        TextSpan(
          style: theme.textTheme.titleLarge?.copyWith(
            height: 1.4,
            fontSize: widget.arabicTextSize ?? AppConstants.defaultArabicTextSize,
            fontFamily: effectiveFontFamily,
            letterSpacing: 0.0,
          ),
          children: [
            TextSpan(text: _getArabicTextWithEndSymbol()),
            TextSpan(
              text: ' $arabicVerseNumber',
              style: const TextStyle(fontFamily: 'QPC_Hafs'),
            ),
          ],
        ),
      );
    }

    // Filter out verse number markers
    final verseWords = verseWordsList.where((word) {
      final text = (word['text'] as String? ?? '').trim();
      // Filter out standalone Arabic-Indic numerals (verse number markers)
      final isVerseNumber = RegExp(r'^[\u0660-\u0669]+$').hasMatch(text);
      return !isVerseNumber;
    }).toList();

    // Build clickable text spans using RichText for seamless appearance
    // Clear old recognizers first
    for (final recognizer in _gestureRecognizers) {
      recognizer.dispose();
    }
    _gestureRecognizers.clear();

    final tajweedWords = isTajweed
        ? TajweedService().getTajweedWordsSync(widget.verse.surahId, widget.verse.verseNumber)
        : null;

    final textSpans = <TextSpan>[];
    final baseStyle = theme.textTheme.titleLarge?.copyWith(
      height: 1.4,
      fontSize: widget.arabicTextSize ?? 22,
      fontFamily: effectiveFontFamily,
      letterSpacing: 0.0,
    );

    for (int i = 0; i < verseWords.length; i++) {
      final word = verseWords[i];
      final wordText = ((word['text'] as String?) ?? (word['arabic'] as String?) ?? '').trim();
      final wordNumber = int.tryParse(word['word']?.toString() ?? '0') ?? 0;
      // For clicked words: use _playingWordNumber (has timer, will auto-clear)
      // For verse playback: use _highlightedWordNumber (from UI state stream)
      // Don't use isWordPlaying() for clicked words as it persists longer than we want
      final isClickedWord = _playingWordNumber == wordNumber;
      final isHighlighted = _highlightedWordNumber == wordNumber;
      // Highlight if either clicked (temporary) or highlighted (during verse playback)
      final shouldHighlight = isClickedWord || isHighlighted;

      // Create a tap recognizer for this word
      final recognizer = TapGestureRecognizer()
        ..onTap = () {
          debugPrint('[VerseItem] ===== WORD TAP DETECTED ===== Word $wordNumber tapped in verse ${widget.verse.surahId}:${widget.verse.verseNumber}');
          
          // Play audio / seek asynchronously
          Future(() async {
            try {
              final hasActivePlayback = _audioService.hasActivePlayback;
              final isThisVersePlaying = _audioService.isPlayingVerse(
                widget.verse.surahId,
                widget.verse.verseNumber,
              );
              
              debugPrint('[VerseItem] hasActivePlayback: $hasActivePlayback, isThisVersePlaying: $isThisVersePlaying');
              
              if (hasActivePlayback && isThisVersePlaying) {
                // Miniplayer is open AND this specific verse is playing - seek to word position
                debugPrint('[VerseItem] Seeking to word $wordNumber position in playing verse');
                final currentEdition = _audioService.currentEdition;
                await _audioService.playVerseFromWord(
                  widget.verse.surahId,
                  widget.verse.verseNumber,
                  wordNumber,
                  edition: currentEdition,
                );
              } else if (hasActivePlayback && !isThisVersePlaying) {
                // Miniplayer is open with a different verse - ignore word click audio
                debugPrint('[VerseItem] Miniplayer open with different verse - ignoring word audio click');
              } else {
                // Miniplayer is closed - play individual word audio
                debugPrint('[VerseItem] Miniplayer closed - playing individual word $wordNumber');
                await _audioService.playWordAudio(
                  widget.verse.surahId,
                  widget.verse.verseNumber,
                  wordNumber,
                );
                // Set highlight (will auto-clear after 1.8 seconds)
                _setWordHighlight(wordNumber);
              }
            } catch (e, stackTrace) {
              debugPrint('[VerseItem] ERROR in word audio playback: $e');
              debugPrint('[VerseItem] Stack trace: $stackTrace');
            }
          });
        };
      
      _gestureRecognizers.add(recognizer);

      final wordStyle = baseStyle?.copyWith(
        color: shouldHighlight ? colorScheme.primary : null,
      );

      if (isTajweed && tajweedWords != null && i < tajweedWords.length) {
        textSpans.add(
          parseTajweedWord(
            wordText: tajweedWords[i],
            baseStyle: wordStyle ?? const TextStyle(),
            context: context,
            onWordTap: recognizer.onTap,
          ),
        );
      } else {
        textSpans.add(
          TextSpan(
            text: wordText,
            recognizer: recognizer,
            style: wordStyle,
          ),
        );
      }

      // Add space between words (except last word)
      if (i < verseWords.length - 1) {
        textSpans.add(const TextSpan(text: ' '));
      }
    }

    // Add verse number symbol at the end (ALWAYS use QPC_Hafs for perfect enclosed circle)
    final arabicVerseNumber = _convertToArabicNumerals(widget.verse.verseNumber);
    textSpans.add(
      TextSpan(
        text: ' $arabicVerseNumber',
        style: baseStyle?.copyWith(
          fontFamily: 'QPC_Hafs',
        ),
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: RichText(
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        text: TextSpan(
          style: baseStyle,
          children: textSpans,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.plainCardsMode
                ? ((widget.isPlaying || widget.isHighlighted)
                    ? colorScheme.primaryContainer.withValues(alpha: 0.15)
                    : Colors.transparent)
                : ((widget.isPlaying || widget.isHighlighted)
                    ? colorScheme.primaryContainer.withValues(alpha: 0.25)
                    : colorScheme.surface),
            borderRadius: BorderRadius.circular(widget.plainCardsMode ? 0 : 16),
            border: widget.plainCardsMode
                ? null
                : ((widget.isPlaying || widget.isHighlighted)
                    ? Border.all(color: colorScheme.primary.withValues(alpha: 0.6), width: 2)
                    : Border.all(color: colorScheme.outline.withValues(alpha: 0.2), width: 1)),
            boxShadow: widget.plainCardsMode
                ? null
                : [
                    BoxShadow(
                      color: (widget.isPlaying || widget.isHighlighted)
                          ? colorScheme.primary.withValues(alpha: 0.12)
                          : colorScheme.shadow.withValues(alpha: 0.05),
                      blurRadius: (widget.isPlaying || widget.isHighlighted) ? 10 : 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: InkWell(
        // Disable tap handler - words are clickable, and onTap only closes actions menu
        // Long press still works for toggling actions
        onTap: null,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onLongPress: () {
          if (widget.onToggleActions != null) {
            widget.onToggleActions!();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Row: Verse Ref Number, Action Buttons, Spacer, and Tafsir Toggle
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Verse number (not theme color, reduced color grey)
                  Text(
                    '${widget.verse.surahId}:${widget.verse.verseNumber}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Play/Pause audio (always visible)
                  _buildActionButton(
                    icon: widget.isPlaying ? Icons.pause : Icons.play_arrow,
                    tooltip: widget.isPlaying ? 'Пауза' : 'Play Audio',
                    onPressed: widget.onPlayAudio,
                    color: widget.isPlaying
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  
                  // Extra actions (bookmark, copy, share, translation)
                  if (widget.showExtraActions) ...[
                    const SizedBox(width: 8),

                    // Bookmark
                    if (widget.showBookmarkAction) ...[
                      _buildActionButton(
                        icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        tooltip: _isBookmarked ? 'Remove Bookmark' : 'Add Bookmark',
                        onPressed: _toggleBookmark,
                        color: _isBookmarked
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Copy
                    _buildActionButton(
                      icon: Icons.copy,
                      tooltip: 'Нусхабардорӣ',
                      onPressed: () async {
                        final text = await _buildCopyText();
                        await Clipboard.setData(ClipboardData(text: text));
                        if (context.mounted) {
                          SnackBarHelper.showSuccess(
                            context: context,
                            message: 'Оят нусхабардорӣ карда шуд',
                            duration: const Duration(seconds: 2),
                          );
                        }
                      },
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),

                    // Share
                    _buildActionButton(
                      icon: Icons.share,
                      tooltip: 'Мубодила',
                      onPressed: () async {
                        final text = await _buildCopyText();
                        if (!context.mounted) return;
                        await ShareHelper.share(text, context: context);
                        ServiceRegistry().analyticsService.logShare('verse', id: widget.verse.uniqueKey);
                        if (context.mounted) {
                          SnackBarHelper.showSuccess(
                            context: context,
                            message: 'Оят мубодила карда шуд',
                            duration: const Duration(seconds: 2),
                          );
                        }
                      },
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Arabic Text or Word-by-Word Tokens
              if (widget.showArabic)
                if (widget.isWordByWordMode && (widget.wordByWordTokens?.isNotEmpty ?? false))
                // Word-by-word display replacing Arabic text
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      alignment: WrapAlignment.end,
                      textDirection: TextDirection.rtl,
                      children: [
                        for (int i = 0; i < widget.wordByWordTokens!.length; i++)
                          Builder(
                            builder: (context) {
                              final t = widget.wordByWordTokens![i];
                              final wordNumber = i + 1; // Word numbers start from 1
                              // For clicked words: use _playingWordNumber (has timer, will auto-clear)
                              // For verse playback: use _highlightedWordNumber (from UI state stream)
                              // Don't use isWordPlaying() for clicked words as it persists longer than we want
                              final isClickedWord = _playingWordNumber == wordNumber;
                              final isHighlighted = _highlightedWordNumber == wordNumber;
                              // Highlight if either clicked (temporary) or highlighted (during verse playback)
                              final shouldHighlight = isClickedWord || isHighlighted;
                              
                              return GestureDetector(
                                onTap: () {
                                  Future(() async {
                                    try {
                                      final isVersePlaying = _audioService.isPlayingVerse(
                                        widget.verse.surahId,
                                        widget.verse.verseNumber,
                                      );
                                      
                                      debugPrint('[VerseItem] Word $wordNumber tapped (WbW mode). isVersePlaying: $isVersePlaying');
                                      
                                      if (isVersePlaying) {
                                        final currentEdition = _audioService.currentEdition;
                                        await _audioService.playVerseFromWord(
                                          widget.verse.surahId,
                                          widget.verse.verseNumber,
                                          wordNumber,
                                          edition: currentEdition,
                                        );
                                      } else {
                                        await _audioService.playWordAudio(
                                          widget.verse.surahId,
                                          widget.verse.verseNumber,
                                          wordNumber,
                                        );
                                        _setWordHighlight(wordNumber);
                                      }
                                    } catch (e) {
                                      debugPrint('[VerseItem] ERROR in WBW word audio tap: $e');
                                    }
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: shouldHighlight
                                        ? colorScheme.primary.withValues(alpha: 0.15)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: shouldHighlight
                                        ? Border.all(
                                            color: colorScheme.primary.withValues(alpha: 0.5),
                                            width: 1,
                                          )
                                        : null,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      () {
                                         final tokenArabic = (t['arabic'] ?? '').trim();
                                         final isVerseNumToken = RegExp(r'^[\u0660-\u0669\u06dd]+$').hasMatch(tokenArabic);
                                         final selFont = ref.watch(settingsProvider).arabicFont;
                                         final isTaj = selFont == 'QPC_Hafs_Tajweed';
                                         final effFont = isVerseNumToken
                                             ? 'QPC_Hafs'
                                             : AppConstants.getEffectiveFontFamily(selFont);

                                         final tokenStyle = theme.textTheme.titleMedium?.copyWith(
                                           fontFamily: effFont,
                                           fontSize: (widget.arabicTextSize ?? AppConstants.defaultArabicTextSize) * 0.82,
                                           fontWeight: FontWeight.w600,
                                           color: shouldHighlight
                                               ? colorScheme.primary
                                               : null,
                                         );

                                         final wordIdx = (int.tryParse(t['word']?.toString() ?? '0') ?? 1) - 1;
                                         final tajWords = isTaj
                                             ? TajweedService().getTajweedWordsSync(widget.verse.surahId, widget.verse.verseNumber)
                                             : null;

                                         if (isTaj && tajWords != null && wordIdx >= 0 && wordIdx < tajWords.length) {
                                           return Text.rich(
                                             parseTajweedWord(
                                               wordText: tajWords[wordIdx],
                                               baseStyle: tokenStyle ?? const TextStyle(),
                                               context: context,
                                             ),
                                             textDirection: TextDirection.rtl,
                                             textAlign: TextAlign.center,
                                           );
                                         }

                                         return Text(
                                           tokenArabic,
                                           textDirection: TextDirection.rtl,
                                           textAlign: TextAlign.center,
                                           style: tokenStyle,
                                         );
                                       }(),
                                      if ((t['meaning'] ?? '').isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          t['meaning']!,
                                          textDirection: TextDirection.ltr,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: shouldHighlight
                                                ? colorScheme.primary.withValues(alpha: 0.8)
                                                : colorScheme.onSurface.withValues(alpha: 0.7),
                                            fontSize: 11,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                )
              else
                // Regular Arabic text display (with clickable words if data available)
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _standardModeWords != null && _standardModeWords!.isNotEmpty
                        ? GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              // Consume tap to prevent parent InkWell from receiving it
                              // Individual word taps are handled by their own GestureDetectors
                            },
                            child: _buildClickableArabicText(theme, colorScheme),
                          )
                        : Text.rich(
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            TextSpan(
                              style: theme.textTheme.titleLarge?.copyWith(
                                height: 1.4,
                                fontSize: widget.arabicTextSize ?? AppConstants.defaultArabicTextSize,
                                fontFamily: AppConstants.getEffectiveFontFamily(ref.watch(settingsProvider).arabicFont),
                                letterSpacing: 0.0,
                              ),
                              children: [
                                TextSpan(text: _getArabicTextWithEndSymbol()),
                                TextSpan(
                                  text: ' ${_convertToArabicNumerals(widget.verse.verseNumber)}',
                                  style: const TextStyle(fontFamily: 'QPC_Hafs'),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),

              const SizedBox(height: 6),

              // Transliteration (hidden if word by word mode is on)
              if (widget.showTransliteration && !widget.isWordByWordMode && widget.verse.transliteration != null)
                Text(
                  widget.verse.transliteration!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                    fontSize: widget.transliterationTextSize ?? AppConstants.defaultTransliterationTextSize,
                  ),
                ),

              const SizedBox(height: 6),

              // Translation (hidden if showOnlyArabic is true, showTranslation is false, or word by word mode is on)
              if (!widget.showOnlyArabic && widget.showTranslation && !widget.isWordByWordMode)
                Builder(
                  builder: (context) {
                    final currentLang = widget.selectedTranslationKey ?? SettingsService().getTranslationLanguage();
                    final translatorName = AppConstants.getTranslationName(currentLang);
                    final selectorColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          widget.translationTextOverride ?? widget.verse.ayatiText,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                            fontSize: widget.translationTextSize ?? AppConstants.defaultTranslationTextSize,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: PopupMenuButton<String>(
                            initialValue: currentLang,
                            tooltip: 'Интихоби тарҷума',
                            onSelected: (newLang) async {
                              final s = SettingsService();
                              await s.init();
                              await s.setTranslationLanguage(newLang);
                              if (widget.onTranslationChanged != null) {
                                widget.onTranslationChanged!(newLang);
                              } else {
                                ref.invalidate(versesProvider(widget.verse.surahId));
                              }
                            },
                            itemBuilder: (context) => AppConstants.supportedLanguages.map((lang) {
                              return PopupMenuItem<String>(
                                value: lang,
                                child: Text(AppConstants.getTranslationName(lang)),
                              );
                            }).toList(),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '— $translatorName',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: selectorColor,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.arrow_drop_down,
                                  size: 16,
                                  color: selectorColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

              // Render Tafsir inline directly below translation without highlight box, matching side spaces
              if (widget.showTafsir)
                Builder(
                builder: (context) {
                  final currentTafsirKey = widget.selectedTafsirSourceKey ?? AppConstants.tafsirSourceTajik;
                  final isRu = currentTafsirKey == AppConstants.tafsirSourceRuIbnKathir;
                  final rawTafsir = isRu
                      ? (widget.verse.tafsirRu?.trim() ?? widget.verse.tafsir?.trim())
                      : (widget.verse.tafsir?.trim() ?? widget.verse.tafsirRu?.trim());

                  if (rawTafsir == null || rawTafsir.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final cleanText = stripHtmlToPlainText(rawTafsir);
                  final selectorColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      // Selectable Tafsir title dropdown (subtle, unhighlighted)
                      PopupMenuButton<String>(
                        initialValue: currentTafsirKey,
                        tooltip: 'Интихоби тафсир',
                        onSelected: (newSourceKey) async {
                          final s = SettingsService();
                          await s.init();
                          await s.setTafsirSource(newSourceKey);
                          if (widget.onTafsirSourceChanged != null) {
                            widget.onTafsirSourceChanged!(newSourceKey);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: AppConstants.tafsirSourceTajik,
                            child: Text('Тафсири Осонбаён'),
                          ),
                          const PopupMenuItem(
                            value: AppConstants.tafsirSourceRuIbnKathir,
                            child: Text('Тафсири Ибни Касир (RU)'),
                          ),
                        ],
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_stories_rounded,
                              size: 14,
                              color: selectorColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isRu ? 'Тафсири Ибни Касир (RU)' : 'Тафсири Осонбаён',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: selectorColor,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.arrow_drop_down,
                              size: 16,
                              color: selectorColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildParagraphText(
                        cleanText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                          fontSize: (widget.translationTextSize ?? AppConstants.defaultTranslationTextSize) - 1,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      ),
        // Horizontal divider in plain mode
        if (widget.plainCardsMode)
          Divider(
            height: 1,
            thickness: 1.2,
            color: colorScheme.outline.withValues(alpha: 0.4),
            indent: 12,
            endIndent: 12,
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
      ),
    );
  }



  /// Build comprehensive copy text including Arabic, transliteration, translation with translator name, tafsir with name, and verse reference
  Future<String> _buildCopyText() async {
    final buffer = StringBuffer();
    
    // 1. Arabic text (inside curly braces)
    final cleanArabicText = widget.verse.arabicText.trim();
    buffer.writeln('{$cleanArabicText}');
    buffer.writeln();
    
    // 2. Transliteration (if visible)
    if (widget.showTransliteration && !widget.isWordByWordMode && widget.verse.transliteration != null && widget.verse.transliteration!.isNotEmpty) {
      buffer.writeln(widget.verse.transliteration!.trim());
      buffer.writeln();
    }
    
    // 3. Current translation with translator name (if visible)
    if (!widget.showOnlyArabic && widget.showTranslation && !widget.isWordByWordMode) {
      final settingsService = SettingsService();
      await settingsService.init();
      final currentLang = settingsService.getTranslationLanguage();
      
      // Get translation text
      String translationText;
      if (widget.translationTextOverride != null) {
        // Use override if provided
        translationText = widget.translationTextOverride!;
      } else {
        // Get from verse based on current language
        translationText = widget.verse.getTranslation(currentLang);
      }
      
      // Get translator name
      final translatorName = AppConstants.getTranslationName(currentLang);
      
      if (translationText.isNotEmpty) {
        buffer.writeln(translationText.trim());
        buffer.writeln('— $translatorName');
        buffer.writeln();
      }
    }
    
    // 4. Tafsir with name (if visible)
    if ((widget.isTafsirOpen ?? _isExpanded)) {
      final key = widget.selectedTafsirSourceKey ?? AppConstants.tafsirSourceTajik;
      final raw = key == AppConstants.tafsirSourceRuIbnKathir ? widget.verse.tafsirRu : widget.verse.tafsir;
      if (raw != null && raw.trim().isNotEmpty) {
        final text = key == AppConstants.tafsirSourceRuIbnKathir ? stripHtmlToPlainText(raw) : raw.trim();
        buffer.writeln('${AppConstants.getTafsirSourceName(key)}:');
        buffer.writeln(text);
        buffer.writeln();
      }
    }
    
    // 5. Verse reference
    buffer.writeln('(Қуръон ${widget.verse.surahId}:${widget.verse.verseNumber})');
    
    return buffer.toString();
  }
}
