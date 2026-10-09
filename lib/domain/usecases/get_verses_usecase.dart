import '../repositories/quran_repository.dart';
import '../../data/models/verse_model.dart';

class GetVersesUseCase {
  final QuranRepository _repository;

  GetVersesUseCase(this._repository);

  Future<List<VerseModel>> call(int surahNumber) async {
    return await _repository.getVersesBySurah(surahNumber);
  }
}
