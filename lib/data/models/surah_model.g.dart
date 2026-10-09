// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'surah_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SurahModel _$SurahModelFromJson(Map<String, dynamic> json) => SurahModel(
      id: (json['id'] as num).toInt(),
      number: (json['number'] as num).toInt(),
      nameArabic: json['name_arabic'] as String,
      nameTajik: json['name_tajik'] as String,
      nameEnglish: json['name_english'] as String,
      revelationType: json['revelation_type'] as String,
      versesCount: (json['verses_count'] as num).toInt(),
      description: json['description'] as String?,
      startJuz: (json['startJuz'] as num?)?.toInt(),
      endJuz: (json['endJuz'] as num?)?.toInt(),
      startPage: (json['startPage'] as num?)?.toInt(),
      endPage: (json['endPage'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SurahModelToJson(SurahModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'number': instance.number,
      'name_arabic': instance.nameArabic,
      'name_tajik': instance.nameTajik,
      'name_english': instance.nameEnglish,
      'revelation_type': instance.revelationType,
      'verses_count': instance.versesCount,
      'description': instance.description,
      'startJuz': instance.startJuz,
      'endJuz': instance.endJuz,
      'startPage': instance.startPage,
      'endPage': instance.endPage,
    };
