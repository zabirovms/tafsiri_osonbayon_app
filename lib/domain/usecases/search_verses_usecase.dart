import '../repositories/quran_repository.dart';
import '../../data/models/verse_model.dart';

class SearchVersesUseCase {
  final QuranRepository _repository;

  SearchVersesUseCase(this._repository);

  Future<List<VerseModel>> call(
    String query, {
    String language = 'both',
    int? surahId,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    if (query.trim().length < 2) {
      throw Exception('Search query must be at least 2 characters long');
    }

    return await _repository.searchVerses(
      query.trim(),
      language: language,
      surahId: surahId,
    );
  }
}
