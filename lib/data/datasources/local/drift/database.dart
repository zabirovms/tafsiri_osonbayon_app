import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:shared_preferences/shared_preferences.dart';

part 'database.g.dart';

@DataClassName('SurahMetadataEntry')
class SurahMetadata extends Table {
  IntColumn get number => integer()();
  TextColumn get nameArabic => text().nullable()();
  TextColumn get nameTajik => text().nullable()();
  IntColumn get versesCount => integer().nullable()();
  TextColumn get revelationType => text().nullable()();
  TextColumn get description => text().nullable()();

  @override
  Set<Column> get primaryKey => {number};
}

@DataClassName('VerseEntry')
class Verses extends Table {
  IntColumn get surahId => integer()();
  IntColumn get verseId => integer()();
  IntColumn get absoluteId => integer().nullable()();
  TextColumn get arabicText => text().nullable()();
  TextColumn get wbwText => text().nullable()();
  IntColumn get page => integer().nullable()();
  IntColumn get juz => integer().nullable()();

  @override
  Set<Column> get primaryKey => {surahId, verseId};
}

@DataClassName('TranslationEntry')
class Translations extends Table {
  IntColumn get surahId => integer()();
  IntColumn get verseId => integer()();
  TextColumn get resourceId => text()();
  TextColumn get content => text().named('text').nullable()();

  @override
  Set<Column> get primaryKey => {surahId, verseId, resourceId};
}

@DataClassName('TafsirEntry')
class Tafsir extends Table {
  IntColumn get surahId => integer()();
  IntColumn get verseId => integer()();
  TextColumn get resourceId => text()();
  TextColumn get content => text().named('text').nullable()();

  @override
  Set<Column> get primaryKey => {surahId, verseId, resourceId};
}

@DriftDatabase(tables: [SurahMetadata, Verses, Translations, Tafsir])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'quran_prebuilt.sqlite'));
    final tempFile = File(p.join(dbFolder.path, 'quran_prebuilt.sqlite.tmp'));

    const expectedDbVersion = 2; // Incremented for verified QUL KFGQPC Hafs migration
    bool needsCopy = false;

    // 1. Verify existence and internal database version before opening via Drift
    if (!await file.exists()) {
      needsCopy = true;
    } else {
      try {
        final db = sqlite3.sqlite3.open(file.path);
        final results = db.select("SELECT value FROM db_metadata WHERE key = 'db_version'");
        int internalVersion = 1;
        if (results.isNotEmpty) {
          internalVersion = int.tryParse(results.first['value']?.toString() ?? '1') ?? 1;
        }
        db.dispose();

        if (internalVersion < expectedDbVersion) {
          needsCopy = true;
        }
      } catch (e) {
        // Force recopy if file is corrupted, unreadable, or missing version table/key
        needsCopy = true;
      }
    }

    // 2. Perform safe, atomic copy if required
    if (needsCopy) {
      try {
        // Copy to temporary file first to avoid database corruption if interrupted
        if (await tempFile.exists()) {
          await tempFile.delete();
        }

        final blob = await rootBundle.load('assets/data/quran/quran_prebuilt.sqlite');
        
        // Write file in 512KB chunks to yield event loop and avoid main isolate ANR freeze
        final sink = tempFile.openWrite();
        final bytes = blob.buffer.asUint8List(blob.offsetInBytes, blob.lengthInBytes);
        const chunkSize = 512 * 1024; // 512 KB chunks
        for (int offset = 0; offset < bytes.length; offset += chunkSize) {
          final end = (offset + chunkSize < bytes.length) ? offset + chunkSize : bytes.length;
          sink.add(bytes.sublist(offset, end));
          if (offset % (1024 * 1024) == 0) {
            await sink.flush();
            await Future<void>.delayed(Duration.zero);
          }
        }
        await sink.close();

        // Atomic swap (rename temp file to final file)
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (_) {}
        }
        await tempFile.rename(file.path);

        // Sync SharedPreferences version flag as a secondary verification
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('quran_prebuilt_db_version', expectedDbVersion);
      } catch (e) {
        // Cleanup temp file in case of failure
        if (await tempFile.exists()) {
          try {
            await tempFile.delete();
          } catch (_) {}
        }
        throw Exception('Failed to safely copy prebuilt database from assets: $e');
      }
    }

    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        try {
          db.execute('PRAGMA journal_mode = WAL;');
          db.execute('PRAGMA wal_autocheckpoint = 100;');
        } catch (_) {}
      },
    );
  });
}

