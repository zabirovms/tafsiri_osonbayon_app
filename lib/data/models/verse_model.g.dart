// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verse_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VerseModel _$VerseModelFromJson(Map<String, dynamic> json) => VerseModel(
      id: (json['id'] as num).toInt(),
      surahId: (json['surah_id'] as num).toInt(),
      verseNumber: (json['verse_number'] as num).toInt(),
      arabicText: json['arabic_text'] as String,
      ayatiText: json['ayati_text'] as String,
      transliteration: json['transliteration'] as String?,
      tafsir: json['tafsir'] as String?,
      alomuddinText: json['alomuddin_text'] as String?,
      pioneersText: json['pioneers_text'] as String?,
      khojamirovText: json['khojamirov_text'] as String?,
      farsi: json['farsi'] as String?,
      russianKulievText: json['russian_kuliev_text'] as String?,
      page: (json['page'] as num?)?.toInt(),
      juz: (json['juz'] as num?)?.toInt(),
      uniqueKey: json['unique_key'] as String,
    );

Map<String, dynamic> _$VerseModelToJson(VerseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'surah_id': instance.surahId,
      'verse_number': instance.verseNumber,
      'arabic_text': instance.arabicText,
      'ayati_text': instance.ayatiText,
      'transliteration': instance.transliteration,
      'tafsir': instance.tafsir,
      'alomuddin_text': instance.alomuddinText,
      'pioneers_text': instance.pioneersText,
      'khojamirov_text': instance.khojamirovText,
      'farsi': instance.farsi,
      'russian_kuliev_text': instance.russianKulievText,
      'page': instance.page,
      'juz': instance.juz,
      'unique_key': instance.uniqueKey,
    };
