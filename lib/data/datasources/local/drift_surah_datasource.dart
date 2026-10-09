import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../models/surah_model.dart';
import '../../models/quran_metadata_model.dart';
import '../../providers/quran_database_provider.dart';
import 'drift/database.dart';
import '../../../presentation/widgets/quran/juz_list_item.dart' show JuzInfo;
import '../../../presentation/widgets/quran/page_list_item.dart' show PageInfo;

final driftSurahDataSourceProvider = Provider<DriftSurahDataSource>((ref) {
  final db = ref.watch(quranDatabaseProvider);
  return DriftSurahDataSource(db);
});

class DriftSurahDataSource {
  final AppDatabase _db;

  DriftSurahDataSource(this._db);

  /// Load Quran metadata (Surahs, Juz, Pages) directly from SQLite
  Future<QuranMetadata> getQuranMetadata() async {
    // 1. Get all surahs
    final surahsQuery = await _db.select(_db.surahMetadata).get();
    
    // 2. Get min/max page and juz for each surah
    final surahBoundsQuery = await _db.customSelect('''
      SELECT surah_id, 
             min(juz) as start_juz, max(juz) as end_juz,
             min(page) as start_page, max(page) as end_page
      FROM verses
      GROUP BY surah_id
    ''').get();
    
    final boundsMap = <int, Map<String, int>>{};
    for (final row in surahBoundsQuery) {
      boundsMap[row.read<int>('surah_id')] = {
        'start_juz': row.read<int>('start_juz'),
        'end_juz': row.read<int>('end_juz'),
        'start_page': row.read<int>('start_page'),
        'end_page': row.read<int>('end_page'),
      };
    }

    final surahs = surahsQuery.map((m) {
      final bounds = boundsMap[m.number];
      return SurahModel(
        id: m.number,
        number: m.number,
        nameArabic: m.nameArabic ?? '',
        nameTajik: m.nameTajik ?? '',
        nameEnglish: '',
        revelationType: m.revelationType ?? '',
        versesCount: m.versesCount ?? 0,
        startJuz: bounds?['start_juz'] ?? 0,
        endJuz: bounds?['end_juz'] ?? 0,
        startPage: bounds?['start_page'] ?? 0,
        endPage: bounds?['end_page'] ?? 0,
        description: m.description,
      );
    }).toList();

    // 3. Get Juz markers
    final juzQuery = await _db.customSelect('''
      SELECT v.juz, v.surah_id, s.name_tajik as nameTajik, s.name_arabic as nameArabic, min(v.verse_id) as min_verse
      FROM verses v
      JOIN surah_metadata s ON v.surah_id = s.number
      WHERE v.juz IS NOT NULL
      GROUP BY v.juz
      ORDER BY v.juz ASC
    ''').get();

    final juzList = juzQuery.map((row) {
      final surahNumber = row.read<int>('surah_id');
      final nameTajik = row.read<String?>('nameTajik');
      final nameArabic = row.read<String?>('nameArabic');
      return JuzInfo(
        juz: row.read<int>('juz'),
        surahNumber: surahNumber,
        surahName: nameTajik ?? nameArabic ?? 'Сураи $surahNumber',
        ayahNumber: row.read<int>('min_verse'),
      );
    }).toList();

    // 4. Get Page markers
    final pageQuery = await _db.customSelect('''
      SELECT v.page, v.surah_id, s.name_tajik as nameTajik, s.name_arabic as nameArabic, min(v.verse_id) as min_verse
      FROM verses v
      JOIN surah_metadata s ON v.surah_id = s.number
      WHERE v.page IS NOT NULL
      GROUP BY v.page
      ORDER BY v.page ASC
    ''').get();

    final pageList = pageQuery.map((row) {
      final surahNumber = row.read<int>('surah_id');
      final nameTajik = row.read<String?>('nameTajik');
      final nameArabic = row.read<String?>('nameArabic');
      return PageInfo(
        page: row.read<int>('page'),
        surahNumber: surahNumber,
        surahName: nameTajik ?? nameArabic ?? 'Сураи $surahNumber',
        ayahNumber: row.read<int>('min_verse'),
      );
    }).toList();

    return QuranMetadata(
      surahs: surahs,
      juzList: juzList,
      pageList: pageList,
    );
  }

  /// Load all surahs from local database
  Future<List<SurahModel>> getAllSurahs() async {
    final metadata = await getQuranMetadata();
    return metadata.surahs;
  }
  
  /// Get surah details (including description) by number
  Future<SurahModel?> getSurahDetails(int number) async {
    final surahs = await getAllSurahs();
    try {
      return surahs.firstWhere((s) => s.number == number);
    } catch (_) {
      return null;
    }
  }
  
  /// Get a specific surah by number
  Future<SurahModel?> getSurahByNumber(int number) async {
    return getSurahDetails(number);
  }

  /// Get the first verse of each page
  Future<List<Map<String, dynamic>>> getPageMarkers() async {
    final sql = '''
      SELECT v.page, v.surah_id, s.name_arabic as nameArabic, s.name_tajik as nameTajik, min(v.verse_id) as min_verse
      FROM verses v
      JOIN surah_metadata s ON v.surah_id = s.number
      WHERE v.page IS NOT NULL
      GROUP BY v.page
      ORDER BY v.page ASC
    ''';
    final results = await _db.customSelect(sql).get();
    
    return results.map((row) {
      final nameTajik = row.read<String?>('nameTajik');
      final nameArabic = row.read<String?>('nameArabic');
      final surahNumber = row.read<int>('surah_id');
      return {
        'page': row.read<int>('page'),
        'surahNumber': surahNumber,
        'surahName': nameTajik ?? nameArabic ?? 'Сураи $surahNumber',
        'ayahNumber': row.read<int>('min_verse'),
      };
    }).toList();
  }
}
