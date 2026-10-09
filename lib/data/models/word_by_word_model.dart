class WordByWordModel {
  WordByWordModel({
    required this.uniqueKey,
    required this.wordNumber,
    required this.arabic,
    this.farsi,
  });

  final String uniqueKey;
  final int wordNumber;
  final String arabic;
  final String? farsi;

  factory WordByWordModel.fromJson(Map<String, dynamic> json) => WordByWordModel(
        uniqueKey: (json['unique_key'] as String?) ?? '',
        wordNumber: (json['word_number'] as num?)?.toInt() ?? 0,
        arabic: (json['arabic'] as String?) ?? '',
        farsi: json['farsi'] as String?,
      );
}


