import '../repositories/quran_repository.dart';
import '../../data/models/surah_model.dart';

class GetAllSurahsUseCase {
  final QuranRepository _repository;

  GetAllSurahsUseCase(this._repository);

  Future<List<SurahModel>> call() async {
    return await _repository.getAllSurahs();
  }
}
