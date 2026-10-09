import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/highlighted_text.dart';
import '../../../shared/widgets/app_search_field.dart';
import '../../providers/search_provider.dart';
import '../../providers/quran_provider.dart';

import '../../../data/models/verse_model.dart';
import '../../../data/models/search_result_model.dart';
import 'widgets/unified_navigator.dart';

import '../../widgets/bottom_navigation_bar_widget.dart';

class SearchPage extends ConsumerStatefulWidget {
  final String? initialQuery;
  final String? initialFilter;
  final int? initialSurah;
  final int? initialVerse;

  const SearchPage({
    super.key,
    this.initialQuery,
    this.initialFilter,
    this.initialSurah,
    this.initialVerse,
  });

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isFocused = false;
  List<Map<String, String>> _recentNavigations = [];

  @override
  void initState() {
    super.initState();

    // Set initial query if provided
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
    }

    // Listen to focus changes
    _searchFocusNode.addListener(() {
      setState(() {
        _isFocused = _searchFocusNode.hasFocus;
      });
    });

    // Listen to scroll to load more results
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(searchNotifierProvider.notifier).loadMoreResults();
      }
    });

    // Focus on search field when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialFilter != 'navigation') {
        _searchFocusNode.requestFocus();
      }

      if (widget.initialFilter != null) {
        ref
            .read(searchNotifierProvider.notifier)
            .updateFilter(widget.initialFilter!);
      }

      // Perform initial search if query is provided
      if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
        _performSearch(widget.initialQuery!);
      }

      // Load recent navigations
      _loadRecentNavigations();
    });
  }

  Future<void> _loadRecentNavigations() async {
    final navigations =
        await ref.read(searchNotifierProvider.notifier).getRecentNavigations();
    if (mounted) {
      setState(() {
        _recentNavigations = navigations;
      });
    }
  }

  void _performSearch(String query) {
    final surahsAsync = ref.read(surahsProvider);
    surahsAsync.whenData((surahs) {
      // surahs is already List<SurahModel>
      ref.read(searchNotifierProvider.notifier).search(
            query,
            surahs: surahs,
          );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchNotifierProvider);
    final surahsAsync = ref.watch(surahsProvider);

    // Sync controller with search state
    if (_searchController.text != searchState.query) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_searchController.text != searchState.query) {
          _searchController.text = searchState.query;
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ҷустуҷӯ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        actions: const [],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Search input
            _buildSearchInput(searchState),

            // Filter chips
            if (searchState.query.isNotEmpty || _isFocused)
              _buildFilterChips(searchState),

            // Results or suggestions
            Expanded(
              child: _buildResults(searchState, surahsAsync),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavigationBarWidget(),
    );
  }

  Widget _buildSearchInput(SearchState searchState) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: AppSearchField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        hintText: searchState.selectedFilter == 'navigation'
            ? 'Рафтан ба...'
            : 'Ҷустуҷӯ дар Қуръон...',
        isLoading: searchState.isLoading,
        dynamicBorderRadius: true,
        unfocusOnTapOutside: false,
        onChanged: (value) {
          _performSearch(value);
        },
        onClear: () {
          ref.read(searchNotifierProvider.notifier).clearSearch();
        },
        onSubmitted: (value) {
          _performSearch(value);
        },
      ),
    );
  }

  Widget _buildFilterChips(SearchState searchState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              'Навигатор',
              'navigation',
              searchState.selectedFilter,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Ҳама',
              'both',
              searchState.selectedFilter,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Арабӣ',
              'arabic',
              searchState.selectedFilter,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Транслитератсия',
              'transliteration',
              searchState.selectedFilter,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Оятӣ',
              'tajik_ayati',
              searchState.selectedFilter,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Абуаломуддин',
              'tajik_alomuddin',
              searchState.selectedFilter,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Pioneers',
              'tajik_pioneers',
              searchState.selectedFilter,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Хоҷамиров',
              'tajik_khojamirov',
              searchState.selectedFilter,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Русӣ',
              'russian_kuliev',
              searchState.selectedFilter,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String selectedValue) {
    final isSelected = selectedValue == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      onSelected: (selected) {
        if (selected) {
          ref.read(searchNotifierProvider.notifier).updateFilter(value);
        }
      },
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  Widget _buildResults(
      SearchState searchState, AsyncValue<List<dynamic>> surahsAsync) {
    if (searchState.query.isEmpty) {
      return _buildEmptyState(searchState);
    }

    if (searchState.isLoading) {
      return LoadingFullScreenWidget(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      );
    }

    if (searchState.error != null) {
      return Center(
        child: CustomErrorWidget(
          title: 'Хатоги дар ҷустуҷӯ',
          message: searchState.error!,
          onRetry: () {
            _performSearch(searchState.query);
          },
        ),
      );
    }

    // Calculate if we have a direct nav to show
    final hasDirectNav = searchState.directNavigation != null &&
        searchState.selectedFilter == 'navigation';

    // Show "no results" only if there's no visible direct navigation and no results
    if (searchState.results.isEmpty &&
        !hasDirectNav &&
        searchState.query.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Натиҷае ёфт нашуд',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      );
    }

    final totalItems = (hasDirectNav ? 1 : 0) +
        searchState.results.length +
        (searchState.isLoadingMore ? 1 : 0);

    return Column(
      children: [
        // Results count
        if (searchState.totalResultsCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${searchState.totalResultsCount} натиҷа ёфт шуд',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),

        // Results list (includes direct navigation as first item)
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: totalItems,
            itemBuilder: (context, index) {
              // First item is direct navigation if available
              if (hasDirectNav && index == 0) {
                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child:
                      _buildDirectNavigationCard(searchState.directNavigation!),
                );
              }

              // Adjust index for results (subtract 1 if direct nav exists)
              final resultIndex = hasDirectNav ? index - 1 : index;

              // Show loading indicator at the bottom
              if (resultIndex == searchState.results.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final result = searchState.results[resultIndex];

              // Handle surah results
              if (result.type == SearchResultType.surah) {
                final surah = result.surah!;
                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: Card(
                    child: InkWell(
                      onTap: () {
                        context.push('/surah/${surah.number}');
                        // Save to recent navigations
                        ref
                            .read(searchNotifierProvider.notifier)
                            .getRecentNavigations()
                            .then((_) {
                          // Navigation saved in provider
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Text(
                              'Сураи ${surah.nameTajik}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              // Handle verse results
              if (result.type == SearchResultType.verse) {
                final verse = result.verse!;
                final matchedText =
                    _getMatchedText(verse, result.matchedFields);
                final matchedFieldLabel = result.matchedFields.isNotEmpty
                    ? _getMatchedFieldLabel(result.matchedFields[0])
                    : '';
                final isArabic = result.matchedFields.isNotEmpty &&
                    result.matchedFields[0] == 'arabicText';

                // Build minimal reference text
                final referenceText = '${verse.surahId}:${verse.verseNumber}';

                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: Card(
                    child: InkWell(
                      onTap: () {
                        context.push(
                            '/surah/${verse.surahId}/verse/${verse.verseNumber}');
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Surah and verse info with matched field label
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    referenceText,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.7),
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                                if (matchedFieldLabel.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      matchedFieldLabel,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.7),
                                          ),
                                    ),
                                  ),
                              ],
                            ),

                            // Matched text (prominently displayed)
                            if (matchedText.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Directionality(
                                textDirection: isArabic
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                child: HighlightedText(
                                  text: matchedText,
                                  highlight: searchState.query,
                                  style: TextStyle(
                                    fontFamily:
                                        isArabic ? 'Noto_Naskh_Arabic' : null,
                                    fontSize: isArabic ? 18 : 16,
                                    height: 1.5,
                                    color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color ??
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                  highlightStyle: TextStyle(
                                    fontFamily:
                                        isArabic ? 'Noto_Naskh_Arabic' : null,
                                    fontSize: isArabic ? 18 : 16,
                                    height: 1.5,
                                    backgroundColor:
                                        Colors.yellow.withValues(alpha: 0.3),
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color ??
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                  textDirection: isArabic
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDirectNavigationCard(DirectNavigation navigation) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final cardBg =
        colorScheme.primaryContainer.withOpacity(isDark ? 0.3 : 0.15);
    final borderColor = colorScheme.primary.withOpacity(0.3);
    final textColor = colorScheme.onSurface;
    final accentColor = colorScheme.primary;

    IconData destinationIcon;
    String typeLabel = '';

    switch (navigation.type) {
      case 'surah':
        destinationIcon = Icons.menu_book;
        typeLabel = 'Сура';
        break;
      case 'verse':
        destinationIcon = Icons.chrome_reader_mode;
        typeLabel = 'Оят';
        break;
      case 'juz':
        destinationIcon = Icons.auto_stories;
        typeLabel = 'Ҷузъ';
        break;
      case 'page':
        destinationIcon = Icons.find_in_page;
        typeLabel = 'Саҳифа';
        break;
      default:
        destinationIcon = Icons.explore;
        typeLabel = 'Гузариш';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Save to recent navigations
            ref.read(searchNotifierProvider.notifier).saveRecentNavigation(
                  label: navigation.label,
                  href: navigation.href,
                  type: navigation.type,
                );
            context.push(navigation.href);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon Badge on Left
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    destinationIcon,
                    color: accentColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),

                // Destination details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (navigation.type != 'surah') ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                typeLabel,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: accentColor,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        navigation.label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // Navigation Arrow / Action Button
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    color: colorScheme.onPrimary,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(SearchState searchState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // If not in navigation tab, just show standard prompt
    if (searchState.selectedFilter != 'navigation') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 72,
              color: colorScheme.primary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Ҷустуҷӯро оғоз кунед',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: UnifiedNavigator(
        initialSurah: widget.initialSurah,
        initialVerse: widget.initialVerse,
      ),
    );
  }

  // Get matched text based on matched fields
  String _getMatchedText(VerseModel verse, List<String> matchedFields) {
    if (matchedFields.isEmpty) return '';

    final matchedField = matchedFields[0];

    switch (matchedField) {
      case 'arabicText':
        return verse.arabicText;
      case 'transliteration':
        return verse.transliteration ?? '';
      case 'tajik_ayati':
        return verse.ayatiText;
      case 'tajik_alomuddin':
        return verse.alomuddinText ?? verse.ayatiText;
      case 'tajik_pioneers':
        return verse.pioneersText ?? verse.ayatiText;
      case 'tajik_khojamirov':
        return verse.khojamirovText ?? verse.ayatiText;
      case 'farsi':
        return verse.farsi ?? verse.ayatiText;
      case 'russian_kuliev':
        return verse.russianKulievText ?? verse.ayatiText;
      default:
        // Fallback: try to find any matching field
        if (matchedFields.contains('arabicText')) return verse.arabicText;
        if (matchedFields.contains('ayatiText')) return verse.ayatiText;
        if (matchedFields.contains('transliteration') &&
            verse.transliteration != null) {
          return verse.transliteration!;
        }
        return verse.ayatiText.isNotEmpty ? verse.ayatiText : verse.arabicText;
    }
  }

  // Get matched field label
  String _getMatchedFieldLabel(String matchedField) {
    switch (matchedField) {
      case 'arabicText':
      case 'arabic_text':
      case 'quran_arabic':
        return 'Арабӣ';
      case 'transliteration':
        return 'Транслит';
      case 'tajik_ayati':
      case 'tj_ayati':
        return 'Оятӣ';
      case 'tajik_alomuddin':
      case 'tj_alomuddin':
        return 'Абуаломуддин';
      case 'tajik_pioneers':
      case 'tj_pioneers':
        return 'Pioneers';
      case 'tajik_khojamirov':
      case 'tj_khojamirov':
        return 'Хоҷамиров';
      case 'farsi':
      case 'fa_translation':
        return 'Форсӣ';
      case 'russian_kuliev':
      case 'ru_kuliev':
        return 'Русӣ';
      case 'nameTajik':
      case 'nameArabic':
      case 'number':
        return 'Сура';
      default:
        if (matchedField.isEmpty) return '';
        // If it's a raw resource ID not in switch, capitalize it
        return matchedField[0].toUpperCase() +
            matchedField.substring(1).replaceAll('_', ' ');
    }
  }

  Widget _buildGuideChip(String text, String? query) {
    final theme = Theme.of(context);
    return ActionChip(
      label: Text(
        text,
        style: theme.textTheme.bodySmall,
      ),
      onPressed: query != null
          ? () {
              _searchController.text = query;
              ref
                  .read(searchNotifierProvider.notifier)
                  .updateFilter('navigation');
              _performSearch(query);
            }
          : null,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
    );
  }
}
