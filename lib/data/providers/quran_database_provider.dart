import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/local/drift/database.dart';

final quranDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() {
    db.close();
  });
  return db;
});
