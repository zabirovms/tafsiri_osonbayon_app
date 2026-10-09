import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'surah_model.g.dart';

@JsonSerializable()
class SurahModel extends Equatable {
  final int id;
  final int number;
  @JsonKey(name: 'name_arabic')
  final String nameArabic;
  @JsonKey(name: 'name_tajik')
  final String nameTajik;
  @JsonKey(name: 'name_english')
  final String nameEnglish;
  @JsonKey(name: 'revelation_type')
  final String revelationType;
  @JsonKey(name: 'verses_count')
  final int versesCount;
  final String? description;
  
  // Juz and Page information
  final int? startJuz;
  final int? endJuz;
  final int? startPage;
  final int? endPage;

  const SurahModel({
    required this.id,
    required this.number,
    required this.nameArabic,
    required this.nameTajik,
    required this.nameEnglish,
    required this.revelationType,
    required this.versesCount,
    this.description,
    this.startJuz,
    this.endJuz,
    this.startPage,
    this.endPage,
  });

  factory SurahModel.fromJson(Map<String, dynamic> json) =>
      _$SurahModelFromJson(json);

  /// Factory method for AlQuran Cloud JSON format
  factory SurahModel.fromAlQuranCloudJson(Map<String, dynamic> json) {
    final ayahs = json['ayahs'] as List?;
    
    // Calculate juz and page ranges from first and last ayah
    int? startJuz;
    int? endJuz;
    int? startPage;
    int? endPage;
    
    if (ayahs != null && ayahs.isNotEmpty) {
      final firstAyah = ayahs.first as Map<String, dynamic>;
      final lastAyah = ayahs.last as Map<String, dynamic>;
      
      startJuz = firstAyah['juz'] as int?;
      endJuz = lastAyah['juz'] as int?;
      startPage = firstAyah['page'] as int?;
      endPage = lastAyah['page'] as int?;
    }
    
    return SurahModel(
      id: json['number'] as int,
      number: json['number'] as int,
      nameArabic: json['name'] as String,
      nameTajik: json['name_tajik'] as String,
      nameEnglish: '', // Not available in new format
      revelationType: json['revelationType'] as String,
      versesCount: ayahs?.length ?? 0,
      description: json['description'] as String?,
      startJuz: startJuz,
      endJuz: endJuz,
      startPage: startPage,
      endPage: endPage,
    );
  }

  Map<String, dynamic> toJson() => _$SurahModelToJson(this);

  SurahModel copyWith({
    int? id,
    int? number,
    String? nameArabic,
    String? nameTajik,
    String? nameEnglish,
    String? revelationType,
    int? versesCount,
    String? description,
    int? startJuz,
    int? endJuz,
    int? startPage,
    int? endPage,
  }) {
    return SurahModel(
      id: id ?? this.id,
      number: number ?? this.number,
      nameArabic: nameArabic ?? this.nameArabic,
      nameTajik: nameTajik ?? this.nameTajik,
      nameEnglish: nameEnglish ?? this.nameEnglish,
      revelationType: revelationType ?? this.revelationType,
      versesCount: versesCount ?? this.versesCount,
      description: description ?? this.description,
      startJuz: startJuz ?? this.startJuz,
      endJuz: endJuz ?? this.endJuz,
      startPage: startPage ?? this.startPage,
      endPage: endPage ?? this.endPage,
    );
  }

  @override
  List<Object?> get props => [
        id,
        number,
        nameArabic,
        nameTajik,
        nameEnglish,
        revelationType,
        versesCount,
        description,
        startJuz,
        endJuz,
        startPage,
        endPage,
      ];

  @override
  String toString() {
    return 'SurahModel(id: $id, number: $number, nameArabic: $nameArabic, nameTajik: $nameTajik, nameEnglish: $nameEnglish, revelationType: $revelationType, versesCount: $versesCount, description: $description, startJuz: $startJuz, endJuz: $endJuz, startPage: $startPage, endPage: $endPage)';
  }
}
