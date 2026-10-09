import 'package:equatable/equatable.dart';

class TajikAudioFileModel extends Equatable {
  final String name; // e.g., "003.mp3"
  final String url; // Direct URL to the audio file
  final int size; // File size in bytes

  const TajikAudioFileModel({
    required this.name,
    required this.url,
    required this.size,
  });

  // Extract surah number from filename (e.g., "003.mp3" -> 3)
  int get surahNumber {
    try {
      // Tajik surah files are named exactly "XXX.mp3" (e.g., "001.mp3" to "114.mp3")
      // Ensure the name is exactly 7 characters (3 digits + ".mp3") and contains only digits before the extension
      if (name.length != 7 || !name.endsWith('.mp3')) {
        return 0;
      }
      final numberStr = name.substring(0, 3);
      final parsed = int.parse(numberStr);
      if (parsed < 1 || parsed > 114) {
        return 0;
      }
      return parsed;
    } catch (e) {
      return 0;
    }
  }

  factory TajikAudioFileModel.fromJson(Map<String, dynamic> json) {
    return TajikAudioFileModel(
      name: json['name'] as String,
      url: json['url'] as String,
      size: json['size'] as int,
    );
  }

  @override
  List<Object?> get props => [name, url, size];
}

