import 'package:equatable/equatable.dart';
import 'surah_model.dart';
import '../../presentation/widgets/quran/juz_list_item.dart' show JuzInfo;
import '../../presentation/widgets/quran/page_list_item.dart' show PageInfo;

class QuranMetadata extends Equatable {
  final List<SurahModel> surahs;
  final List<JuzInfo> juzList;
  final List<PageInfo> pageList;

  const QuranMetadata({
    required this.surahs,
    required this.juzList,
    required this.pageList,
  });

  factory QuranMetadata.fromJson(Map<String, dynamic> json) {
    final surahsJson = json['surahs'] as List;
    final juzJson = json['juz_list'] as List;
    final pageJson = json['page_list'] as List;

    final surahs = surahsJson.map((s) => SurahModel(
      id: s['number'],
      number: s['number'],
      nameArabic: s['name_arabic'],
      nameTajik: s['name_tajik'],
      nameEnglish: '',
      revelationType: s['revelation_type'],
      versesCount: s['verses_count'],
      startJuz: s['start_juz'],
      endJuz: s['end_juz'],
      startPage: s['start_page'],
      endPage: s['end_page'],
    )).toList();

    final juzList = juzJson.map((j) => JuzInfo(
      juz: j['juz'],
      surahNumber: j['surah'],
      surahName: j['surah_name_tajik'],
      ayahNumber: j['verse'],
    )).toList();

    final pageList = pageJson.map((p) => PageInfo(
      page: p['page'],
      surahNumber: p['surah'],
      surahName: p['surah_name_tajik'],
      ayahNumber: p['verse'],
    )).toList();

    return QuranMetadata(
      surahs: surahs,
      juzList: juzList,
      pageList: pageList,
    );
  }

  @override
  List<Object?> get props => [surahs, juzList, pageList];
}
