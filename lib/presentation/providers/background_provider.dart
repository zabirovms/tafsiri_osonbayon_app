import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/background_service.dart';

final backgroundServiceProvider = Provider<BackgroundService>((ref) {
  return BackgroundService();
});

final backgroundImagesProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(backgroundServiceProvider);
  return service.fetchBackgroundUrls();
});

final shuffledBackgroundImagesProvider = Provider<List<String>>((ref) {
  final imagesAsync = ref.watch(backgroundImagesProvider);
  return imagesAsync.maybeWhen(
    data: (urls) {
      final shuffled = List<String>.from(urls);
      shuffled.shuffle(Random(DateTime.now().millisecondsSinceEpoch));
      return shuffled;
    },
    orElse: () => const [],
  );
});