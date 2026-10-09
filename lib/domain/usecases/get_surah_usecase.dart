import '../repositories/quran_repository.dart';
import '../../data/models/surah_model.dart';

class GetSurahUseCase {
  final QuranRepository _repository;

  GetSurahUseCase(this._repository);

  Future<SurahModel?> call(int surahNumber) async {
    return await _repository.getSurahDetails(surahNumber);
  }
}
