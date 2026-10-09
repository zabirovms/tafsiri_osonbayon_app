import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qcf_quran/qcf_quran.dart';
import '../../../core/theme/mushaf_theme_helper.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'dart:async';

import '../../../data/models/verse_model.dart';
import '../../../data/models/surah_model.dart';
import '../../../data/services/audio_service.dart';
import '../../../core/utils/bottom_sheet_helper.dart';
import '../../../core/utils/share_helper.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/quran_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/quran_last_read_provider.dart';
import '../../../data/services/quran_last_read_service.dart';
import '../../../core/constants/app_constants.dart';

const int kTotalMushafPages = 604;
const double kHeaderHeight = 56.0;

class MushafPage extends ConsumerStatefulWidget {
  final int? initialPage;
  final int? initialSurah;
  final int? initialVerse;

  const MushafPage({
    super.key,
    this.initialPage,
    this.initialSurah,
    this.initialVerse,
  });

  @override
  ConsumerState<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends ConsumerState<MushafPage> {
  late final PageController _mushafController;
  final ItemScrollController _listScrollController = ItemScrollController();
  final ItemPositionsListener _listPositionsListener = ItemPositionsListener.create();

  late int _currentPage;
  int _currentSurah = 1;
  int _currentVerse = 1;
  bool _isMushafMode = true;
  String? _highlightedAyahKey;
  Timer? _highlightTimer;
  StreamSubscription<PlaybackStateInfo>? _audioSubscription;

  @override
  void initState() {
    super.initState();
    _currentPage = _resolveInitialPage();
    _mushafController = PageController(initialPage: _currentPage - 1);
    _syncSurahVerseFromPage(_currentPage);

    if (widget.initialSurah != null && widget.initialVerse != null) {
      _highlightedAyahKey = '${widget.initialSurah}:${widget.initialVerse}';
    }

    _audioSubscription =
        QuranAudioService().uiStateStream.listen(_handleAudioState);

    _listPositionsListener.itemPositions.addListener(_onListPositionChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _recordMushafLastRead(_currentPage);
      }
    });
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _audioSubscription?.cancel();
    _listPositionsListener.itemPositions.removeListener(_onListPositionChanged);
    _mushafController.dispose();
    super.dispose();
  }

  int _resolveInitialPage() {
    if (widget.initialPage != null) {
      return widget.initialPage!.clamp(1, kTotalMushafPages);
    }
    if (widget.initialSurah != null && widget.initialVerse != null) {
      try {
        return getPageNumber(widget.initialSurah!, widget.initialVerse!);
      } catch (_) {
        return 1;
      }
    }
    return 1;
  }

  void _syncSurahVerseFromPage(int page) {
    try {
      final ranges = getPageData(page);
      if (ranges.isNotEmpty) {
        _currentSurah = int.parse(ranges[0]['surah'].toString());
        _currentVerse = int.parse(ranges[0]['start'].toString());
      }
    } catch (_) {}
  }

  void _recordMushafLastRead(int page) {
    if (!mounted) return;
    try {
      final ranges = getPageData(page);
      if (ranges.isNotEmpty) {
        final sNum = int.parse(ranges[0]['surah'].toString());
        final vNum = int.parse(ranges[0]['start'].toString());
        final surahs = ref.read(surahsProvider).valueOrNull;
        final match = surahs?.where((s) => s.number == sNum).firstOrNull;
        final sName = match?.nameTajik ?? AppConstants.getSurahNameTajik(sNum);
        final totalCount = match?.versesCount;

        ref.read(quranLastReadServiceProvider).recordVisit(
              QuranLastReadEntry(
                surahNumber: sNum,
                verseNumber: vNum,
                surahNameTajik: sName,
                surahAyahCount: totalCount,
              ),
            );
        ref.invalidate(quranLastReadListProvider);
      }
    } catch (_) {}
  }

  void _handleAudioState(PlaybackStateInfo info) {
    final surah = info.currentSurahNumber;
    final verse = info.currentVerseNumber;
    if (!mounted || surah == null || verse == null) return;

    final ayahKey = '$surah:$verse';
    if (_highlightedAyahKey != ayahKey) {
      setState(() => _highlightedAyahKey = ayahKey);
    }
  }

  void _onListPositionChanged() {
    if (_isMushafMode || !mounted) return;
    final positions = _listPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // Find top-most visible item index
    final topItem = positions.reduce((a, b) => a.itemLeadingEdge < b.itemLeadingEdge ? a : b);
    final pageIndex = topItem.index + 1; // 1-based page number in Ayah list
    if (pageIndex >= 1 && pageIndex <= kTotalMushafPages && pageIndex != _currentPage) {
      setState(() {
        _currentPage = pageIndex;
        _syncSurahVerseFromPage(pageIndex);
      });
    }
  }

  Future<void> _toggleViewMode() async {
    setState(() {
      _isMushafMode = !_isMushafMode;
    });

    if (_isMushafMode) {
      // Switching to Mushaf page mode: jump controller to _currentPage
      await Future.delayed(const Duration(milliseconds: 50));
      if (_mushafController.hasClients) {
        _mushafController.jumpToPage(_currentPage - 1);
      }
    } else {
      // Switching to Ayah list mode: scroll list to _currentPage index
      await Future.delayed(const Duration(milliseconds: 50));
      if (_listScrollController.isAttached) {
        _listScrollController.jumpTo(index: _currentPage - 1);
      }
    }
  }

  void _highlightVerseTemporary(int surah, int verse) {
    setState(() {
      _highlightedAyahKey = '$surah:$verse';
    });
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _highlightedAyahKey = null);
      }
    });
  }

  Future<void> _jumpToLocation({int? page, int? surah, int? verse, int? juz}) async {
    int targetPage = _currentPage;

    if (page != null) {
      targetPage = page.clamp(1, kTotalMushafPages);
    } else if (surah != null) {
      final v = verse ?? 1;
      try {
        targetPage = getPageNumber(surah, v);
      } catch (_) {
        targetPage = 1;
      }
    } else if (juz != null) {
      // Find start page for juz
      targetPage = ((juz - 1) * 20 + 2).clamp(1, kTotalMushafPages);
    }

    setState(() {
      _currentPage = targetPage;
      if (surah != null && verse != null) {
        _currentSurah = surah;
        _currentVerse = verse;
      } else {
        _syncSurahVerseFromPage(targetPage);
      }
    });

    if (surah != null && verse != null) {
      _highlightVerseTemporary(surah, verse);
    }

    if (_isMushafMode) {
      if (_mushafController.hasClients) {
        await _mushafController.animateToPage(
          targetPage - 1,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    } else {
      if (_listScrollController.isAttached) {
        _listScrollController.scrollTo(
          index: targetPage - 1,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  Future<void> _showNavigatorDialog() async {
    final surahs = ref.read(surahsProvider).valueOrNull ?? [];
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => _MushafNavigatorDialog(
        currentSurah: _currentSurah,
        currentVerse: _currentVerse,
        currentPage: _currentPage,
        surahs: surahs,
        onNavigateSurahVerse: (surah, verse) {
          Navigator.of(dialogCtx).pop();
          _jumpToLocation(surah: surah, verse: verse);
        },
        onNavigatePage: (page) {
          Navigator.of(dialogCtx).pop();
          _jumpToLocation(page: page);
        },
        onNavigateJuz: (juz) {
          Navigator.of(dialogCtx).pop();
          _jumpToLocation(juz: juz);
        },
      ),
    );
  }

  void _showSettingsSheet() {
    final theme = Theme.of(context);
    BottomSheetHelper.showStandard<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Танзимоти намоиш',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                _isMushafMode ? Icons.format_list_bulleted : Icons.auto_stories,
              ),
              title: Text(
                _isMushafMode
                    ? 'Гузариш ба рӯйхати оятҳо'
                    : 'Гузариш ба намуди Мусҳаф (15 сатр)',
              ),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _toggleViewMode();
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_outline),
              title: const Text('Нишонҳо ва хатм'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                context.push('/bookmarks');
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Танзимоти умумии барнома'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                context.push('/settings');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showVerseActions(int surahNumber, int verseNumber) async {
    final userId = ref.read(currentUserIdProvider);
    final verseKey = '$surahNumber:$verseNumber';
    final bookmarkState = ref.read(bookmarkNotifierProvider(userId));
    final isBookmarked = bookmarkState.bookmarkStatus[verseKey] ?? false;

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
        uniqueKey: verseKey,
      ),
    );

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF7F1E6);

    final media = MediaQuery.of(context);
    final screenH = media.size.height;
    final safeH = (screenH - kHeaderHeight).clamp(1.0, screenH);
    final availableRatio = safeH / screenH;
    final mushafScale = (availableRatio + 0.12).clamp(0.84, 0.92);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/quran');
            }
          },
        ),
        title: Builder(
          builder: (context) {
            String surahTitle = 'Мусҳаф';
            String subtitle = 'Саҳифаи $_currentPage';
            try {
              final ranges = getPageData(_currentPage);
              if (ranges.isNotEmpty) {
                final sNum = int.parse(ranges[0]['surah'].toString());
                final vNum = int.parse(ranges[0]['start'].toString());
                final sName = AppConstants.getSurahNameTajik(sNum);
                final jNum = getJuzNumber(sNum, vNum);
                surahTitle = 'Сураи $sName';
                subtitle = 'Саҳифаи $_currentPage · Ҷузъи $jNum';
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
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: _isMushafMode ? 'Рӯйхати оятҳо' : 'Саҳифаи Мусҳаф',
            icon: Icon(
              _isMushafMode ? Icons.format_list_bulleted_rounded : Icons.menu_book_rounded,
            ),
            onPressed: _toggleViewMode,
          ),
          IconButton(
            tooltip: 'Навигатор',
            icon: const Icon(Icons.explore_outlined),
            onPressed: _showNavigatorDialog,
          ),
          IconButton(
            tooltip: 'Танзимот',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _showSettingsSheet,
          ),
        ],
      ),
      body: _isMushafMode
          ? PageviewQuran(
              key: const ValueKey('mushaf_view'),
              initialPageNumber: _currentPage,
              controller: _mushafController,
              sp: mushafScale,
              h: mushafScale,
              theme: MushafThemeHelper.getTheme(context),
              onPageChanged: (page) {
                if (!mounted) return;
                setState(() {
                  _currentPage = page;
                  _syncSurahVerseFromPage(page);
                });
                _recordMushafLastRead(page);
              },
              verseBackgroundColor: (surah, verse) {
                if (_highlightedAyahKey == '$surah:$verse') {
                  return cs.primary.withValues(alpha: 0.35);
                }
                return null;
              },
              onTap: (surah, verse) => _showVerseActions(surah, verse),
              onLongPress: (surah, verse) => _showVerseActions(surah, verse),
            )
          : ScrollablePositionedList.builder(
              key: const ValueKey('ayah_list_view'),
              itemScrollController: _listScrollController,
              itemPositionsListener: _listPositionsListener,
              itemCount: kTotalMushafPages,
              initialScrollIndex: _currentPage - 1,
              itemBuilder: (ctx, pageIndex) {
                final pageNum = pageIndex + 1;
                return _AyahPageCard(
                  pageNumber: pageNum,
                  highlightedAyahKey: _highlightedAyahKey,
                  onVerseTap: (surah, verse) => _showVerseActions(surah, verse),
                );
              },
            ),
    );
  }
}

class _AyahPageCard extends StatelessWidget {
  final int pageNumber;
  final String? highlightedAyahKey;
  final void Function(int surah, int verse) onVerseTap;

  const _AyahPageCard({
    required this.pageNumber,
    required this.highlightedAyahKey,
    required this.onVerseTap,
  });

  @override
  Widget build(BuildContext context) {
    final ranges = getPageData(pageNumber);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final firstSurah = ranges.isNotEmpty ? int.parse(ranges[0]['surah'].toString()) : 1;
    final firstVerse = ranges.isNotEmpty ? int.parse(ranges[0]['start'].toString()) : 1;
    final juz = getJuzNumber(firstSurah, firstVerse);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Page & Juz Header Divider
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Саҳифаи $pageNumber',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Ҷузъи $juz • Сураи ${AppConstants.getSurahNameTajik(firstSurah)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final r in ranges) ...[
                  _buildSurahBlock(context, r),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahBlock(BuildContext context, Map r) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final surah = int.parse(r['surah'].toString());
    final start = int.parse(r['start'].toString());
    final end = int.parse(r['end'].toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (start == 1) ...[
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Сураи ${AppConstants.getSurahNameTajik(surah)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cs.primary,
                fontSize: 15,
              ),
            ),
          ),
        ],
        for (int v = start; v <= end; v++) ...[
          Builder(
            builder: (ctx) {
              final verseKey = '$surah:$v';
              final isHighlighted = (highlightedAyahKey == verseKey);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? cs.primary.withValues(alpha: 0.22)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: InkWell(
                  onTap: () => onVerseTap(surah, v),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          getVerse(surah, v, verseEndSymbol: true),
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontSize: 22,
                            height: 1.8,
                            fontFamily: 'Amiri',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '[$surah:$v]',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

// Navigation dialog matching surah_page.dart Navigator style
class _MushafNavigatorDialog extends StatefulWidget {
  final int currentSurah;
  final int currentVerse;
  final int currentPage;
  final List<SurahModel> surahs;
  final void Function(int surahNumber, int verseNumber) onNavigateSurahVerse;
  final void Function(int pageNumber) onNavigatePage;
  final void Function(int juzNumber) onNavigateJuz;

  const _MushafNavigatorDialog({
    required this.currentSurah,
    required this.currentVerse,
    required this.currentPage,
    required this.surahs,
    required this.onNavigateSurahVerse,
    required this.onNavigatePage,
    required this.onNavigateJuz,
  });

  @override
  State<_MushafNavigatorDialog> createState() => _MushafNavigatorDialogState();
}

class _MushafNavigatorDialogState extends State<_MushafNavigatorDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _selectedSurah;
  late final TextEditingController _verseController;
  late final TextEditingController _pageController;
  late final TextEditingController _juzController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedSurah = widget.currentSurah;
    _verseController = TextEditingController(text: widget.currentVerse.toString());
    _pageController = TextEditingController(text: widget.currentPage.toString());
    _juzController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _verseController.dispose();
    _pageController.dispose();
    _juzController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AlertDialog(
      title: const Text('Навигатор'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabController,
              labelColor: cs.primary,
              unselectedLabelColor: cs.onSurface.withValues(alpha: 0.6),
              indicatorColor: cs.primary,
              tabs: const [
                Tab(text: 'Сура & Оят'),
                Tab(text: 'Саҳифа'),
                Tab(text: 'Ҷузъ'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Surah & Verse
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Интихоби Сура', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        initialValue: _selectedSurah,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: widget.surahs.map((s) {
                          return DropdownMenuItem<int>(
                            value: s.number,
                            child: Text(
                              '${s.number}. ${s.nameTajik}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedSurah = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      Text('Рақами Оят', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _verseController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: '1',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),

                  // Tab 2: Page Number
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Рақами Саҳифа (1 - 604)', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _pageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: 'Саҳифа (1-604)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),

                  // Tab 3: Juz Number
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Рақами Ҷузъ (1 - 30)', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _juzController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: 'Ҷузъ (1-30)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ],
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
            if (_tabController.index == 0) {
              final v = int.tryParse(_verseController.text.trim()) ?? 1;
              widget.onNavigateSurahVerse(_selectedSurah, v);
            } else if (_tabController.index == 1) {
              final p = int.tryParse(_pageController.text.trim()) ?? 1;
              widget.onNavigatePage(p);
            } else if (_tabController.index == 2) {
              final j = int.tryParse(_juzController.text.trim()) ?? 1;
              widget.onNavigateJuz(j);
            }
          },
          child: const Text('Рафтан'),
        ),
      ],
    );
  }
}
