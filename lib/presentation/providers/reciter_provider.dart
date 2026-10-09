import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/reciter_model.dart';
import '../../data/services/audio_manifest_service_v2.dart';
import 'audio_editions_provider.dart' show apiRecitersProvider;

// Provider for available reciters - fetches from manifest (ALL from CDN)
// Directly use apiRecitersProvider
final recitersProvider = apiRecitersProvider;

/// Hardcoded mapping of verse-by-verse reciter IDs to ReciterModel
/// Created directly from verified URLs - no manifest dependency
/// Uses CDN IDs directly (no appId conversion)
const Map<String, ReciterModel> _verseByVerseRecitersMap = {
  // 128 kbps
  'ar.ahmedajamy': ReciterModel(
    id: 'ar.ahmedajamy',
    name: 'Ahmed Al-Ajamy',
    nameTajik: 'Аҳмад Ал-Аҷамӣ',
    nameArabic: 'أحمد العجمي',
  ),
  'ar.alafasy': ReciterModel(
    id: 'ar.alafasy',
    name: 'Mishary Alafasy',
    nameTajik: 'Мишарӣ Ал-Афосӣ',
    nameArabic: 'مشاري العفاسي',
  ),
  'ar.hudhaify': ReciterModel(
    id: 'ar.hudhaify',
    name: 'Ali Abdur-Rahman Al-Huthaifi',
    nameTajik: 'Алӣ Абдур Раҳмон Ал-Ҳусайфӣ',
    nameArabic: 'علي عبد الرحمن الحذيفي',
  ),
  'ar.husary': ReciterModel(
    id: 'ar.husary',
    name: 'Mahmoud Khalil Al-Husary',
    nameTajik: 'Маҳмуд Халил Ал-Ҳусарӣ',
    nameArabic: 'محمود خليل الحصري',
  ),
  'ar.husarymujawwad': ReciterModel(
    id: 'ar.husarymujawwad',
    name: 'Mahmoud Khalil Al-Husary (Mujawwad)',
    nameTajik: 'Маҳмуд Халил Ал-Ҳусарӣ (Муҷаввад)',
    nameArabic: 'محمود خليل الحصري مجود',
  ),
  'ar.mahermuaiqly': ReciterModel(
    id: 'ar.mahermuaiqly',
    name: 'Maher Al Muaiqly',
    nameTajik: 'Маҳер Ал-Муайқлӣ',
    nameArabic: 'ماهر المعيقلي',
  ),
  'ar.minshawi': ReciterModel(
    id: 'ar.minshawi',
    name: 'Muhammad Siddiq Al-Minshawi',
    nameTajik: 'Муҳаммад Сиддиқ Ал-Миншавӣ',
    nameArabic: 'محمد صديق المنشاوي',
  ),
  'ar.muhammadayyoub': ReciterModel(
    id: 'ar.muhammadayyoub',
    name: 'Muhammad Ayyub',
    nameTajik: 'Муҳаммад Айюб',
    nameArabic: 'محمد أيوب',
  ),
  'ar.muhammadjibreel': ReciterModel(
    id: 'ar.muhammadjibreel',
    name: 'Muhammad Jibreel',
    nameTajik: 'Муҳаммад Ҷибрил',
    nameArabic: 'محمد جبريل',
  ),
  'ar.shaatree': ReciterModel(
    id: 'ar.shaatree',
    name: 'Abu Bakr Ash-Shatri',
    nameTajik: 'Абӯ Бакр Аш-Шатри',
    nameArabic: 'أبو بكر الشاطري',
  ),
  // 192 kbps
  'ar.abdulbasitmurattal': ReciterModel(
    id: 'ar.abdulbasitmurattal',
    name: 'Abdul Basit Murattal',
    nameTajik: 'Абдул Босити Мураттал',
    nameArabic: 'عبد الباسط مرتل',
  ),
  'ar.abdullahbasfar': ReciterModel(
    id: 'ar.abdullahbasfar',
    name: 'Abdullah Basfar',
    nameTajik: 'Абдуллоҳ Басфар',
    nameArabic: 'عبد الله بصفر',
  ),
  'ar.abdurrahmaansudais': ReciterModel(
    id: 'ar.abdurrahmaansudais',
    name: 'Abdur-Rahman As-Sudais',
    nameTajik: 'Абдур Раҳмон Ас-Судайс',
    nameArabic: 'عبد الرحمن السديس',
  ),
  'ar.hanirifai': ReciterModel(
    id: 'ar.hanirifai',
    name: 'Hani Al-Refai (Hajjaj)',
    nameTajik: 'Ҳонӣ Ал-Рефаӣ (Ҳаҷҷоҷ)',
    nameArabic: 'هاني الرفاعي',
  ),
  // 32 kbps
  'ar.ibrahimakhbar': ReciterModel(
    id: 'ar.ibrahimakhbar',
    name: 'Ibrahim Al-Akhbar',
    nameTajik: 'Иброҳим Ал-Ахбар',
    nameArabic: 'إبراهيم الأخضر',
  ),
  // 64 kbps
  'ar.abdulsamad': ReciterModel(
    id: 'ar.abdulsamad',
    name: 'Abdul Samad',
    nameTajik: 'Абдул Самад',
    nameArabic: 'عبد الصمد',
  ),
  'ar.aymanswoaid': ReciterModel(
    id: 'ar.aymanswoaid',
    name: 'Ayman Swoaid',
    nameTajik: 'Айман Своид',
    nameArabic: 'أيمن سويد',
  ),
  'ar.minshawimujawwad': ReciterModel(
    id: 'ar.minshawimujawwad',
    name: 'Muhammad Siddiq Al-Minshawi (Mujawwad)',
    nameTajik: 'Муҳаммад Сиддиқ Ал-Миншавӣ (Муҷаввад)',
    nameArabic: 'محمد صديق المنشاوي مجود',
  ),
  'ar.saoodshuraym': ReciterModel(
    id: 'ar.saoodshuraym',
    name: 'Saood Bin Ibrahim Shuraym',
    nameTajik: 'Сауд Бин Иброҳим Шурайм',
    nameArabic: 'سعود بن إبراهيم الشريم',
  ),
  // Translations with verse-by-verse
  'fr.leclerc': ReciterModel(
    id: 'fr.leclerc',
    name: 'French Translation',
    nameTajik: 'Фаронсавӣ',
    nameArabic: 'فرنسي',
  ),
  'ru.kuliev-audio': ReciterModel(
    id: 'ru.kuliev-audio',
    name: 'Russian Translation',
    nameTajik: 'Русский',
    nameArabic: 'روسي',
  ),
  'zh.chinese': ReciterModel(
    id: 'zh.chinese',
    name: 'Chinese Translation',
    nameTajik: 'Чинӣ',
    nameArabic: 'صيني',
  ),
  'en.walk': ReciterModel(
    id: 'en.walk',
    name: 'English Translation',
    nameTajik: 'Англисӣ',
    nameArabic: 'إنجليزي',
  ),
  'fa.hedayatfarfooladvand': ReciterModel(
    id: 'fa.hedayatfarfooladvand',
    name: 'Persian Translation',
    nameTajik: 'Форсӣ',
    nameArabic: 'فارسي',
  ),
  'ur.khan': ReciterModel(
    id: 'ur.khan',
    name: 'Urdu Translation',
    nameTajik: 'Урду',
    nameArabic: 'أردو',
  ),
};

// Provider for reciters that support verse-by-verse audio (for settings)
// Uses centralized list from AudioManifestServiceV2
// TODO: Migrate to ReciterDataService when JSON files are fully populated
final recitersWithVerseByVerseProvider = Provider<List<ReciterModel>>((ref) {
  final verseByVerseIds = AudioManifestServiceV2.verseByVerseReciterIds;
  
  final reciters = verseByVerseIds
      .map((cdnId) => _verseByVerseRecitersMap[cdnId])
      .whereType<ReciterModel>()
      .toList();
  
  if (kDebugMode) {
    debugPrint('[ReciterProvider] Returning ${reciters.length} verse-by-verse reciters from centralized list');
    if (reciters.length != verseByVerseIds.length) {
      debugPrint('[ReciterProvider] WARNING: Some verse-by-verse reciters missing from map!');
      final missing = verseByVerseIds.where((id) => !_verseByVerseRecitersMap.containsKey(id)).toList();
      if (missing.isNotEmpty) {
        debugPrint('[ReciterProvider] Missing: ${missing.join(", ")}');
      }
    }
  }
  
  return reciters;
});

// Provider for a specific reciter by ID
// Uses JSON only - has all names, bitrates, and verse-by-verse info
// All IDs are CDN IDs (no underscores) - JSON is the single source of truth
final reciterProvider = Provider.family<ReciterModel?, String>((ref, reciterId) {
  // JSON is the single source of truth - has all names, bitrates, and verse-by-verse info
  final allRecitersAsync = ref.watch(recitersProvider);
  return allRecitersAsync.when(
    data: (reciters) {
      try {
        // Direct match - JSON uses CDN IDs (no underscores)
        return reciters.firstWhere((r) => r.id == reciterId);
      } catch (e) {
        return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

