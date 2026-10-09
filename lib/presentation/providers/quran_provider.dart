import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../data/datasources/remote/api_service.dart';
import '../../data/repositories/local_quran_repository.dart';
import '../../data/datasources/local/drift_surah_datasource.dart';
import '../../data/datasources/local/drift_verse_datasource.dart';
import '../../data/datasources/local/drift_search_datasource.dart';
import '../../data/datasources/local/bookmark_local_datasource.dart';
import '../../data/datasources/remote/alquran_cloud_api.dart';
import '../pages/surah/surah_controller.dart';
import '../../domain/repositories/quran_repository.dart';
import '../../domain/usecases/get_all_surahs_usecase.dart';
import '../../domain/usecases/get_surah_usecase.dart';
import '../../domain/usecases/get_verses_usecase.dart';
import '../../domain/usecases/search_verses_usecase.dart';
import '../../domain/usecases/bookmark_usecase.dart';
import '../../data/models/surah_model.dart';
import '../../data/models/quran_metadata_model.dart';
import '../../data/models/verse_model.dart';
import '../../core/constants/audio_constants.dart';

// Providers for dependencies
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final alquranCloudApiProvider = Provider<AlQuranCloudApi>((ref) => AlQuranCloudApi());

// Use the Drift data sources instead of the JSON ones
final surahLocalDataSourceProvider = Provider<DriftSurahDataSource>((ref) => ref.watch(driftSurahDataSourceProvider));

final verseLocalDataSourceProvider = Provider<DriftVerseDataSource>((ref) => ref.watch(driftVerseDataSourceProvider));

final searchLocalDataSourceProvider = Provider<DriftSearchDataSource>((ref) => ref.watch(driftSearchDataSourceProvider));

final bookmarkLocalDataSourceProvider = Provider<BookmarkLocalDataSource>((ref) => BookmarkLocalDataSource());

// Auto-dispose provider - cleans up when surah page is closed
// No longer loads data on creation - only loads word-by-word when needed
final surahControllerProvider = ChangeNotifierProvider.autoDispose.family<SurahController, int>((ref, surahNumber) {
  final api = ref.watch(apiServiceProvider);
  final aqc = ref.watch(alquranCloudApiProvider);
  final controller = SurahController(apiService: api, aqc: aqc);
  // Only set default audio edition - no data loading (optimized)
  controller.setAudioEdition(AudioConstants.defaultReciter);
  return controller;
});

final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  return LocalQuranRepository(
    surahLocalDataSource: ref.watch(surahLocalDataSourceProvider),
    verseLocalDataSource: ref.watch(verseLocalDataSourceProvider),
    searchLocalDataSource: ref.watch(searchLocalDataSourceProvider),
    bookmarkLocalDataSource: ref.watch(bookmarkLocalDataSourceProvider),
  );
});

// Use case providers
final getAllSurahsUseCaseProvider = Provider<GetAllSurahsUseCase>((ref) {
  return GetAllSurahsUseCase(ref.watch(quranRepositoryProvider));
});

final getSurahUseCaseProvider = Provider<GetSurahUseCase>((ref) {
  return GetSurahUseCase(ref.watch(quranRepositoryProvider));
});

final getVersesUseCaseProvider = Provider<GetVersesUseCase>((ref) {
  return GetVersesUseCase(ref.watch(quranRepositoryProvider));
});

final searchVersesUseCaseProvider = Provider<SearchVersesUseCase>((ref) {
  return SearchVersesUseCase(ref.watch(quranRepositoryProvider));
});

final bookmarkUseCaseProvider = Provider<BookmarkUseCase>((ref) {
  return BookmarkUseCase(ref.watch(quranRepositoryProvider));
});

// State providers
final surahsProvider = FutureProvider<List<SurahModel>>((ref) async {
  final useCase = ref.watch(getAllSurahsUseCaseProvider);
  return await useCase();
});

final quranMetadataProvider = FutureProvider<QuranMetadata>((ref) async {
  final dataSource = ref.watch(surahLocalDataSourceProvider);
  return await dataSource.getQuranMetadata();
});

final surahProvider = FutureProvider.family<SurahModel?, int>((ref, surahNumber) async {
  final useCase = ref.watch(getSurahUseCaseProvider);
  return await useCase(surahNumber);
});

final versesProvider = FutureProvider.family<List<VerseModel>, int>((ref, surahNumber) async {
  final useCase = ref.watch(getVersesUseCaseProvider);
  return await useCase(surahNumber);
});

final versesByPageProvider = FutureProvider.family<List<VerseModel>, int>((ref, pageNumber) async {
  final dataSource = ref.watch(driftVerseDataSourceProvider);
  return await dataSource.getVersesByPage(pageNumber);
});

final searchResultsProvider = StateNotifierProvider<SearchNotifier, AsyncValue<List<VerseModel>>>((ref) => SearchNotifier(ref.watch(searchVersesUseCaseProvider)));

// Old bookmark provider removed - use bookmark_provider.dart instead

// Connectivity status provider (true when online, false when offline)
final connectivityStatusProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  
  bool isConnected(dynamic res) {
    if (res is List) {
      return !res.contains(ConnectivityResult.none);
    }
    return res != ConnectivityResult.none;
  }

  // Emit initial status
  final initial = await connectivity.checkConnectivity();
  yield isConnected(initial);
  
  // Emit changes
  await for (final result in connectivity.onConnectivityChanged) {
    yield isConnected(result);
  }
});

// Search notifier
class SearchNotifier extends StateNotifier<AsyncValue<List<VerseModel>>> {
  final SearchVersesUseCase _searchUseCase;

  SearchNotifier(this._searchUseCase) : super(const AsyncValue.data([]));

  Future<void> search(String query, {String language = 'both', int? surahId}) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    
    try {
      final results = await _searchUseCase(query, language: language, surahId: surahId);
      state = AsyncValue.data(results);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void clearSearch() {
    state = const AsyncValue.data([]);
  }
}

// Legacy bookmark notifier removed - use bookmark_provider.dart instead
