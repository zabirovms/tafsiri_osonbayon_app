import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' show max, min;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../providers/quran_provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/reciter_provider.dart';
import '../../providers/translation_audio_provider.dart'
    show translationAudioEditionProvider;
import '../../providers/quran_last_read_provider.dart';
import '../../providers/quran_text_sizes_provider.dart';
import '../../../data/services/audio_service.dart';
import '../../../core/utils/bottom_sheet_helper.dart';
import '../../../core/utils/share_helper.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../data/services/settings_service.dart';
import '../../../data/services/surah_svg_service.dart';
import '../../../core/config/feature_badges_config.dart';
import '../../providers/feature_badge_provider.dart';
import '../../../shared/widgets/feature_badge.dart';
import '../../widgets/audio_player_controls.dart';
import '../../widgets/translation_selection_dialog.dart';
import '../../widgets/reciter_selection_dialog.dart';
import '../../widgets/quran/verse_item.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../data/models/surah_model.dart';
import '../../../data/models/verse_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/analytics_service.dart';
import '../../../data/services/quran_last_read_service.dart';
import '../settings/settings_page.dart';

import 'package:qcf_quran/qcf_quran.dart';
import '../../../core/theme/mushaf_theme_helper.dart';

class SurahPage extends ConsumerStatefulWidget {
  final int surahNumber;
  final int? initialVerseNumber;
  final int? initialPageNumber;
  final bool initialMushafMode;
  final String? swipeDirection;

  const SurahPage({
    super.key,
    required this.surahNumber,
    this.initialVerseNumber,
    this.initialPageNumber,
    this.initialMushafMode = false,
    this.swipeDirection,
  });

  @override
  ConsumerState<SurahPage> createState() => _SurahPageState();
}

class _SurahPageState extends ConsumerState<SurahPage> {
  final FocusNode _focusNode = FocusNode();
  bool _showArabic = true;
  bool _showTransliteration = false;
  bool _isWordByWordMode = false;
  bool _showTranslation = true;
  bool _showTafsir = true;
  bool _showVerseActions = true;
  bool _plainCardsMode = true; // Always use plain cards mode
  bool _mushafMode = false;
  late int _currentMushafPage;
  late final PageController _mushafPageController;
  String _translationLang = AppConstants.defaultLanguage;
  String _tafsirSourceKey = AppConstants.tafsirSourceTajik;
  double _arabicTextSize = AppConstants.defaultArabicTextSize;
  double _translationTextSize = AppConstants.defaultTranslationTextSize;
  double _transliterationTextSize = AppConstants.defaultTransliterationTextSize;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  int? _highlightedVerseIndex; // for highlighting specific verse
  StreamSubscription<PlaybackStateInfo>? _audioSub; // listen for verse changes
  int? _lastAutoScrolledVerse;
  int? _lastNavigatedSurah; // prevent duplicate navigations
  final _svgService = SurahSvgService();
  int? _activeActionsIndex; // controls verse action row visibility
  bool _hasHighlightedInitialVerse =
      false; // track if initial verse has been highlighted
  bool _hasActiveAudio = false;

  // Last-read: dominant visible verse (debounced) + one-shot initial row.
  Timer? _lastReadDebounceTimer;
  List<VerseModel>? _lastReadVersesCache;
  bool _lastReadHasBismillah = false;
  int _lastReadTotalItems = 0;
  bool _lastReadListenerAttached = false;
  bool _lastReadAttachScheduled = false;
  bool _initialLastReadWritten = false;

  late final Offset _slideBeginOffset;

  @override
  void initState() {
    super.initState();
    _mushafMode = widget.initialMushafMode;
    if (widget.initialPageNumber != null) {
      _currentMushafPage = widget.initialPageNumber!.clamp(1, 604);
    } else {
      try {
        _currentMushafPage = getPageNumber(
          widget.surahNumber,
          widget.initialVerseNumber ?? 1,
        );
      } catch (_) {
        _currentMushafPage = 1;
      }
    }
    _mushafPageController = PageController(initialPage: _currentMushafPage - 1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
    if (widget.swipeDirection == 'right') {
      _slideBeginOffset = const Offset(-0.15, 0.0); // Slide in from left (subtle)
    } else if (widget.swipeDirection == 'left') {
      _slideBeginOffset = const Offset(0.15, 0.0); // Slide in from right (subtle)
    } else {
      _slideBeginOffset = Offset.zero;
    }
    Future(() async {
      try {
        final s = SettingsService();
        await s.init();
        final loadedMushafMode = widget.initialMushafMode || s.getMushafMode();
        if (mounted) {
          setState(() {
            _showArabic = s.getShowArabic();
            _showTransliteration = s.getShowTransliteration();
            _isWordByWordMode = s.getWordByWordMode();
            _showTranslation = s.getShowTranslation();
            _showTafsir = s.getShowTafsir();
            _showVerseActions = s.getShowVerseActions();
            // Plain cards mode is always enabled
            _plainCardsMode = true;
            _mushafMode = loadedMushafMode;
            _translationLang = s.getTranslationLanguage();
            _tafsirSourceKey = s.getTafsirSource();
            _arabicTextSize = s.getArabicTextSize();
            _translationTextSize = s.getTranslationTextSize();
            _transliterationTextSize = s.getTransliterationTextSize();
          });
          if (loadedMushafMode) {
            _recordCurrentMushafPageLastRead(_currentMushafPage);
          }
        }
        // Sync audio edition from global settings into the surah controller
        final edition = s.getAudioEdition();
        if (mounted) {
          ref
              .read(surahControllerProvider(widget.surahNumber))
              .setAudioEdition(edition);
        }
      } catch (_) {
        // Fallback to defaults if settings not ready
      }
    });
    // Note: initialScrollIndex handles initial scrolling, so _handleInitialScroll is not needed
    // But we'll keep it as a fallback for highlighting
    if (widget.initialVerseNumber != null) {
      _hasHighlightedInitialVerse =
          false; // Will be set to true after first highlight
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AnalyticsService().logSurahView(widget.surahNumber);
      if (widget.initialVerseNumber != null) {
        AnalyticsService()
            .logVerseView(widget.surahNumber, widget.initialVerseNumber!);
      }
    });

    // Auto-scroll to the currently playing verse when playback changes
    final audio = QuranAudioService();
    _hasActiveAudio = audio.hasActivePlayback;
    _audioSub = audio.uiStateStream.listen((info) {
      if (!mounted) return;
      final hasActive = (info.currentUrl != null) &&
          (info.processingState != ProcessingState.idle);
      if (_hasActiveAudio != hasActive) {
        setState(() {
          _hasActiveAudio = hasActive;
        });
      }
      final isThisSurah = info.currentSurahNumber == widget.surahNumber;
      final verse = info.currentVerseNumber;
      // Auto-scroll to currently playing verse within this surah
      if (isThisSurah && verse != null) {
        if (_lastAutoScrolledVerse == verse) return;
        _lastAutoScrolledVerse = verse;
        if (_mushafMode) {
          try {
            final targetPage = getPageNumber(widget.surahNumber, verse);
            if (targetPage != _currentMushafPage &&
                _mushafPageController.hasClients) {
              _currentMushafPage = targetPage;
              _mushafPageController.animateToPage(
                targetPage - 1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          } catch (_) {}
        } else {
          // Use a small delay to ensure data is ready
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              _scrollToVerse(verse);
            }
          });
        }
      }

      // If playback context switched to a different surah, navigate there
      final targetSurah = info.currentSurahNumber;
      if (targetSurah != null &&
          targetSurah != widget.surahNumber &&
          _lastNavigatedSurah != targetSurah) {
        _lastNavigatedSurah = targetSurah;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _navigateToSurah(targetSurah);
          }
        });
      }
    });
    // SVGs are now loaded from assets, no download needed
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _lastReadDebounceTimer?.cancel();
    if (_lastReadListenerAttached) {
      _itemPositionsListener.itemPositions
          .removeListener(_onItemPositionsChangedLastRead);
      _lastReadListenerAttached = false;
    }
    _audioSub?.cancel();
    _mushafPageController.dispose();
    super.dispose();
  }

  void _toggleMushafMode() {
    final newMode = !_mushafMode;
    setState(() {
      _mushafMode = newMode;
    });
    Future(() async {
      final s = SettingsService();
      await s.init();
      await s.setMushafMode(newMode);
    });

    if (_mushafMode) {
      // Switched to Mushaf 15-line mode: compute page for active verse
      try {
        int activeVerse = _lastAutoScrolledVerse ?? widget.initialVerseNumber ?? 1;
        final positions = _itemPositionsListener.itemPositions.value;
        if (positions.isNotEmpty) {
          final hasBismillah = widget.surahNumber != 1 && widget.surahNumber != 9;
          final firstVerseListIndex = hasBismillah ? 2 : 1;
          final verses = _lastReadVersesCache;
          for (final p in positions) {
            if (p.index >= firstVerseListIndex) {
              final vIdx = hasBismillah ? p.index - 2 : p.index - 1;
              if (verses != null && vIdx >= 0 && vIdx < verses.length) {
                activeVerse = verses[vIdx].verseNumber;
                break;
              }
            }
          }
        }
        _currentMushafPage = getPageNumber(widget.surahNumber, activeVerse);
        _recordCurrentMushafPageLastRead(_currentMushafPage);
      } catch (_) {}

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_mushafPageController.hasClients) {
          _mushafPageController.jumpToPage(_currentMushafPage - 1);
        }
      });
    } else {
      // Switched to Ayah List mode: compute surah/verse for active mushaf page
      try {
        final ranges = getPageData(_currentMushafPage);
        if (ranges.isNotEmpty) {
          final targetSurah = int.parse(ranges[0]['surah'].toString());
          final targetVerse = int.parse(ranges[0]['start'].toString());
          if (targetSurah != widget.surahNumber) {
            context.go('/surah/$targetSurah?verse=$targetVerse');
            return;
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _scrollToVerse(targetVerse);
            }
          });
        }
      } catch (_) {}
    }
  }

  void _onItemPositionsChangedLastRead() {
    final verses = _lastReadVersesCache;
    if (verses == null || !mounted || verses.isEmpty) return;
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;
    final hasBismillah = _lastReadHasBismillah;
    final totalItems = _lastReadTotalItems;
    final firstVerseListIndex = hasBismillah ? 2 : 1;
    // Use the furthest ayah with any visible slice — not a single "dominant" row.
    // Short surahs often show many ayahs at once; dominant picked a middle row (~50–70%).
    var maxVerse = 0;
    for (final p in positions) {
      if (p.index < firstVerseListIndex || p.index >= totalItems) continue;
      final vis = (min(1.0, p.itemTrailingEdge) - max(0.0, p.itemLeadingEdge))
          .clamp(0.0, 1.0);
      if (vis <= 0.02) continue;
      final verseIndex = hasBismillah ? p.index - 2 : p.index - 1;
      if (verseIndex < 0 || verseIndex >= verses.length) continue;
      final vn = verses[verseIndex].verseNumber;
      if (vn > maxVerse) maxVerse = vn;
    }
    if (maxVerse < 1) return;
    _scheduleLastReadPersist(maxVerse);
  }

  void _scheduleLastReadPersist(int verseNumber) {
    _lastReadDebounceTimer?.cancel();
    _lastReadDebounceTimer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      unawaited(_persistLastReadVerse(verseNumber));
    });
  }

  Future<void> _persistLastReadVerse(int verseNumber, {int? targetSurahNumber}) async {
    if (!mounted) return;
    final surahNum = targetSurahNumber ?? widget.surahNumber;
    final surahs = ref.read(surahsProvider).valueOrNull;
    final match = surahs?.where((s) => s.number == surahNum).firstOrNull;
    final surahAsync = ref.read(surahProvider(surahNum));
    final surah = surahAsync.valueOrNull;
    final name = match?.nameTajik ?? surah?.nameTajik ?? AppConstants.getSurahNameTajik(surahNum);
    final verses = _lastReadVersesCache;
    final ayahTotal = match?.versesCount ??
        ((surahNum == widget.surahNumber && verses != null && verses.isNotEmpty) ? verses.length : null);
    await ref.read(quranLastReadServiceProvider).recordVisit(
          QuranLastReadEntry(
            surahNumber: surahNum,
            verseNumber: verseNumber,
            surahNameTajik: name,
            surahAyahCount: ayahTotal,
          ),
        );
    ref.invalidate(quranLastReadListProvider);
  }

  void _recordCurrentMushafPageLastRead(int page) {
    if (!mounted) return;
    try {
      final ranges = getPageData(page);
      if (ranges.isNotEmpty) {
        final sNum = int.parse(ranges[0]['surah'].toString());
        final vNum = int.parse(ranges[0]['start'].toString());
        unawaited(_persistLastReadVerse(vNum, targetSurahNumber: sNum));
      }
    } catch (_) {}
  }

  Future<void> _writeInitialLastRead(
      SurahModel? surah, List<VerseModel> verses) async {
    if (_initialLastReadWritten) return;
    if (verses.isEmpty) {
      _initialLastReadWritten = true;
      return;
    }
    if (surah == null) return;
    _initialLastReadWritten = true;
    final target = widget.initialVerseNumber;
    int verseNum = verses.first.verseNumber;
    if (target != null) {
      final match = verses.where((v) => v.verseNumber == target).toList();
      if (match.isNotEmpty) verseNum = match.first.verseNumber;
    }
    await ref.read(quranLastReadServiceProvider).recordVisit(
          QuranLastReadEntry(
            surahNumber: widget.surahNumber,
            verseNumber: verseNum,
            surahNameTajik: surah.nameTajik,
            surahAyahCount: verses.length,
          ),
        );
    ref.invalidate(quranLastReadListProvider);
  }

  Future<void> _showVerseActionsFromNumbers(
      BuildContext context, int surahNumber, int verseNumber) async {
    List<VerseModel> verses = [];
    try {
      verses = await ref.read(versesProvider(surahNumber).future);
    } catch (_) {}

    final verseModel = verses.firstWhere(
      (v) => v.verseNumber == verseNumber,
      orElse: () => VerseModel(
        id: 0,
        surahId: surahNumber,
        verseNumber: verseNumber,
        arabicText: getVerse(surahNumber, verseNumber),
        ayatiText: '',
        uniqueKey: '$surahNumber:$verseNumber',
      ),
    );

    final userId = ref.read(currentUserIdProvider);
    final bookmarkState = ref.read(bookmarkNotifierProvider(userId));
    final verseKey = '$surahNumber:$verseNumber';
    final isBookmarked = bookmarkState.bookmarkStatus[verseKey] ?? false;

    if (!mounted) return;
    await BottomSheetHelper.showStandard<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Сураи ${AppConstants.getSurahNameTajik(surahNumber)} — Ояти $verseNumber',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const Divider(),
          if (!_mushafMode) ...[
            ListTile(
              leading: const Icon(Icons.play_circle_fill_rounded, color: Colors.green),
              title: const Text('Тиловати оят'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                QuranAudioService().playVerse(surahNumber, verseNumber);
                SnackBarHelper.showInfo(
                  context: context,
                  message: 'Тиловат оғоз шуд ($surahNumber:$verseNumber)',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_rounded, color: Colors.indigo),
              title: const Text('Тафсири Осонбаён'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                if (surahNumber == widget.surahNumber) {
                  _scrollToVerse(verseNumber);
                } else {
                  context.go('/surah/$surahNumber/verse/$verseNumber');
                }
              },
            ),
          ],
          ListTile(
            leading: Icon(
              isBookmarked
                  ? Icons.bookmark_remove_rounded
                  : Icons.bookmark_add_rounded,
              color: isBookmarked ? Colors.red : Colors.amber.shade800,
            ),
            title: Text(
              isBookmarked ? 'Пок кардани захира' : 'Захира кардан',
            ),
            onTap: () async {
              Navigator.of(sheetCtx).pop();
              final surahName = AppConstants.getSurahNameTajik(surahNumber);
              await ref
                  .read(bookmarkNotifierProvider(userId).notifier)
                  .toggleBookmark(verseModel, surahName);
              if (!mounted) return;
              SnackBarHelper.showSuccess(
                context: context,
                message: isBookmarked ? 'Захира пок шуд' : 'Оят захира шуд',
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy_rounded),
            title: const Text('Нусхабардорӣ'),
            onTap: () async {
              Navigator.of(sheetCtx).pop();
              final arabic = verseModel.arabicText.isNotEmpty
                  ? verseModel.arabicText
                  : getVerse(surahNumber, verseNumber);
              final translation = verseModel.ayatiText;
              final text = translation.trim().isEmpty
                  ? '$arabic\n($surahNumber:$verseNumber)'
                  : '$arabic\n\n$translation\n($surahNumber:$verseNumber)';
              await Clipboard.setData(ClipboardData(text: text));
              if (!mounted) return;
              SnackBarHelper.showSuccess(
                context: context,
                message: 'Нусхабардорӣ шуд',
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.share_rounded),
            title: const Text('Мубодила'),
            onTap: () async {
              Navigator.of(sheetCtx).pop();
              final arabic = verseModel.arabicText.isNotEmpty
                  ? verseModel.arabicText
                  : getVerse(surahNumber, verseNumber);
              final translation = verseModel.ayatiText;
              final text = translation.trim().isEmpty
                  ? '$arabic\n($surahNumber:$verseNumber)'
                  : '$arabic\n\n$translation\n($surahNumber:$verseNumber)';
              await ShareHelper.share(text);
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _ensureLastReadScrollListenerAttached() {
    if (_lastReadAttachScheduled) return;
    _lastReadAttachScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _lastReadListenerAttached) return;
      _itemPositionsListener.itemPositions
          .addListener(_onItemPositionsChangedLastRead);
      _lastReadListenerAttached = true;
    });
  }

  int _getInitialPage(List<VerseModel> verses) {
    if (widget.initialVerseNumber != null) {
      try {
        final verse = verses.firstWhere(
          (v) => v.verseNumber == widget.initialVerseNumber,
        );
        return verse.page ?? 1;
      } catch (_) {}
    }
    return verses.isNotEmpty ? (verses.first.page ?? 1) : 1;
  }

  void _showVerseAudioController(int verseNumber) {
    BottomSheetHelper.showStandard(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildVerseAudioController(verseNumber),
    );
  }

  Widget _buildVerseAudioController(int verseNumber) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Use shared audio service via controls; no local usage needed here
    final currentEdition = ref
        .read(surahControllerProvider(widget.surahNumber))
        .state
        .audioEdition;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 20),

            // Verse info - minimal
            Row(
              children: [
                Text(
                  'Ояти ${verseNumber}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Minimal reusable audio controls
            AudioPlayerControls(
              surahNumber: widget.surahNumber,
              verseNumber: verseNumber,
              edition: currentEdition,
              compact: false,
              showPrevNext: true,
            ),
          ],
        ),
      ),
    );
  }

  // Calculate initial scroll index for ScrollablePositionedList
  int? _calculateInitialScrollIndex(List<VerseModel> verses) {
    if (widget.initialVerseNumber == null || verses.isEmpty) {
      return null;
    }

    // Find the verse index in the verses list
    final verseIndex =
        verses.indexWhere((v) => v.verseNumber == widget.initialVerseNumber);
    if (verseIndex == -1) {
      return null;
    }

    // Header is at index 0, Bismillah is at index 1 (if exists)
    final hasBismillah = widget.surahNumber != 1 && widget.surahNumber != 9;
    final scrollIndex = hasBismillah ? verseIndex + 2 : verseIndex + 1;

    return scrollIndex;
  }

  // Note: _handleInitialScroll removed - using initialScrollIndex instead

  void _scrollToVerse(int verseNumber) {
    // Wait for verses to be available, then scroll
    final versesAsync = ref.read(versesProvider(widget.surahNumber));

    if (versesAsync.hasValue && versesAsync.value!.isNotEmpty) {
      _performScrollToVerse(versesAsync.value!, verseNumber);
    } else {
      // Wait for data to load
      versesAsync.whenData((verses) {
        if (verses.isNotEmpty && mounted) {
          _performScrollToVerse(verses, verseNumber);
        }
      });
    }
  }

  void _performScrollToVerse(List<dynamic> verses, int verseNumber) {
    // Find the verse index
    final verseIndex = verses.indexWhere((v) => v.verseNumber == verseNumber);
    if (verseIndex != -1) {
      // Header and Bismillah are at indices 0 and 1 (if bismillah exists)
      final hasBismillah = widget.surahNumber != 1 && widget.surahNumber != 9;
      final scrollIndex = hasBismillah ? verseIndex + 2 : verseIndex + 1;

      if (_itemScrollController.isAttached) {
        _itemScrollController.scrollTo(
          index: scrollIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.2,
        );
      }

      // Highlight the verse
      setState(() {
        _highlightedVerseIndex = verseIndex;
      });

      // Remove highlight after 1.5 seconds
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _highlightedVerseIndex = null;
          });
        }
      });
    }
  }

  void _openNavigator() {
    int currentSurah = widget.surahNumber;
    int currentVerse = 1;

    if (_mushafMode) {
      try {
        final ranges = getPageData(_currentMushafPage);
        if (ranges.isNotEmpty) {
          currentSurah = int.parse(ranges[0]['surah'].toString());
          currentVerse = int.parse(ranges[0]['start'].toString());
        }
      } catch (_) {}
    } else {
      final positions = _itemPositionsListener.itemPositions.value;
      if (positions.isNotEmpty) {
        final hasBismillah = widget.surahNumber != 1 && widget.surahNumber != 9;
        final firstVerseListIndex = hasBismillah ? 2 : 1;
        final verses = _lastReadVersesCache;
        for (final p in positions) {
          if (p.index >= firstVerseListIndex) {
            final vIdx = hasBismillah ? p.index - 2 : p.index - 1;
            if (verses != null && vIdx >= 0 && vIdx < verses.length) {
              currentVerse = verses[vIdx].verseNumber;
              break;
            }
          }
        }
      } else {
        currentVerse = _lastAutoScrolledVerse ?? widget.initialVerseNumber ?? 1;
      }
    }

    context.push('/search?filter=navigation&surah=$currentSurah&verse=$currentVerse');
  }

  @override
  Widget build(BuildContext context) {
    final surahAsync = ref.watch(surahProvider(widget.surahNumber));
    final versesAsync = ref.watch(versesProvider(widget.surahNumber));
    final controller = ref.watch(surahControllerProvider(widget.surahNumber));

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          final audio = QuranAudioService();
          if (event.logicalKey == LogicalKeyboardKey.space) {
            if (audio.playerState.playing) {
              audio.pause();
            } else {
              audio.resume();
            }
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            if (audio.currentVerseNumber != null) {
              audio.playNextVerse(edition: audio.currentEdition);
            } else if (widget.surahNumber < 114) {
              _navigateToSurah(widget.surahNumber + 1);
            }
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            if (audio.currentVerseNumber != null) {
              audio.playPreviousVerse(edition: audio.currentEdition);
            } else if (widget.surahNumber > 1) {
              _navigateToSurah(widget.surahNumber - 1);
            }
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            if (GoRouter.of(context).canPop()) {
              GoRouter.of(context).pop();
            } else {
              context.go('/quran');
            }
          }
        }
      },
      child: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              setState(() {
                _activeActionsIndex =
                    null; // hide any open verse actions when tapping anywhere
              });
            },
            child: PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop) {
                  if (GoRouter.of(context).canPop()) {
                    try {
                      GoRouter.of(context).pop();
                    } catch (_) {
                      context.go('/');
                    }
                  } else {
                    context.go('/');
                  }
                }
              },
              child: Scaffold(
              // Removed extendBody to ensure content never goes under system navigation bar
              appBar: AppBar(
                centerTitle: false,
                title: _mushafMode
                    ? Builder(
                        builder: (context) {
                          String surahTitle = 'Мусҳаф';
                          String subtitle = 'Саҳифаи $_currentMushafPage';
                          try {
                            final ranges = getPageData(_currentMushafPage);
                            if (ranges.isNotEmpty) {
                              final sNum = int.parse(ranges[0]['surah'].toString());
                              final vNum = int.parse(ranges[0]['start'].toString());
                              final sName = AppConstants.getSurahNameTajik(sNum);
                              final jNum = getJuzNumber(sNum, vNum);
                              surahTitle = 'Сураи $sName';
                              subtitle = 'Саҳифаи $_currentMushafPage · Ҷузъи $jNum';
                            }
                          } catch (_) {}

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                surahTitle,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                subtitle,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.normal,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          );
                        },
                      )
                    : surahAsync.when(
                        data: (surah) => Text(
                          surah != null
                              ? 'Сураи ${surah.nameTajik}'
                              : 'Сураи ${widget.surahNumber}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => Text(
                          'Сураи ${widget.surahNumber}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    // Check if we can pop (normal back navigation)
                    if (GoRouter.of(context).canPop()) {
                      GoRouter.of(context).pop();
                    } else {
                      // If no history, go to quran page (surahs list) instead of main menu
                      context.go('/quran');
                    }
                  },
                ),
                actions: [
                  // Mushaf view toggle
                  IconButton(
                    icon: Icon(
                      _mushafMode
                          ? Icons.menu_book_rounded
                          : Icons.auto_stories_outlined,
                    ),
                    onPressed: _toggleMushafMode,
                    tooltip: _mushafMode ? 'Ҳолати оятҳо' : 'Ҳолати Мусҳаф (15 сатр)',
                  ),
                  // Navigator button
                  IconButton(
                    icon: Transform.rotate(
                      angle: 0.5,
                      child: const Icon(Icons.navigation_outlined),
                    ),
                    onPressed: _openNavigator,
                    tooltip: 'Навигатор',
                  ),
                  // Settings icon - opens display settings
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => _showDisplaySettings(context),
                    tooltip: 'Танзимоти намоиш',
                  ),
                ],
              ),
              body: _mushafMode
                  ? Builder(
                      builder: (ctx) {
                        final media = MediaQuery.of(ctx);
                        final screenH = media.size.height;
                        final safeH = (screenH - 56.0).clamp(1.0, screenH);
                        final availableRatio = safeH / screenH;
                        final mushafScale = (availableRatio + 0.12).clamp(0.84, 0.92);

                        return PageviewQuran(
                          key: const ValueKey('mushaf_pageview'),
                          initialPageNumber: _currentMushafPage,
                          controller: _mushafPageController,
                          sp: mushafScale,
                          h: mushafScale,
                          theme: MushafThemeHelper.getTheme(ctx),
                          onPageChanged: (page) {
                            if (!mounted) return;
                            setState(() => _currentMushafPage = page);
                            try {
                              final ranges = getPageData(page);
                              if (ranges.isNotEmpty) {
                                final sNum = int.parse(ranges[0]['surah'].toString());
                                final vNum = int.parse(ranges[0]['start'].toString());
                                unawaited(_persistLastReadVerse(vNum, targetSurahNumber: sNum));
                              }
                            } catch (_) {}
                          },
                          verseBackgroundColor: (surah, verse) {
                            if (_highlightedVerseIndex != null) {
                              final verses = versesAsync.valueOrNull;
                              if (verses != null &&
                                  _highlightedVerseIndex! >= 0 &&
                                  _highlightedVerseIndex! < verses.length) {
                                final v = verses[_highlightedVerseIndex!];
                                if (v.surahId == surah && v.verseNumber == verse) {
                                  return Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.35);
                                }
                              }
                            }
                            return null;
                          },
                          onTap: (surah, verse) =>
                              _showVerseActionsFromNumbers(ctx, surah, verse),
                          onLongPress: (surah, verse) =>
                              _showVerseActionsFromNumbers(ctx, surah, verse),
                        );
                      },
                    )
                  : TweenAnimationBuilder<Offset>(
                key: ValueKey(widget.surahNumber),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                tween: Tween<Offset>(
                  begin: _slideBeginOffset,
                  end: Offset.zero,
                ),
                builder: (context, offset, child) {
                  if (offset == Offset.zero) return child!;
                  final double opacity = (1.0 - (offset.dx.abs() / 0.15)).clamp(0.0, 1.0);
                  return FractionalTranslation(
                    translation: offset,
                    child: Opacity(
                      opacity: opacity,
                      child: child,
                    ),
                  );
                },
                child: SafeArea(
                  top: false, // AppBar handles top
                  bottom:
                      false, // Bottom padding is handled dynamically by ScrollablePositionedList and mini player
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                  onTap: () {
                    setState(() {
                      _activeActionsIndex = null;
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    // Swipe right to go to next surah
                    if (details.primaryVelocity! > 0 &&
                        widget.surahNumber < 114) {
                      _navigateToSurah(widget.surahNumber + 1);
                    }
                    // Swipe left to go to previous surah
                    else if (details.primaryVelocity! < 0 &&
                        widget.surahNumber > 1) {
                      _navigateToSurah(widget.surahNumber - 1);
                    }
                  },
                  child: versesAsync.when(
                    data: (verses) {
                      if (verses.isEmpty) {
                        return const EmptyStateWidget(
                          title: 'Оятҳо ёфт нашуд',
                          message: 'Дар ҳоли ҳозир ҳеҷ ояте дар ин сура нест.',
                          icon: Icons.menu_book,
                        );
                      }

                      // Normal mode: show verse list

                      final hasBismillah =
                          widget.surahNumber != 1 && widget.surahNumber != 9;
                      final totalItems = hasBismillah ? verses.length + 2 : verses.length + 1;

                      return Consumer(
                        builder: (context, ref, child) {
                          final userId = ref.watch(currentUserIdProvider);
                          final bookmarkState =
                              ref.watch(bookmarkNotifierProvider(userId));

                          return surahAsync.when(
                            data: (surah) {
                              _lastReadVersesCache = verses;
                              _lastReadHasBismillah = hasBismillah;
                              _lastReadTotalItems = totalItems;
                              _ensureLastReadScrollListenerAttached();
                              unawaited(_writeInitialLastRead(surah, verses));
                              // Calculate initial scroll index if initialVerseNumber is provided
                              final initialScrollIndex =
                                  _calculateInitialScrollIndex(verses);

                              // Highlight the verse if initialVerseNumber is provided (only once)
                              if (initialScrollIndex != null &&
                                  !_hasHighlightedInitialVerse) {
                                final verseIndex = verses.indexWhere((v) =>
                                    v.verseNumber == widget.initialVerseNumber);
                                if (verseIndex != -1) {
                                  _hasHighlightedInitialVerse =
                                      true; // Mark as highlighted immediately to prevent re-triggering
                                  // Use a small delay to ensure the list is rendered
                                  Future.delayed(
                                      const Duration(milliseconds: 100), () {
                                    if (mounted) {
                                      setState(() {
                                        _highlightedVerseIndex = verseIndex;
                                      });
                                      // Remove highlight after 1.5 seconds
                                      Future.delayed(
                                          const Duration(milliseconds: 1500),
                                          () {
                                        if (mounted) {
                                          setState(() {
                                            _highlightedVerseIndex = null;
                                          });
                                        }
                                      });
                                    }
                                  });
                              }
                            }

                            return SafeArea(
                              bottom: !_hasActiveAudio,
                              child: ScrollablePositionedList.builder(
                                key: ValueKey(widget.surahNumber),
                                itemScrollController: _itemScrollController,
                                itemPositionsListener: _itemPositionsListener,
                                initialScrollIndex: initialScrollIndex ?? 0,
                                itemCount: totalItems,
                                padding: const EdgeInsets.only(bottom: 16),
                                itemBuilder: (context, index) {
                                  // Index 0: Header
                                  if (index == 0) {
                                    if (surah == null)
                                      return const SizedBox.shrink();
                                    final colorScheme = Theme.of(context).colorScheme;
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildModernSurahHeader(context,
                                            surah, verses, _plainCardsMode),
                                        if (_plainCardsMode)
                                          Divider(
                                            height: 1,
                                            thickness: 1.2,
                                            color: colorScheme.outline
                                                .withValues(alpha: 0.4),
                                            indent: 12,
                                            endIndent: 12,
                                          ),
                                      ],
                                    );
                                  }

                                  // Index 1: Bismillah (if exists)
                                  if (index == 1 && hasBismillah) {
                                    final plainCardsMode = _plainCardsMode;
                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 6),
                                      child: Center(
                                        child: Container(
                                          height: 80,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                                plainCardsMode ? 0 : 10),
                                            color: plainCardsMode
                                                ? Colors.transparent
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest
                                                    .withValues(alpha: 0.3),
                                            border: plainCardsMode
                                                ? null
                                                : Border.all(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .outline
                                                        .withValues(alpha: 0.1),
                                                    width: 1,
                                                  ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4),
                                            child: FittedBox(
                                              fit: BoxFit.contain,
                                              child: SvgPicture.asset(
                                                'assets/svgs/bismillah.svg',
                                                height: 140,
                                                colorFilter: ColorFilter.mode(
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.9),
                                                  BlendMode.srcIn,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  // Index 2+ (or 1+ if no bismillah): Verses or Continuous Mushaf View
                                  final verseIndex =
                                      hasBismillah ? index - 2 : index - 1;
                                  if (verseIndex < 0 ||
                                      verseIndex >= verses.length) {
                                    return const SizedBox.shrink();
                                  }

                                  final verse = verses[verseIndex];
                                  // Use only local Arabic text (Bismillah removed) instead of remote API text
                                  final arabicText = verse.arabicText;
                                  final wbw = controller
                                      .state.wordByWord[verse.uniqueKey]
                                      ?.map((w) => {
                                            'arabic': w.arabic,
                                            'meaning': w.farsi ?? ''
                                          })
                                      .toList();

                                  // Check if verse is bookmarked
                                  final isBookmarked = bookmarkState
                                          .bookmarkStatus[verse.uniqueKey] ??
                                      false;

                                  final audio = QuranAudioService();
                                  final edition = ref
                                      .read(surahControllerProvider(
                                          widget.surahNumber))
                                      .state
                                      .audioEdition;
                                  return StreamBuilder<PlaybackStateInfo>(
                                    stream: audio.uiStateStream,
                                    builder: (context, snap) {
                                      final info = snap.data;
                                      final isPlayingThis =
                                          (info?.currentSurahNumber ==
                                                  widget.surahNumber &&
                                              info?.currentVerseNumber ==
                                                  verse.verseNumber &&
                                              (info?.isPlaying ?? false));
                                      return VerseItem(
                                        verse: verse.copyWith(
                                            arabicText: arabicText),
                                        showTransliteration:
                                            _showTransliteration,
                                        showArabic: _showArabic,
                                         showTafsir: _showTafsir,
                                        isWordByWordMode: _isWordByWordMode,
                                        wordByWordTokens: wbw,
                                        showTranslation: _showTranslation,
                                        plainCardsMode: _plainCardsMode,
                                        arabicTextSize: _arabicTextSize,
                                        translationTextSize:
                                            _translationTextSize,
                                        transliterationTextSize:
                                            _transliterationTextSize,
                                        translationTextOverride: () {
                                          switch (_translationLang) {
                                            case 'tajik_ayati':
                                              return verse.ayatiText;
                                            case 'tajik_alomuddin':
                                              if (verse.alomuddinText == null ||
                                                  verse
                                                      .alomuddinText!.isEmpty) {
                                                return 'Тарҷумаи "Абуаломуддин" барои ин оят мавҷуд нест.';
                                              }
                                              return verse.alomuddinText!;
                                            case 'tajik_pioneers':
                                              if (verse.pioneersText == null ||
                                                  verse.pioneersText!.isEmpty) {
                                                return 'Тарҷумаи "Pioneers of Translation Center" барои ин оят мавҷуд нест.';
                                              }
                                              return verse.pioneersText!;
                                            case 'tajik_khojamirov':
                                              if (verse.khojamirovText ==
                                                      null ||
                                                  verse.khojamirovText!
                                                      .isEmpty) {
                                                return 'Тарҷумаи "Хоҷамиров" барои ин оят мавҷуд нест.';
                                              }
                                              return verse.khojamirovText!;
                                            case 'farsi':
                                              if (verse.farsi == null ||
                                                  verse.farsi!.isEmpty) {
                                                return 'Тарҷумаи "Форсӣ" барои ин оят мавҷуд нест.';
                                              }
                                              return verse.farsi!;
                                            case 'russian_kuliev':
                                              if (verse.russianKulievText ==
                                                      null ||
                                                  verse.russianKulievText!
                                                      .isEmpty) {
                                                return 'Тарҷумаи "Эльмир Кулиев" барои ин оят мавҷуд нест.';
                                              }
                                              return verse.russianKulievText!;
                                            default:
                                              return verse.ayatiText;
                                          }
                                        }(),
                                        isHighlighted: _highlightedVerseIndex ==
                                            verseIndex,
                                        isBookmarked: isBookmarked,
                                        isPlaying: isPlayingThis,
                                        showExtraActions: _showVerseActions,
                                        onTranslationChanged: (newLang) {
                                          setState(() {
                                            _translationLang = newLang;
                                          });
                                          ref.invalidate(versesProvider(
                                              widget.surahNumber));
                                        },
                                        onTap: () {
                                          if (_activeActionsIndex ==
                                              verseIndex) {
                                            setState(() {
                                              _activeActionsIndex = null;
                                            });
                                          }
                                        },
                                        onToggleActions: () {
                                          setState(() {
                                            _activeActionsIndex =
                                                _activeActionsIndex ==
                                                        verseIndex
                                                    ? null
                                                    : verseIndex;
                                          });
                                        },
                                        selectedTafsirSourceKey:
                                            _tafsirSourceKey,
                                        onTafsirSourceChanged:
                                            (String key) async {
                                          final s = SettingsService();
                                          await s.init();
                                          await s.setTafsirSource(key);
                                          if (mounted)
                                            setState(
                                                () => _tafsirSourceKey = key);
                                        },
                                        onPlayAudio: () async {
                                          await audio.togglePlayPause(
                                            surahNumber: widget.surahNumber,
                                            verseNumber: verse.verseNumber,
                                            edition: edition,
                                          );
                                          ref
                                              .read(surahControllerProvider(
                                                  widget.surahNumber))
                                              .setCurrentAyahIndex(verseIndex);
                                        },
                                        onBookmark: () async {
                                          final notifier = ref.read(
                                              bookmarkNotifierProvider(userId)
                                                  .notifier);
                                          final surahName =
                                              surahAsync.maybeWhen(
                                                  data: (s) =>
                                                      s?.nameTajik ?? '',
                                                  orElse: () => '');

                                          await notifier
                                              .toggleBookmark(verse, surahName);

                                          if (mounted) {
                                            SnackBarHelper.showSuccess(
                                              context: context,
                                              message: isBookmarked
                                                  ? 'Захира пок карда шуд'
                                                  : 'Оят ба захирагоҳ илова карда шуд',
                                              duration: const Duration(seconds: 2),
                                            );
                                          }
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            );
                          },
                          loading: () => LoadingFullScreenWidget(
                              backgroundColor:
                                  Theme.of(context).scaffoldBackgroundColor,
                              itemCount: 10,
                            ),
                            error: (error, stackTrace) => CustomErrorWidget(
                              title: 'Хатоги дар боргирӣ',
                              message:
                                  'Сураро наметавонем боргирӣ кунем. Лутфан пас аз чанд лаҳза такрор кӯшиш кунед.',
                              errorDetails: '$error\n$stackTrace',
                              onRetry: () {
                                ref.invalidate(
                                    surahProvider(widget.surahNumber));
                              },
                            ),
                          );
                        },
                      );
                    },
                    loading: () => LoadingFullScreenWidget(
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                      itemCount: 10,
                    ),
                    error: (error, stackTrace) => CustomErrorWidget(
                      title: 'Хатоги дар боргирӣ',
                      message:
                          'Оятҳоро наметавонем боргирӣ кунем. Лутфан пас аз чанд лаҳза такрор кӯшиш кунед.',
                      errorDetails: '$error\n$stackTrace',
                      onRetry: () {
                        ref.invalidate(versesProvider(widget.surahNumber));
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
            bottomNavigationBar: _hasActiveAudio ? _buildBottomMiniPlayer() : null,
          ),
          ),
        ),
        // Word-by-word error popup
        if (controller.state.showWordByWordError)
          _buildWordByWordErrorPopup(context, controller),
      ],
    ),
  );
}

  // Removed jump scrolling helper (no jump navigator)

  // Removed marker navigation (juz, hizb, ruku, manzil, page)

  Widget _buildBottomMiniPlayer() {
    final audio = QuranAudioService();
    final edition = ref
        .read(surahControllerProvider(widget.surahNumber))
        .state
        .audioEdition;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<PlaybackStateInfo>(
      stream: audio.uiStateStream,
      initialData: audio.currentPlaybackState,
      builder: (context, snapshot) {
        final info = snapshot.data;
        final hasActive = (info?.currentUrl != null) &&
            ((info?.processingState ?? ProcessingState.idle) !=
                ProcessingState.idle);
        if (!hasActive) {
          return const SizedBox.shrink();
        }

        final activeSurah = info!.currentSurahNumber ?? widget.surahNumber;
        final activeVerse = info.currentVerseNumber; // null -> surah mode
        final isPlaying = info.isPlaying;
        final position = info.position;
        final duration = info.duration ?? Duration.zero;
        final progress = duration.inMilliseconds > 0
            ? position.inMilliseconds / duration.inMilliseconds
            : 0.0;

        return SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress bar
                Container(
                  height: 3,
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    minHeight: 3,
                  ),
                ),
                // Main content
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      // Surah/Verse info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title
                            Text(
                              activeVerse == null
                                  ? 'Сураи $activeSurah'
                                  : 'Ояти $activeVerse',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            // Time info
                            Row(
                              children: [
                                Text(
                                  _formatDurationForPlayer(position),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  ' / ${_formatDurationForPlayer(duration)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Autoplay next button (continuous playback)
                      IconButton(
                        onPressed: () {
                          audio.toggleAutoPlayNextVerse();
                        },
                        icon: Icon(
                          Icons.playlist_play,
                          color: info.autoPlayNextVerse
                              ? colorScheme.primary
                              : colorScheme.onSurface.withValues(alpha: 0.55),
                          size: 22,
                        ),
                        iconSize: 22,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        tooltip: 'Пахши пайдарпай',
                      ),
                      // Previous button
                      IconButton(
                        onPressed: () async {
                          if (activeVerse != null) {
                            await audio.playPreviousVerse(edition: edition);
                          } else {
                            await audio.playPreviousSurah(edition: edition);
                          }
                        },
                        icon: Icon(
                          Icons.skip_previous,
                          color: colorScheme.onSurface,
                          size: 22,
                        ),
                        iconSize: 22,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        tooltip: 'Гузашта',
                      ),
                      // Play/Pause button (between previous and next)
                      IconButton(
                        onPressed: () async {
                          await audio.togglePlayPause(
                            surahNumber: activeSurah,
                            verseNumber: activeVerse,
                            edition: edition,
                          );
                        },
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: colorScheme.onSurface,
                          size: 22,
                        ),
                        iconSize: 22,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        tooltip: isPlaying ? 'Ист кардан' : 'Пахш кардан',
                      ),
                      // Next button
                      IconButton(
                        onPressed: () async {
                          if (activeVerse != null) {
                            await audio.playNextVerse(edition: edition);
                          } else {
                            await audio.playNextSurah(edition: edition);
                          }
                        },
                        icon: Icon(
                          Icons.skip_next,
                          color: colorScheme.onSurface,
                          size: 22,
                        ),
                        iconSize: 22,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        tooltip: 'Оянда',
                      ),
                      // Close button
                      IconButton(
                        onPressed: () async {
                          await audio.stop();
                        },
                        icon: Icon(
                          Icons.close,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          size: 20,
                        ),
                        iconSize: 20,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        tooltip: 'Пӯшидан',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDurationForPlayer(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showSurahInfoBottomSheet(BuildContext context, SurahModel surah) {
    if ((surah.description ?? '').trim().isEmpty) return;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    BottomSheetHelper.showStandard(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      maxHeightMultiplier: 0.7,
      builder: (context) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Маълумоти сура',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Сураи ${surah.nameTajik}',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildMetaChip(context, Icons.tag, 'Сураи №${surah.number}'),
                  _buildMetaChip(context, Icons.location_on_outlined, surah.revelationType),
                  _buildMetaChip(context, Icons.format_list_numbered, '${surah.versesCount} оят'),
                  if (surah.startPage != null && surah.endPage != null)
                    _buildMetaChip(
                      context,
                      Icons.auto_stories_outlined,
                      surah.startPage == surah.endPage
                          ? 'Саҳифаи ${surah.startPage}'
                          : 'Саҳифаҳои ${surah.startPage}-${surah.endPage}',
                    ),
                  if (surah.startJuz != null && surah.endJuz != null)
                    _buildMetaChip(
                      context,
                      Icons.chrome_reader_mode_outlined,
                      surah.startJuz == surah.endJuz
                          ? 'Ҷузъи ${surah.startJuz}'
                          : 'Ҷузъҳои ${surah.startJuz}-${surah.endJuz}',
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: cs.outlineVariant.withValues(alpha: 0.35)),
              const SizedBox(height: 16),
              _buildDescriptionParagraphs(
                surah.description!.trim(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  fontSize: 15,
                  color: cs.onSurface.withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetaChip(BuildContext context, IconData icon, String label) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  /// Renders [text] with paragraph support: splits on \n, renders each
  /// non-empty paragraph as a separate [Text] widget with 10 dp gap between them.
  /// Falls back to a single [Text] when there are no newlines.
  Widget _buildDescriptionParagraphs(String text, {TextStyle? style}) {
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
          if (i > 0) const SizedBox(height: 14),
          Text(paragraphs[i], style: style),
        ],
      ],
    );
  }

  void _showDisplaySettings(BuildContext context) {
    final controller = ref.read(surahControllerProvider(widget.surahNumber));

    BottomSheetHelper.showStandard(
      context: context,
      isScrollControlled: true,
      maxHeightMultiplier: 0.8,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(
                          Icons.settings,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Танзимоти намоиш',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Translation Language
                    _buildModernSettingTile(
                      context,
                      Icons.translate,
                      'Забони тарҷума',
                      _getTranslationLanguageName(_translationLang),
                      () => _showTranslationLanguageDialog(
                          context, setModalState),
                    ),

                    const SizedBox(height: 16),

                    // Qari Selection (Audio Settings)
                    Consumer(
                      builder: (context, ref, child) {
                        final qariId = controller.state.audioEdition;
                        final isTranslation = !qariId.startsWith('ar.');
                        final reciter = isTranslation
                            ? null
                            : ref.watch(reciterProvider(qariId));
                        final translation = isTranslation
                            ? ref.watch(translationAudioEditionProvider(qariId))
                            : null;

                        final displayName = isTranslation
                            ? (translation?.name ?? 'Тарҷума')
                            : (reciter != null
                                ? (reciter.nameTajik.isNotEmpty &&
                                        reciter.nameTajik != reciter.id
                                    ? reciter.nameTajik
                                    : (reciter.name.isNotEmpty &&
                                            reciter.name != reciter.id
                                        ? reciter.name
                                        : 'Қорӣ'))
                                : 'Қорӣ');

                        return _buildModernSettingTile(
                          context,
                          Icons.record_voice_over,
                          'Қори',
                          displayName,
                          () => _showReciterSelectionDialog(
                              context, setModalState, controller),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Arabic Font Selection
                    Consumer(
                      builder: (context, ref, child) {
                        final settings = ref.watch(settingsProvider);
                        final selectedFontLabel = AppConstants.arabicFontOptions.firstWhere(
                          (o) => o.key == settings.arabicFont,
                          orElse: () => AppConstants.arabicFontOptions.first,
                        ).label;

                        return _buildModernSettingTile(
                          context,
                          Icons.font_download_outlined,
                          'Шрифти Қуръон',
                          selectedFontLabel,
                          () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Шрифти Қуръонро интихоб кунед'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: AppConstants.arabicFontOptions.map((option) {
                                    final isTajweed =
                                        option.key == 'QPC_Hafs_Tajweed';
                                    return RadioListTile<String>(
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              option.label,
                                              style: TextStyle(
                                                fontFamily: AppConstants.getEffectiveFontFamily(option.key),
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                          if (isTajweed) ...[
                                            const SizedBox(width: 8),
                                            const BadgeLabel(text: 'НАВ'),
                                          ],
                                        ],
                                      ),
                                      value: option.key,
                                      groupValue: settings.arabicFont,
                                      onChanged: (value) {
                                        if (value != null) {
                                          if (value == 'QPC_Hafs_Tajweed') {
                                            ref
                                                .read(badgeControllerProvider)
                                                .markSeen(FeatureBadges.tajweedFont);
                                          }
                                          ref
                                              .read(settingsProvider.notifier)
                                              .setArabicFont(value);
                                          Navigator.pop(ctx);
                                          setModalState(() {});
                                        }
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Show Arabic Text
                    _buildModernSwitchTile(
                      context,
                      Icons.menu_book_rounded,
                      'Намоиши матни арабӣ',
                      '',
                      _showArabic,
                      (value) {
                        setModalState(() {
                          _showArabic = value;
                        });
                        setState(() {
                          _showArabic = value;
                        });
                        Future(() async {
                          final s = SettingsService();
                          await s.init();
                          await s.setShowArabic(value);
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Show Tafsir
                    _buildModernSwitchTile(
                      context,
                      Icons.auto_stories_rounded,
                      'Намоиши тафсир',
                      '',
                      _showTafsir,
                      (value) {
                        setModalState(() {
                          _showTafsir = value;
                        });
                        setState(() {
                          _showTafsir = value;
                        });
                        Future(() async {
                          final s = SettingsService();
                          await s.init();
                          await s.setShowTafsir(value);
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Word by Word Mode
                    _buildModernSwitchTile(
                      context,
                      Icons.format_list_bulleted,
                      'Ҳолати калима ба калима',
                      '',
                      _isWordByWordMode,
                      (value) async {
                        setModalState(() {
                          _isWordByWordMode = value;
                        });
                        setState(() {
                          _isWordByWordMode = value;
                        });

                        if (value) {
                          final versesAsyncValue =
                              ref.read(versesProvider(widget.surahNumber));
                          versesAsyncValue.whenData((verses) {
                            if (mounted) {
                              ref
                                  .read(surahControllerProvider(
                                      widget.surahNumber))
                                  .loadWordByWord(verses);
                            }
                          });
                        }
                        Future(() async {
                          final s = SettingsService();
                          await s.init();
                          await s.setWordByWordMode(value);
                        });

                        if (value && !controller.state.wordByWordAvailable) {
                          controller.showWordByWordError();
                        }
                      },
                    ),

                    const Divider(height: 24),

                    // Text Size Section Header
                    Row(
                      children: [
                        Icon(
                          Icons.text_fields,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Андозаи матн',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Arabic Text Size Slider
                    _buildTextSizeSlider(
                      context,
                      'Матни арабӣ',
                      _arabicTextSize,
                      14,
                      36,
                      (val) {
                        setModalState(() => _arabicTextSize = val);
                        setState(() => _arabicTextSize = val);
                      },
                      (val) async {
                        final s = SettingsService();
                        await s.init();
                        await s.setArabicTextSize(val);
                        if (mounted) ref.invalidate(quranTextSizesProvider);
                      },
                    ),

                    // Translation Text Size Slider
                    _buildTextSizeSlider(
                      context,
                      'Тарҷума',
                      _translationTextSize,
                      12,
                      28,
                      (val) {
                        setModalState(() => _translationTextSize = val);
                        setState(() => _translationTextSize = val);
                      },
                      (val) async {
                        final s = SettingsService();
                        await s.init();
                        await s.setTranslationTextSize(val);
                        if (mounted) ref.invalidate(quranTextSizesProvider);
                      },
                    ),

                    // Transliteration Text Size Slider
                    _buildTextSizeSlider(
                      context,
                      'Транслитератсия',
                      _transliterationTextSize,
                      10,
                      24,
                      (val) {
                        setModalState(() => _transliterationTextSize = val);
                        setState(() => _transliterationTextSize = val);
                      },
                      (val) async {
                        final s = SettingsService();
                        await s.init();
                        await s.setTransliterationTextSize(val);
                        if (mounted) ref.invalidate(quranTextSizesProvider);
                      },
                    ),

                    const SizedBox(height: 12),

                    // Reset Default Sizes Button
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          setModalState(() {
                            _arabicTextSize = AppConstants.defaultArabicTextSize;
                            _translationTextSize = AppConstants.defaultTranslationTextSize;
                            _transliterationTextSize = AppConstants.defaultTransliterationTextSize;
                          });
                          setState(() {
                            _arabicTextSize = AppConstants.defaultArabicTextSize;
                            _translationTextSize = AppConstants.defaultTranslationTextSize;
                            _transliterationTextSize = AppConstants.defaultTransliterationTextSize;
                          });
                          final s = SettingsService();
                          await s.init();
                          await s.resetTextSizesToDefaults();
                          if (mounted) ref.invalidate(quranTextSizesProvider);
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Барқарор кардани андозаи пешфарз'),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      );
  }

  Widget _buildTextSizeSlider(
    BuildContext context,
    String title,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    ValueChanged<double> onChangeEnd,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${value.round()} pt',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).round(),
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
              activeColor: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _getTranslationLanguageName(String lang) {
    return AppConstants.getTranslationName(lang);
  }

  void _showTranslationLanguageDialog(
      BuildContext context, StateSetter setModalState) {
    showDialog(
      context: context,
      builder: (context) => TranslationSelectionDialog(
        currentTranslation: _translationLang,
        surahNumber: widget.surahNumber,
        onTranslationSelected: (newLang) {
          setState(() {
            _translationLang = newLang;
          });
          // Update settings
          Future(() async {
            final s = SettingsService();
            await s.init();
            await s.setTranslationLanguage(newLang);
          });
          // Reload verses to show new translation
          ref.invalidate(versesProvider(widget.surahNumber));
        },
      ),
    );
  }

  void _navigateToSurah(int surahNumber) {
    if (surahNumber >= 1 && surahNumber <= 114) {
      final direction = surahNumber > widget.surahNumber ? 'right' : 'left';
      context.go('/surah/$surahNumber?swipe=$direction');
    }
  }

  Widget _buildModernSettingTile(BuildContext context, IconData icon,
      String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: (subtitle.trim().isEmpty)
            ? null
            : Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildModernSwitchTile(BuildContext context, IconData icon,
      String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: (subtitle.trim().isEmpty)
            ? null
            : Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
        value: value,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }



  // Get proper reciter name from provider (no hardcoded fallbacks, never show ID)
  String? _getQariDisplayName(String qariId) {
    final reciter = ref.read(reciterProvider(qariId));
    if (reciter != null) {
      // Never show ID, always use proper name
      if (reciter.nameTajik.isNotEmpty && reciter.nameTajik != reciter.id) {
        return reciter.nameTajik;
      }
      if (reciter.name.isNotEmpty && reciter.name != reciter.id) {
        return reciter.name;
      }
    }
    // Return null if reciter not found or name equals ID
    return null;
  }

  void _showReciterSelectionDialog(
      BuildContext context, StateSetter setModalState, dynamic controller) {
    final currentEdition = controller.state.audioEdition;

    showDialog(
      context: context,
      builder: (dialogContext) => ReciterSelectionDialog(
        currentReciterId: currentEdition,
      ),
    ).then((selectedReciterId) {
      if (selectedReciterId != null && mounted) {
        // Update the surah controller with the new edition
        controller.setAudioEdition(selectedReciterId);
        // Update settings
        Future(() async {
          final settings = SettingsService();
          await settings.init();
          await settings.setAudioEdition(selectedReciterId);
        });
        // Refresh the dialog state
        setModalState(() {});
      }
    });
  }

  Widget _buildWordByWordErrorPopup(BuildContext context, dynamic controller) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wifi_off,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ҳолати калима ба калима дастрас нест',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.error,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Интернет пайваст нест. Лутфан интернетро тафтиш кунед ва дубора кӯшиш кунед.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          controller.hideWordByWordError();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Тасдиқ кардан'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          controller.hideWordByWordError();
                          // Reload the surah to try fetching word-by-word data again
                          controller.load(
                            surahNumber: widget.surahNumber,
                            audioEdition: controller.state.audioEdition,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Такрор кӯшиш'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernSurahHeader(BuildContext context, SurahModel surah,
      List<VerseModel>? verses, bool plainCardsMode) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: plainCardsMode ? Colors.transparent : colorScheme.surface,
        borderRadius: BorderRadius.circular(plainCardsMode ? 0 : 16),
        border: plainCardsMode
            ? null
            : Border.all(
                color: colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
        boxShadow: plainCardsMode
            ? null
            : [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Play Button on the left
                StreamBuilder<PlaybackStateInfo>(
                  stream: QuranAudioService().uiStateStream,
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    final isPlayingThisSurah =
                        info?.currentSurahNumber == surah.number &&
                            (info?.isPlaying ?? false);

                    return Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () async {
                          final audioService = QuranAudioService();
                          final controller = ref
                              .read(surahControllerProvider(widget.surahNumber));
                          final edition = controller.state.audioEdition;

                          if (isPlayingThisSurah) {
                            await audioService.pause();
                          } else {
                            try {
                              await audioService.playSurahVerseByVerse(
                                  surah.number,
                                  edition: edition);
                            } catch (e) {
                              if (mounted) {
                                SnackBarHelper.showError(
                                  context: context,
                                  message: 'Хатоги дар пахш кардани оятҳо: ${e.toString()}',
                                  duration: const Duration(seconds: 3),
                                );
                              }
                            }
                          }
                        },
                        icon: Icon(
                          isPlayingThisSurah ? Icons.pause : Icons.play_arrow,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                          maxWidth: 32,
                          maxHeight: 32,
                        ),
                        tooltip: isPlayingThisSurah
                            ? 'Ист кардан'
                            : 'Пахш кардани сура',
                      ),
                    );
                  },
                ),

                const SizedBox(width: 20), // Spacing between play button and SVG name

                // 2. Surah Name SVG (directly in center, flexible to prevent overflow)
                Flexible(
                  child: _buildArabicNameSvg(surah, theme, colorScheme),
                ),

                const SizedBox(width: 20), // Spacing between SVG name and info button

                // 3. Info / Bottom sheet button on the right (or empty spacer to preserve centering)
                if ((surah.description ?? '').trim().isNotEmpty)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => _showSurahInfoBottomSheet(context, surah),
                      icon: Icon(
                        Icons.info_outline,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                        maxWidth: 32,
                        maxHeight: 32,
                      ),
                      tooltip: 'Маълумоти сура',
                    ),
                  )
                else
                  const SizedBox(width: 32, height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArabicNameSvg(
      SurahModel surah, ThemeData theme, ColorScheme colorScheme) {
    final svgColor = colorScheme.onSurface;

    return SizedBox(
      height: 50,
      child: SvgPicture.asset(
        _svgService.getSurahSvgAssetPath(surah.number),
        fit: BoxFit.contain,
        alignment: Alignment.center,
        colorFilter: ColorFilter.mode(
          svgColor,
          BlendMode.srcIn,
        ),
        semanticsLabel: surah.nameArabic,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

// Navigation dialog widget
class _NavigationDialog extends StatefulWidget {
  final int currentSurah;
  final List<SurahModel> surahs;
  final TextEditingController verseController;
  final void Function(int surahNumber, int? verseNumber) onNavigate;

  const _NavigationDialog({
    required this.currentSurah,
    required this.surahs,
    required this.verseController,
    required this.onNavigate,
  });

  @override
  State<_NavigationDialog> createState() => _NavigationDialogState();
}

class _NavigationDialogState extends State<_NavigationDialog> {
  late int _selectedSurah;
  final GlobalKey _dropdownKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _selectedSurah = widget.currentSurah;
  }

  @override
  void dispose() {
    widget.verseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Навигатор'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Surah selector
            Text(
              'Сура',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (builderContext) {
                return Container(
                  key: _dropdownKey,
                  height: 48,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      // Show menu below the button
                      final RenderBox? renderBox = _dropdownKey.currentContext
                          ?.findRenderObject() as RenderBox?;
                      final Offset? offset =
                          renderBox?.localToGlobal(Offset.zero);
                      final Size? size = renderBox?.size;

                      if (offset != null && size != null) {
                        showMenu<int>(
                          context: builderContext,
                          position: RelativeRect.fromLTRB(
                            offset.dx,
                            offset.dy + size.height + 4,
                            offset.dx + size.width,
                            offset.dy + size.height + 304,
                          ),
                          items: widget.surahs.map((surah) {
                            return PopupMenuItem<int>(
                              value: surah.number,
                              child: Text(
                                  '${surah.number}. Сураи ${surah.nameTajik}'),
                            );
                          }).toList(),
                        ).then((value) {
                          if (value != null) {
                            setState(() {
                              _selectedSurah = value;
                            });
                          }
                        });
                      }
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_selectedSurah}. Сураи ${widget.surahs.firstWhere((s) => s.number == _selectedSurah).nameTajik}',
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Verse input
            Text(
              'Оят (ихтиёрӣ)',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.verseController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Рақами оят',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Бекор кардан'),
        ),
        FilledButton(
          onPressed: () {
            final verseText = widget.verseController.text.trim();
            if (verseText.isNotEmpty) {
              final verseNumber = int.tryParse(verseText);
              if (verseNumber != null && verseNumber >= 1) {
                Navigator.of(context).pop();
                widget.onNavigate(_selectedSurah, verseNumber);
              } else {
                SnackBarHelper.showWarning(
                  context: context,
                  message: 'Рақами оят нодуруст аст',
                );
              }
            } else {
              Navigator.of(context).pop();
              widget.onNavigate(_selectedSurah, null);
            }
          },
          child: const Text('Рафтан'),
        ),
      ],
    );
  }
}

// JumpChip removed with marker navigation
