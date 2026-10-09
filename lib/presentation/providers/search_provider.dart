import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/surah_model.dart';
import '../../data/models/search_result_model.dart';
import '../../data/datasources/local/drift_search_datasource.dart';
import '../../core/platform/service_registry.dart';
import '../../core/utils/search_query_parser.dart';

// Direct navigation result
class DirectNavigation {
  final String type; // 'surah', 'verse', 'juz', 'page'
  final String label;
  final String href;
  final int? surahNumber;
  final int? verseNumber;
  final int? juzNumber;
  final int? pageNumber;

  DirectNavigation({
    required this.type,
    required this.label,
    required this.href,
    this.surahNumber,
    this.verseNumber,
    this.juzNumber,
    this.pageNumber,
  });
}

// Search state
class SearchState {
  final String query;
  final List<SearchResult> results;
  final bool isLoading;
  final String? error;
  final List<String> suggestions;
  final String selectedFilter;
  final int? selectedSurahId;
  final DirectNavigation? directNavigation;

  final int totalResultsCount;
  final bool hasMoreResults;
  final int currentOffset;
  final bool isLoadingMore;

  SearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.suggestions = const [],
    this.selectedFilter = 'both',
    this.selectedSurahId,
    this.directNavigation,
    this.totalResultsCount = 0,
    this.hasMoreResults = false,
    this.currentOffset = 0,
    this.isLoadingMore = false,
  });

  SearchState copyWith({
    String? query,
    List<SearchResult>? results,
    bool? isLoading,
    String? error,
    List<String>? suggestions,
    String? selectedFilter,
    int? selectedSurahId,
    DirectNavigation? directNavigation,
    int? totalResultsCount,
    bool? hasMoreResults,
    int? currentOffset,
    bool? isLoadingMore,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      suggestions: suggestions ?? this.suggestions,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      selectedSurahId: selectedSurahId ?? this.selectedSurahId,
      directNavigation: directNavigation ?? this.directNavigation,
      totalResultsCount: totalResultsCount ?? this.totalResultsCount,
      hasMoreResults: hasMoreResults ?? this.hasMoreResults,
      currentOffset: currentOffset ?? this.currentOffset,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

// Enhanced search notifier with instant search
// Enhanced search notifier with instant search
class SearchNotifier extends StateNotifier<SearchState> {
  final DriftSearchDataSource _searchDataSource;
  Timer? _debounceTimer;
  Timer? _suggestionTimer;

  SearchNotifier(this._searchDataSource)
      : super(SearchState());

  Future<DirectNavigation?> _parseDirectNavigation(
      String query, List<SurahModel>? surahs) async {
    if (surahs == null || surahs.isEmpty) return null;
    final parsed = SearchQueryParser.parseQuery(query, surahs);

    if (parsed.type == SearchQueryType.text) return null;

    if (parsed.type == SearchQueryType.surah) {
      final surah = surahs.firstWhere((s) => s.number == parsed.surahNumber);
      return DirectNavigation(
        type: 'surah',
        label: 'Сураи ${surah.nameTajik}',
        href: '/surah/${surah.number}',
        surahNumber: surah.number,
      );
    } else if (parsed.type == SearchQueryType.verse) {
      final surah = surahs.firstWhere((s) => s.number == parsed.surahNumber);
      return DirectNavigation(
        type: 'verse',
        label: 'Сураи ${surah.nameTajik}, Ояти ${parsed.verseNumber}',
        href: '/surah/${surah.number}/verse/${parsed.verseNumber}',
        surahNumber: surah.number,
        verseNumber: parsed.verseNumber,
      );
    } else if (parsed.type == SearchQueryType.juz) {
      final loc =
          await _searchDataSource.getFirstVerseLocationOfJuz(parsed.juzNumber!);
      if (loc != null) {
        return DirectNavigation(
          type: 'juz',
          label: 'Ҷузъи ${parsed.juzNumber}',
          href: '/surah/${loc['surah_id']}/verse/${loc['verse_id']}',
          juzNumber: parsed.juzNumber,
        );
      }
    } else if (parsed.type == SearchQueryType.page) {
      final loc = await _searchDataSource
          .getFirstVerseLocationOfPage(parsed.pageNumber!);
      if (loc != null) {
        return DirectNavigation(
          type: 'page',
          label: 'Саҳифаи ${parsed.pageNumber}',
          href: '/surah/${loc['surah_id']}/verse/${loc['verse_id']}',
          pageNumber: parsed.pageNumber,
        );
      }
    }
    return null;
  }

  // Debounced search with instant results and pattern matching
  void search(String query, {List<SurahModel>? surahs}) {
    // Cancel previous timers
    _debounceTimer?.cancel();
    _suggestionTimer?.cancel();

    // Update query immediately for UI responsiveness
    state = state.copyWith(query: query, directNavigation: null);

    if (query.trim().isEmpty) {
      state = state.copyWith(
        results: [],
        suggestions: [],
        isLoading: false,
        error: null,
        directNavigation: null,
      );
      return;
    }

    // Show loading state
    state =
        state.copyWith(isLoading: true, error: null, directNavigation: null);

    // Debounce search to avoid too many requests
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        // Parse direct navigation
        final directNav = await _parseDirectNavigation(query, surahs);

        // If we are in "navigation" tab, we ONLY show navigation results. Skip text search.
        if (state.selectedFilter == 'navigation') {
          final List<SearchResult> surahResults = [];
          if (surahs != null && surahs.isNotEmpty) {
            surahResults.addAll(await _searchDataSource
                .searchSurahs(surahs, query, language: 'both'));
          }

          state = state.copyWith(
            results: surahResults,
            isLoading: false,
            error: null,
            directNavigation: directNav,
            totalResultsCount: surahResults.length,
            hasMoreResults: false,
            currentOffset: 0,
          );
          return;
        }

        // Always perform text search, even if direct navigation is set
        // Save only the searched term (not results)
        await _searchDataSource.saveSearchedTerm(query.trim());

        final List<SearchResult> allResults = [];

        // Get total count of verses
        int totalVerses = await _searchDataSource.countSearchVerses(
          query,
          language: state.selectedFilter,
          surahId: state.selectedSurahId,
        );

        // Search verses with matched fields
        final verseResults = await _searchDataSource.searchVersesWithFields(
          query,
          language: state.selectedFilter,
          surahId: state.selectedSurahId,
          limit: 30,
          offset: 0,
        );
        allResults.addAll(verseResults);

        // Sort results by relevance
        allResults.sort((a, b) => b.relevance.compareTo(a.relevance));

        state = state.copyWith(
          results: allResults,
          isLoading: false,
          error: null,
          directNavigation: directNav,
          totalResultsCount: totalVerses,
          hasMoreResults: verseResults.length == 30,
          currentOffset: 0,
        );
        // Log only meaningful searches (query length >= 2) to avoid noise from single-keystroke debounces
        if (query.trim().length >= 2) {
          ServiceRegistry().analyticsService.logSearch('quran', resultCount: allResults.length);
        }
      } catch (e) {
        state = state.copyWith(
          results: [],
          isLoading: false,
          error: e.toString(),
          directNavigation: null,
        );
      }
    });

    // Get suggestions with a shorter delay
    _suggestionTimer = Timer(const Duration(milliseconds: 150), () async {
      try {
        final suggestions = await _searchDataSource.getSearchSuggestions(query);
        state = state.copyWith(suggestions: suggestions);
      } catch (e) {
        // Don't update state for suggestion errors
      }
    });
  }

  // Instant search without debouncing (for real-time search)
  void searchInstant(String query, {List<SurahModel>? surahs}) {
    _debounceTimer?.cancel();
    _suggestionTimer?.cancel();

    state = state.copyWith(query: query, directNavigation: null);

    if (query.trim().isEmpty) {
      state = state.copyWith(
        results: [],
        suggestions: [],
        isLoading: false,
        error: null,
        directNavigation: null,
      );
      return;
    }

    // Perform instant search
    _performSearchInstant(query, surahs: surahs);
  }

  Future<void> _performSearchInstant(String query,
      {List<SurahModel>? surahs}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final directNav = await _parseDirectNavigation(query, surahs);

      // If we are in "navigation" tab, we ONLY show navigation results. Skip text search.
      if (state.selectedFilter == 'navigation') {
        final List<SearchResult> surahResults = [];
        if (surahs != null && surahs.isNotEmpty) {
          surahResults.addAll(await _searchDataSource
              .searchSurahs(surahs, query, language: 'both'));
        }

        state = state.copyWith(
          results: surahResults,
          totalResultsCount: surahResults.length,
          hasMoreResults: false,
          currentOffset: 0,
          isLoading: false,
          error: null,
          directNavigation: directNav,
        );
        return;
      }

      // If no direct navigation, perform text search
      if (state.directNavigation == null) {
        final List<SearchResult> allResults = [];

        int totalVerses = await _searchDataSource.countSearchVerses(
          query,
          language: state.selectedFilter,
          surahId: state.selectedSurahId,
        );

        // Search verses with matched fields
        final verseResults = await _searchDataSource.searchVersesWithFields(
          query,
          language: state.selectedFilter,
          surahId: state.selectedSurahId,
          limit: 30,
          offset: 0,
        );
        allResults.addAll(verseResults);

        // Sort results by relevance
        allResults.sort((a, b) => b.relevance.compareTo(a.relevance));

        state = state.copyWith(
          results: allResults,
          isLoading: false,
          error: null,
          totalResultsCount: totalVerses,
          hasMoreResults: verseResults.length == 30,
          currentOffset: 0,
        );
      }
    } catch (e) {
      state = state.copyWith(
        results: [],
        isLoading: false,
        error: e.toString(),
        directNavigation: null,
      );
    }
  }

  // Load more results for pagination
  Future<void> loadMoreResults() async {
    if (state.isLoadingMore || !state.hasMoreResults || state.query.isEmpty) {
      return;
    }

    try {
      state = state.copyWith(isLoadingMore: true);

      final nextOffset = state.currentOffset + 30;

      final verseResults = await _searchDataSource.searchVersesWithFields(
        state.query,
        language: state.selectedFilter,
        surahId: state.selectedSurahId,
        limit: 30,
        offset: nextOffset,
      );

      // We do not re-sort the entire list because BM25 ranking is already sorted by the DB
      // and we want to append the next 30 results smoothly to the end.
      final newResults = List<SearchResult>.from(state.results)
        ..addAll(verseResults);

      state = state.copyWith(
        results: newResults,
        isLoadingMore: false,
        currentOffset: nextOffset,
        hasMoreResults: verseResults.length == 30,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  // Update search filter
  void updateFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);

    // Re-search with new filter if there's a query
    if (state.query.isNotEmpty) {
      search(state.query, surahs: null);
    }
  }

  // Update surah filter
  void updateSurahFilter(int? surahId) {
    state = state.copyWith(selectedSurahId: surahId);

    // Re-search with new surah filter if there's a query
    if (state.query.isNotEmpty) {
      search(state.query, surahs: null);
    }
  }

  // Clear search
  void clearSearch() {
    _debounceTimer?.cancel();
    _suggestionTimer?.cancel();

    state = SearchState();
  }

  // Get recent navigations
  Future<List<Map<String, String>>> getRecentNavigations() async {
    return await _searchDataSource.getRecentNavigations();
  }

  // Save recent navigation
  Future<void> saveRecentNavigation({
    required String label,
    required String href,
    required String type,
  }) async {
    await _searchDataSource.saveRecentNavigation(
      label: label,
      href: href,
      type: type,
    );
  }

  // Select suggestion
  void selectSuggestion(String suggestion) {
    search(suggestion);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _suggestionTimer?.cancel();
    super.dispose();
  }
}

// Provider for search notifier (autoDispose to avoid persisting results when leaving the page)
final searchNotifierProvider =
    StateNotifierProvider.autoDispose<SearchNotifier, SearchState>((ref) {
  final searchDataSource = ref.watch(driftSearchDataSourceProvider);
  return SearchNotifier(searchDataSource);
});

// Provider for search suggestions
final searchSuggestionsProvider =
    FutureProvider.family<List<String>, String>((ref, query) async {
  final searchDataSource = ref.watch(driftSearchDataSourceProvider);
  return await searchDataSource.getSearchSuggestions(query);
});
