import 'package:equatable/equatable.dart';

class BookmarkModel extends Equatable {
  final int id;
  final String userId;
  final int verseId;
  final String verseKey;
  final int surahNumber;
  final int verseNumber;
  final String arabicText;
  final String ayatiText;
  final String surahName;
  final DateTime createdAt;

  const BookmarkModel({
    required this.id,
    required this.userId,
    required this.verseId,
    required this.verseKey,
    required this.surahNumber,
    required this.verseNumber,
    required this.arabicText,
    required this.ayatiText,
    required this.surahName,
    required this.createdAt,
  });

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    return BookmarkModel(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      verseId: json['verse_id'] as int,
      verseKey: json['verse_key'] as String,
      surahNumber: json['surah_number'] as int,
      verseNumber: json['verse_number'] as int,
      arabicText: json['arabic_text'] as String,
      ayatiText: json['tajik_text'] as String,
      surahName: json['surah_name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'verse_id': verseId,
      'verse_key': verseKey,
      'surah_number': surahNumber,
      'verse_number': verseNumber,
      'arabic_text': arabicText,
      'tajik_text': ayatiText,
      'surah_name': surahName,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  BookmarkModel copyWith({
    int? id,
    String? userId,
    int? verseId,
    String? verseKey,
    int? surahNumber,
    int? verseNumber,
    String? arabicText,
    String? ayatiText,
    String? surahName,
    DateTime? createdAt,
  }) {
    return BookmarkModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      verseId: verseId ?? this.verseId,
      verseKey: verseKey ?? this.verseKey,
      surahNumber: surahNumber ?? this.surahNumber,
      verseNumber: verseNumber ?? this.verseNumber,
      arabicText: arabicText ?? this.arabicText,
      ayatiText: ayatiText ?? this.ayatiText,
      surahName: surahName ?? this.surahName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        verseId,
        verseKey,
        surahNumber,
        verseNumber,
        arabicText,
        ayatiText,
        surahName,
        createdAt,
      ];

  @override
  String toString() {
    return 'BookmarkModel(id: $id, userId: $userId, verseId: $verseId, verseKey: $verseKey, surahNumber: $surahNumber, verseNumber: $verseNumber, arabicText: $arabicText, ayatiText: $ayatiText, surahName: $surahName, createdAt: $createdAt)';
  }
}
