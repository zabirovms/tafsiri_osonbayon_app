class AqcSurahResponse {
  AqcSurahResponse({required this.data});
  final dynamic data; // can be SurahEdition or List<SurahEdition> depending on endpoint

  factory AqcSurahResponse.fromJson(Map<String, dynamic> json) => AqcSurahResponse(data: json['data']);
}

class SurahEdition {
  SurahEdition({required this.editionIdentifier, required this.ayahs});

  final String editionIdentifier; // e.g., 'quran-uthmani' or 'ar.alafasy'
  final List<AqcAyah> ayahs;

  factory SurahEdition.fromJson(Map<String, dynamic> json) {
    final edition = json['edition'] as Map<String, dynamic>?;
    final identifier = (edition != null ? (edition['identifier'] as String? ?? '') : '')
        .toString();
    final ayahsJson = (json['ayahs'] as List?) ?? const [];
    return SurahEdition(
      editionIdentifier: identifier,
      ayahs: ayahsJson.map((e) => AqcAyah.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class AqcAyah {
  AqcAyah({
    this.number,
    required this.numberInSurah,
    required this.text,
    this.audio,
    this.juz,
    this.manzil,
    this.ruku,
    this.hizbQuarter,
    this.page,
    this.sajda,
  });

  final int numberInSurah;
  final int? number; // global ayah number (1..6236)
  final String text;
  final String? audio; // present for audio editions
  final int? juz;
  final int? manzil;
  final int? ruku;
  final int? hizbQuarter;
  final int? page;
  final dynamic sajda; // can be bool or object

  factory AqcAyah.fromJson(Map<String, dynamic> json) => AqcAyah(
        number: (json['number'] as num?)?.toInt(),
        numberInSurah: (json['numberInSurah'] as num).toInt(),
        text: (json['text'] as String?) ?? '',
        audio: json['audio'] as String?,
        juz: (json['juz'] as num?)?.toInt(),
        manzil: (json['manzil'] as num?)?.toInt(),
        ruku: (json['ruku'] as num?)?.toInt(),
        hizbQuarter: (json['hizbQuarter'] as num?)?.toInt(),
        page: (json['page'] as num?)?.toInt(),
        sajda: json['sajda'],
      );
}

class AudioEditionInfo {
  AudioEditionInfo({required this.identifier, required this.englishName});
  final String identifier; // e.g., 'ar.alafasy'
  final String englishName; // e.g., 'Mishary Rashid Alafasy'

  factory AudioEditionInfo.fromJson(Map<String, dynamic> json) => AudioEditionInfo(
        identifier: (json['identifier'] as String?) ?? '',
        englishName: (json['englishName'] as String?) ?? ((json['name'] as String?) ?? ''),
      );
}


