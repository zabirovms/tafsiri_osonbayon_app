import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'verse_model.g.dart';

@JsonSerializable()
class VerseModel extends Equatable {
  final int id;
  @JsonKey(name: 'surah_id')
  final int surahId;
  @JsonKey(name: 'verse_number')
  final int verseNumber;
  @JsonKey(name: 'arabic_text')
  final String arabicText;
  @JsonKey(name: 'ayati_text')
  final String ayatiText;
  final String? transliteration;
  final String? tafsir;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? tafsirRu;
  @JsonKey(name: 'alomuddin_text')
  final String? alomuddinText;
  @JsonKey(name: 'pioneers_text')
  final String? pioneersText;
  @JsonKey(name: 'khojamirov_text')
  final String? khojamirovText;
  final String? farsi;
  @JsonKey(name: 'russian_kuliev_text')
  final String? russianKulievText;
  final int? page;
  final int? juz;
  @JsonKey(name: 'unique_key')
  final String uniqueKey;

  const VerseModel({
    required this.id,
    required this.surahId,
    required this.verseNumber,
    required this.arabicText,
    required this.ayatiText,
    this.transliteration,
    this.tafsir,
    this.tafsirRu = null,
    this.alomuddinText,
    this.pioneersText,
    this.khojamirovText,
    this.farsi,
    this.russianKulievText,
    this.page,
    this.juz,
    required this.uniqueKey,
  });

  factory VerseModel.fromJson(Map<String, dynamic> json) =>
      _$VerseModelFromJson(json);

  Map<String, dynamic> toJson() => _$VerseModelToJson(this);

  VerseModel copyWith({
    int? id,
    int? surahId,
    int? verseNumber,
    String? arabicText,
    String? ayatiText,
    String? transliteration,
    String? tafsir,
    String? tafsirRu,
    String? alomuddinText,
    String? pioneersText,
    String? khojamirovText,
    String? farsi,
    String? russianKulievText,
    int? page,
    int? juz,
    String? uniqueKey,
  }) {
    return VerseModel(
      id: id ?? this.id,
      surahId: surahId ?? this.surahId,
      verseNumber: verseNumber ?? this.verseNumber,
      arabicText: arabicText ?? this.arabicText,
      ayatiText: ayatiText ?? this.ayatiText,
      transliteration: transliteration ?? this.transliteration,
      tafsir: tafsir ?? this.tafsir,
      tafsirRu: tafsirRu ?? this.tafsirRu,
      alomuddinText: alomuddinText ?? this.alomuddinText,
      pioneersText: pioneersText ?? this.pioneersText,
      khojamirovText: khojamirovText ?? this.khojamirovText,
      farsi: farsi ?? this.farsi,
      russianKulievText: russianKulievText ?? this.russianKulievText,
      page: page ?? this.page,
      juz: juz ?? this.juz,
      uniqueKey: uniqueKey ?? this.uniqueKey,
    );
  }

  // Helper method to get translation based on language
  String getTranslation(String language) {
    switch (language) {
      case 'tajik_ayati':
        return ayatiText;
      case 'tajik_alomuddin':
        return alomuddinText ?? ayatiText;
      case 'tajik_pioneers':
        return pioneersText ?? ayatiText;
      case 'tajik_khojamirov':
        return khojamirovText ?? ayatiText;
      case 'farsi':
        return farsi ?? '';
      case 'russian_kuliev':
        return russianKulievText ?? '';
      default:
        return ayatiText;
    }
  }

  @override
  List<Object?> get props => [
        id,
        surahId,
        verseNumber,
        arabicText,
        ayatiText,
        transliteration,
        tafsir,
        tafsirRu,
        alomuddinText,
        pioneersText,
        khojamirovText,
        farsi,
        russianKulievText,
        page,
        juz,
        uniqueKey,
      ];

  @override
  String toString() {
    return 'VerseModel(id: $id, surahId: $surahId, verseNumber: $verseNumber, arabicText: $arabicText, ayatiText: $ayatiText, transliteration: $transliteration, tafsir: $tafsir, tafsirRu: $tafsirRu, alomuddinText: $alomuddinText, pioneersText: $pioneersText, khojamirovText: $khojamirovText, farsi: $farsi, russianKulievText: $russianKulievText, page: $page, juz: $juz, uniqueKey: $uniqueKey)';
  }
}
