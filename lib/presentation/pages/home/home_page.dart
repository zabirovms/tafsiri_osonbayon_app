import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/quran_provider.dart';
import '../../providers/quran_last_read_provider.dart';
import '../../widgets/quran/surah_list_item.dart';
import '../../widgets/quran/juz_list_item.dart' show JuzInfo, JuzListItem;
import '../../widgets/quran/page_list_item.dart' show PageInfo, PageListItem;
import '../../widgets/bottom_navigation_bar_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../widgets/share_rate_dialog.dart';
import '../../../data/models/surah_model.dart';

import '../../../data/services/quran_last_read_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/bottom_sheet_helper.dart';

/// Same relative-date wording as Bukhari / Masnavi (`Имрӯз · HH:MM`, etc.).
String? _formatQuranLastReadVisited(int visitedAtMillis) {
  if (visitedAtMillis <= 0) return null;
  final d = DateTime.fromMillisecondsSinceEpoch(visitedAtMillis);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yday = today.subtract(const Duration(days: 1));
  final day = DateTime(d.year, d.month, d.day);
  String hm(int x) => x < 10 ? '0$x' : '$x';
  final clock = '${hm(d.hour)}:${hm(d.minute)}';
  if (day == today) return 'Имрӯз · $clock';
  if (day == yday) return 'Дирӯз · $clock';
  return '${d.day}.${d.month}.${d.year} · $clock';
}

/// Display line «Сураи …» (avoids doubling if stored name already starts with «Сураи»).
String _quranSurahTitleLine(QuranLastReadEntry e, List<SurahModel>? surahs) {
  if (surahs != null) {
    for (final s in surahs) {
      if (s.number == e.surahNumber) {
        return 'Сураи ${s.nameTajik}';
      }
    }
  }
  if (e.surahNameTajik.isNotEmpty) {
    final t = e.surahNameTajik.trim();
    final lower = t.toLowerCase();
    if (lower.startsWith('сураи ')) return t;
    return 'Сураи $t';
  }
  return 'Сураи ${e.surahNumber}';
}

/// Progress through the surah by current ayah vs total ayahs; `null` if total unknown.
String? _quranSurahProgressLine(
    QuranLastReadEntry e, List<SurahModel>? surahs) {
  int? total;
  if (e.surahAyahCount != null && e.surahAyahCount! > 0) {
    total = e.surahAyahCount;
  } else if (surahs != null) {
    for (final s in surahs) {
      if (s.number == e.surahNumber) {
        total = s.versesCount;
        break;
      }
    }
  }
  if (total == null || total < 1) return 'Ояти ${e.verseNumber}';
  final denom = max(total, e.verseNumber);
  final v = e.verseNumber.clamp(1, denom);
  final pct = (100.0 * v / denom).round();
  return 'Ояти $v аз $denom ($pct%)';
}

void _showQuranLastReadSheet(
  BuildContext context,
  WidgetRef ref,
  List<QuranLastReadEntry> items,
) {
  if (items.isEmpty) return;

  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  final parentContext = context;
  final maxListHeight = MediaQuery.sizeOf(context).height * 0.52;
  final surahs = ref.read(surahsProvider).valueOrNull;

  BottomSheetHelper.showStandard<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                'Охирин боздид',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxListHeight),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                ),
                itemBuilder: (context, i) {
                  final e = items[i];
                  final prog = _quranSurahProgressLine(e, surahs) ?? 'Ояти ${e.verseNumber}';
                  final visited = _formatQuranLastReadVisited(e.visitedAtMillis);
                  final sub = visited != null ? '$prog · $visited' : prog;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 2),
                    leading: Icon(Icons.history_rounded, color: cs.primary),
                    title: Text(
                      _quranSurahTitleLine(e, surahs),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: cs.onSurfaceVariant),
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      if (parentContext.mounted) {
                        await parentContext.push(
                            '/surah/${e.surahNumber}/verse/${e.verseNumber}');
                        if (parentContext.mounted) {
                          await ShareRateDialog.showIfNeeded(parentContext);
                        }
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}



class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  void _navigateToSurah(int surahNumber) {
    if (surahNumber >= 1 && surahNumber <= 114) {
      context.go('/surah/$surahNumber');
    }
  }

  void _navigateToVerse(int surahNumber, int verseNumber) {
    if (surahNumber >= 1 && surahNumber <= 114 && verseNumber >= 1) {
      context.go('/surah/$surahNumber/verse/$verseNumber');
    }
  }

  void _showNavigationDialog(BuildContext context) {
    // Navigate to navigation page
    context.push('/navigation');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          // Exit app or do nothing on home root back button
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Root home screen has no back button
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Қуръони Карим',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Тафсири Осонбаён',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: Transform.rotate(
                angle: 0.5,
                child: const Icon(Icons.navigation),
              ),
              onPressed: () => context.push('/search?filter=navigation'),
              tooltip: 'Навигатор',
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => context.push('/search'),
              tooltip: 'Ҷустуҷӯ',
            ),
          ],
        ),
        body: const SafeArea(
          top: false, // AppBar handles top
          bottom: true,
          child: _SurahsTab(),
        ),
        bottomNavigationBar: const BottomNavigationBarWidget(),
      ),
    );
  }
}

class _SurahsTab extends ConsumerStatefulWidget {
  const _SurahsTab();

  @override
  ConsumerState<_SurahsTab> createState() => _SurahsTabState();
}

// JuzInfo and PageInfo moved to their respective widget files

class _SurahsTabState extends ConsumerState<_SurahsTab>
    with SingleTickerProviderStateMixin {
  bool _isAscending = true; // true = 1-114, false = 114-1
  late TabController _tabController;

  List<JuzInfo>? _juzList;
  List<PageInfo>? _pageList;
  bool _isLoadingJuzPage = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Update UI when tab changes
    });
    _loadJuzPageData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadJuzPageData() async {
    if (_isLoadingJuzPage) return;

    setState(() {
      _isLoadingJuzPage = true;
    });

    try {
      final metadata = await ref.read(quranMetadataProvider.future);

      setState(() {
        _juzList = metadata.juzList;
        _pageList = metadata.pageList;
        _isLoadingJuzPage = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingJuzPage = false;
      });
      debugPrint('Error loading juz/page data: $e');
    }
  }

  List<SurahModel> _sortSurahs(List<SurahModel> surahs) {
    final sorted = List<SurahModel>.from(surahs);
    sorted.sort((a, b) => _isAscending
        ? a.number.compareTo(b.number)
        : b.number.compareTo(a.number));
    return sorted;
  }



  Widget _buildSurahsList(AsyncValue<List<SurahModel>> surahsAsync) {
    return surahsAsync.when(
      data: (surahs) {
        if (surahs.isEmpty) {
          return const EmptyStateWidget(
            title: 'Қуръон ёфт нашуд',
            message:
                'Дар ҳоли ҳозир ҳеҷ сурае дар барнома нест. Лутфан пас аз чанд лаҳза такрор кӯшиш кунед.',
            icon: Icons.menu_book,
          );
        }

        final sortedSurahs = _sortSurahs(surahs);

        return ListView.builder(
          itemCount: sortedSurahs.length,
          cacheExtent: 1000,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          itemBuilder: (context, index) {
            final surah = sortedSurahs[index];
            return SurahListItem(
              key: ValueKey(surah.number),
              surah: surah,
              onTap: () async {
                await context.push('/surah/${surah.number}');
                if (context.mounted) {
                  await ShareRateDialog.showIfNeeded(context);
                }
              },
            );
          },
        );
      },
      loading: () => LoadingFullScreenWidget(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        itemCount: 10,
        itemHeight: 68,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        borderRadius: BorderRadius.circular(12),
      ),
      error: (error, stackTrace) => CustomErrorWidget(
        title: 'Хатоги дар боргирӣ',
        message:
            'Қуръонро наметавонем боргирӣ кунем. Лутфан пас аз чанд лаҳза такрор кӯшиш кунед.',
        onRetry: () {
          ref.invalidate(surahsProvider);
        },
      ),
    );
  }

  Widget _buildJuzList() {
    if (_isLoadingJuzPage || _juzList == null) {
      return LoadingFullScreenWidget(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        itemCount: 10,
        itemHeight: 68,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        borderRadius: BorderRadius.circular(12),
      );
    }

    if (_juzList!.isEmpty) {
      return const EmptyStateWidget(
        title: 'Ҷузъҳо ёфт нашуд',
        message: 'Маълумоти ҷузъҳо дастрас нест.',
        icon: Icons.book,
      );
    }

    final displayList =
        _isAscending ? _juzList! : List<JuzInfo>.from(_juzList!.reversed);

    return ListView.builder(
      itemCount: displayList.length,
      cacheExtent: 1000,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        final juzInfo = displayList[index];
        return JuzListItem(
          key: ValueKey(juzInfo.juz),
          juzInfo: juzInfo,
          onTap: () async {
            await context.push(
                '/surah/${juzInfo.surahNumber}/verse/${juzInfo.ayahNumber}');
            if (context.mounted) {
              await ShareRateDialog.showIfNeeded(context);
            }
          },
        );
      },
    );
  }

  Widget _buildPageList() {
    if (_isLoadingJuzPage || _pageList == null) {
      return LoadingFullScreenWidget(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        itemCount: 10,
        itemHeight: 68,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        borderRadius: BorderRadius.circular(12),
      );
    }

    if (_pageList!.isEmpty) {
      return const EmptyStateWidget(
        title: 'Саҳифаҳо ёфт нашуд',
        message: 'Маълумоти саҳифаҳо дастрас нест.',
        icon: Icons.description,
      );
    }

    final displayList =
        _isAscending ? _pageList! : List<PageInfo>.from(_pageList!.reversed);

    return ListView.builder(
      itemCount: displayList.length,
      cacheExtent: 1000,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        final pageInfo = displayList[index];
        return PageListItem(
          key: ValueKey(pageInfo.page),
          pageInfo: pageInfo,
          onTap: () async {
            if (AppConstants.enableMushafModule) {
              await context.push('/mushaf?page=${pageInfo.page}');
            } else {
              await context.push('/surah/${pageInfo.surahNumber}/verse/${pageInfo.ayahNumber}');
            }
            if (context.mounted) {
              await ShareRateDialog.showIfNeeded(context);
            }
          },
        );
      },
    );
  }

  Widget _buildLastReadHeroCard(
      BuildContext context, List<QuranLastReadEntry> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final surahs = ref.watch(surahsProvider).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Охирин боздид',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              if (items.length > 1)
                InkWell(
                  onTap: () => _showQuranLastReadSheet(context, ref, items),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Ҳама (${items.length})',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Builder(
          builder: (context) {
            final entry = items.first;
            final title = _quranSurahTitleLine(entry, surahs);
            final progressStr = _quranSurahProgressLine(entry, surahs);

            double progressPct = 0.0;
            if (entry.surahAyahCount != null && entry.surahAyahCount! > 0) {
              progressPct =
                  (entry.verseNumber / entry.surahAyahCount!).clamp(0.0, 1.0);
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            colorScheme.primaryContainer.withValues(alpha: 0.5),
                            colorScheme.surfaceContainerHighest,
                          ]
                        : [
                            colorScheme.primaryContainer.withValues(alpha: 0.35),
                            colorScheme.primaryContainer.withValues(alpha: 0.12),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => context.push(
                      '/surah/${entry.surahNumber}/verse/${entry.verseNumber}'),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    progressStr ?? 'Ояти ${entry.verseNumber}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => context.push(
                                  '/surah/${entry.surahNumber}/verse/${entry.verseNumber}'),
                              icon: const Icon(Icons.play_arrow_rounded, size: 16),
                              label: const Text('Идома', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                        if (progressPct > 0) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progressPct,
                              minHeight: 3.5,
                              backgroundColor:
                                  colorScheme.primary.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.primary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final surahsAsync = ref.watch(surahsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final lastReadItems = ref.watch(quranLastReadListProvider).valueOrNull ??
        <QuranLastReadEntry>[];

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          if (lastReadItems.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildLastReadHeroCard(context, lastReadItems),
            ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Сура'),
                  Tab(text: 'Ҷузъ'),
                  Tab(text: 'Саҳифа'),
                ],
                labelColor: colorScheme.primary,
                unselectedLabelColor:
                    colorScheme.onSurface.withValues(alpha: 0.6),
                indicatorColor: colorScheme.primary,
                dividerColor: colorScheme.outline.withValues(alpha: 0.2),
                tabAlignment: TabAlignment.fill,
              ),
              theme.scaffoldBackgroundColor,
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          // Surah tab
          _buildSurahsList(surahsAsync),
          // Juz tab
          _buildJuzList(),
          // Page tab
          _buildPageList(),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this.tabBar, this.backgroundColor);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
