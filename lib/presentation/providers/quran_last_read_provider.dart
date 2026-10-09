import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/quran_last_read_service.dart';

final quranLastReadServiceProvider = Provider<QuranLastReadService>((ref) {
  return QuranLastReadService();
});

final quranLastReadListProvider = FutureProvider<List<QuranLastReadEntry>>((ref) async {
  final service = ref.watch(quranLastReadServiceProvider);
  return service.getAll();
});
