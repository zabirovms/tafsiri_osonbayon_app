import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AudioFavorite {
  final String reciterId;
  final int surahNumber;
  final DateTime createdAt;

  AudioFavorite({
    required this.reciterId,
    required this.surahNumber,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'reciterId': reciterId,
        'surahNumber': surahNumber,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AudioFavorite.fromJson(Map<String, dynamic> json) => AudioFavorite(
        reciterId: json['reciterId'] as String,
        surahNumber: json['surahNumber'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  String get key => '$reciterId:$surahNumber';
}

class AudioFavoritesService {
  static const String _key = 'audio_favorites';

  Future<List<AudioFavorite>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => AudioFavorite.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> isFavorite(String reciterId, int surahNumber) async {
    final favorites = await getFavorites();
    final key = '$reciterId:$surahNumber';
    return favorites.any((f) => f.key == key);
  }

  Future<void> addFavorite(String reciterId, int surahNumber) async {
    final favorites = await getFavorites();
    final key = '$reciterId:$surahNumber';
    
    // Check if already exists
    if (favorites.any((f) => f.key == key)) return;

    favorites.add(AudioFavorite(
      reciterId: reciterId,
      surahNumber: surahNumber,
      createdAt: DateTime.now(),
    ));

    await _saveFavorites(favorites);
  }

  Future<void> removeFavorite(String reciterId, int surahNumber) async {
    final favorites = await getFavorites();
    final key = '$reciterId:$surahNumber';
    favorites.removeWhere((f) => f.key == key);
    await _saveFavorites(favorites);
  }

  Future<void> toggleFavorite(String reciterId, int surahNumber) async {
    final isFav = await isFavorite(reciterId, surahNumber);
    if (isFav) {
      await removeFavorite(reciterId, surahNumber);
    } else {
      await addFavorite(reciterId, surahNumber);
    }
  }

  Future<List<AudioFavorite>> getFavoritesByReciter(String reciterId) async {
    final favorites = await getFavorites();
    return favorites.where((f) => f.reciterId == reciterId).toList();
  }

  Future<void> _saveFavorites(List<AudioFavorite> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = favorites.map((f) => f.toJson()).toList();
    await prefs.setString(_key, json.encode(jsonList));
  }
}

