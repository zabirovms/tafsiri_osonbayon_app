import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/drift_surah_datasource.dart';
import '../widgets/quran/page_list_item.dart';

/// Provides PageInfo for all Mushaf pages (1–604).
final quranPagesProvider = FutureProvider<List<PageInfo>>((ref) async {
  final surahDS = ref.watch(driftSurahDataSourceProvider);
  final markers = await surahDS.getPageMarkers();
  
  return markers.map((m) => PageInfo(
    page: m['page'] as int,
    surahNumber: m['surahNumber'] as int,
    surahName: m['surahName'] as String,
    ayahNumber: m['ayahNumber'] as int,
  )).toList();
});

