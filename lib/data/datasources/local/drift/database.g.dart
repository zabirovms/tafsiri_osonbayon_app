// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SurahMetadataTable extends SurahMetadata
    with TableInfo<$SurahMetadataTable, SurahMetadataEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SurahMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
      'number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameArabicMeta =
      const VerificationMeta('nameArabic');
  @override
  late final GeneratedColumn<String> nameArabic = GeneratedColumn<String>(
      'name_arabic', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameTajikMeta =
      const VerificationMeta('nameTajik');
  @override
  late final GeneratedColumn<String> nameTajik = GeneratedColumn<String>(
      'name_tajik', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _versesCountMeta =
      const VerificationMeta('versesCount');
  @override
  late final GeneratedColumn<int> versesCount = GeneratedColumn<int>(
      'verses_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _revelationTypeMeta =
      const VerificationMeta('revelationType');
  @override
  late final GeneratedColumn<String> revelationType = GeneratedColumn<String>(
      'revelation_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [number, nameArabic, nameTajik, versesCount, revelationType, description];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'surah_metadata';
  @override
  VerificationContext validateIntegrity(Insertable<SurahMetadataEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('number')) {
      context.handle(_numberMeta,
          number.isAcceptableOrUnknown(data['number']!, _numberMeta));
    }
    if (data.containsKey('name_arabic')) {
      context.handle(
          _nameArabicMeta,
          nameArabic.isAcceptableOrUnknown(
              data['name_arabic']!, _nameArabicMeta));
    }
    if (data.containsKey('name_tajik')) {
      context.handle(_nameTajikMeta,
          nameTajik.isAcceptableOrUnknown(data['name_tajik']!, _nameTajikMeta));
    }
    if (data.containsKey('verses_count')) {
      context.handle(
          _versesCountMeta,
          versesCount.isAcceptableOrUnknown(
              data['verses_count']!, _versesCountMeta));
    }
    if (data.containsKey('revelation_type')) {
      context.handle(
          _revelationTypeMeta,
          revelationType.isAcceptableOrUnknown(
              data['revelation_type']!, _revelationTypeMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {number};
  @override
  SurahMetadataEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SurahMetadataEntry(
      number: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}number'])!,
      nameArabic: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_arabic']),
      nameTajik: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_tajik']),
      versesCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}verses_count']),
      revelationType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}revelation_type']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
    );
  }

  @override
  $SurahMetadataTable createAlias(String alias) {
    return $SurahMetadataTable(attachedDatabase, alias);
  }
}

class SurahMetadataEntry extends DataClass
    implements Insertable<SurahMetadataEntry> {
  final int number;
  final String? nameArabic;
  final String? nameTajik;
  final int? versesCount;
  final String? revelationType;
  final String? description;
  const SurahMetadataEntry(
      {required this.number,
      this.nameArabic,
      this.nameTajik,
      this.versesCount,
      this.revelationType,
      this.description});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['number'] = Variable<int>(number);
    if (!nullToAbsent || nameArabic != null) {
      map['name_arabic'] = Variable<String>(nameArabic);
    }
    if (!nullToAbsent || nameTajik != null) {
      map['name_tajik'] = Variable<String>(nameTajik);
    }
    if (!nullToAbsent || versesCount != null) {
      map['verses_count'] = Variable<int>(versesCount);
    }
    if (!nullToAbsent || revelationType != null) {
      map['revelation_type'] = Variable<String>(revelationType);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    return map;
  }

  SurahMetadataCompanion toCompanion(bool nullToAbsent) {
    return SurahMetadataCompanion(
      number: Value(number),
      nameArabic: nameArabic == null && nullToAbsent
          ? const Value.absent()
          : Value(nameArabic),
      nameTajik: nameTajik == null && nullToAbsent
          ? const Value.absent()
          : Value(nameTajik),
      versesCount: versesCount == null && nullToAbsent
          ? const Value.absent()
          : Value(versesCount),
      revelationType: revelationType == null && nullToAbsent
          ? const Value.absent()
          : Value(revelationType),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
    );
  }

  factory SurahMetadataEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SurahMetadataEntry(
      number: serializer.fromJson<int>(json['number']),
      nameArabic: serializer.fromJson<String?>(json['nameArabic']),
      nameTajik: serializer.fromJson<String?>(json['nameTajik']),
      versesCount: serializer.fromJson<int?>(json['versesCount']),
      revelationType: serializer.fromJson<String?>(json['revelationType']),
      description: serializer.fromJson<String?>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'number': serializer.toJson<int>(number),
      'nameArabic': serializer.toJson<String?>(nameArabic),
      'nameTajik': serializer.toJson<String?>(nameTajik),
      'versesCount': serializer.toJson<int?>(versesCount),
      'revelationType': serializer.toJson<String?>(revelationType),
      'description': serializer.toJson<String?>(description),
    };
  }

  SurahMetadataEntry copyWith(
          {int? number,
          Value<String?> nameArabic = const Value.absent(),
          Value<String?> nameTajik = const Value.absent(),
          Value<int?> versesCount = const Value.absent(),
          Value<String?> revelationType = const Value.absent(),
          Value<String?> description = const Value.absent()}) =>
      SurahMetadataEntry(
        number: number ?? this.number,
        nameArabic: nameArabic.present ? nameArabic.value : this.nameArabic,
        nameTajik: nameTajik.present ? nameTajik.value : this.nameTajik,
        versesCount: versesCount.present ? versesCount.value : this.versesCount,
        revelationType:
            revelationType.present ? revelationType.value : this.revelationType,
        description: description.present ? description.value : this.description,
      );
  SurahMetadataEntry copyWithCompanion(SurahMetadataCompanion data) {
    return SurahMetadataEntry(
      number: data.number.present ? data.number.value : this.number,
      nameArabic:
          data.nameArabic.present ? data.nameArabic.value : this.nameArabic,
      nameTajik: data.nameTajik.present ? data.nameTajik.value : this.nameTajik,
      versesCount:
          data.versesCount.present ? data.versesCount.value : this.versesCount,
      revelationType: data.revelationType.present
          ? data.revelationType.value
          : this.revelationType,
      description:
          data.description.present ? data.description.value : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SurahMetadataEntry(')
          ..write('number: $number, ')
          ..write('nameArabic: $nameArabic, ')
          ..write('nameTajik: $nameTajik, ')
          ..write('versesCount: $versesCount, ')
          ..write('revelationType: $revelationType, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      number, nameArabic, nameTajik, versesCount, revelationType, description);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SurahMetadataEntry &&
          other.number == this.number &&
          other.nameArabic == this.nameArabic &&
          other.nameTajik == this.nameTajik &&
          other.versesCount == this.versesCount &&
          other.revelationType == this.revelationType &&
          other.description == this.description);
}

class SurahMetadataCompanion extends UpdateCompanion<SurahMetadataEntry> {
  final Value<int> number;
  final Value<String?> nameArabic;
  final Value<String?> nameTajik;
  final Value<int?> versesCount;
  final Value<String?> revelationType;
  final Value<String?> description;
  const SurahMetadataCompanion({
    this.number = const Value.absent(),
    this.nameArabic = const Value.absent(),
    this.nameTajik = const Value.absent(),
    this.versesCount = const Value.absent(),
    this.revelationType = const Value.absent(),
    this.description = const Value.absent(),
  });
  SurahMetadataCompanion.insert({
    this.number = const Value.absent(),
    this.nameArabic = const Value.absent(),
    this.nameTajik = const Value.absent(),
    this.versesCount = const Value.absent(),
    this.revelationType = const Value.absent(),
    this.description = const Value.absent(),
  });
  static Insertable<SurahMetadataEntry> custom({
    Expression<int>? number,
    Expression<String>? nameArabic,
    Expression<String>? nameTajik,
    Expression<int>? versesCount,
    Expression<String>? revelationType,
    Expression<String>? description,
  }) {
    return RawValuesInsertable({
      if (number != null) 'number': number,
      if (nameArabic != null) 'name_arabic': nameArabic,
      if (nameTajik != null) 'name_tajik': nameTajik,
      if (versesCount != null) 'verses_count': versesCount,
      if (revelationType != null) 'revelation_type': revelationType,
      if (description != null) 'description': description,
    });
  }

  SurahMetadataCompanion copyWith(
      {Value<int>? number,
      Value<String?>? nameArabic,
      Value<String?>? nameTajik,
      Value<int?>? versesCount,
      Value<String?>? revelationType,
      Value<String?>? description}) {
    return SurahMetadataCompanion(
      number: number ?? this.number,
      nameArabic: nameArabic ?? this.nameArabic,
      nameTajik: nameTajik ?? this.nameTajik,
      versesCount: versesCount ?? this.versesCount,
      revelationType: revelationType ?? this.revelationType,
      description: description ?? this.description,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (nameArabic.present) {
      map['name_arabic'] = Variable<String>(nameArabic.value);
    }
    if (nameTajik.present) {
      map['name_tajik'] = Variable<String>(nameTajik.value);
    }
    if (versesCount.present) {
      map['verses_count'] = Variable<int>(versesCount.value);
    }
    if (revelationType.present) {
      map['revelation_type'] = Variable<String>(revelationType.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurahMetadataCompanion(')
          ..write('number: $number, ')
          ..write('nameArabic: $nameArabic, ')
          ..write('nameTajik: $nameTajik, ')
          ..write('versesCount: $versesCount, ')
          ..write('revelationType: $revelationType, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }
}

class $VersesTable extends Verses with TableInfo<$VersesTable, VerseEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VersesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _surahIdMeta =
      const VerificationMeta('surahId');
  @override
  late final GeneratedColumn<int> surahId = GeneratedColumn<int>(
      'surah_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _verseIdMeta =
      const VerificationMeta('verseId');
  @override
  late final GeneratedColumn<int> verseId = GeneratedColumn<int>(
      'verse_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _absoluteIdMeta =
      const VerificationMeta('absoluteId');
  @override
  late final GeneratedColumn<int> absoluteId = GeneratedColumn<int>(
      'absolute_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _arabicTextMeta =
      const VerificationMeta('arabicText');
  @override
  late final GeneratedColumn<String> arabicText = GeneratedColumn<String>(
      'arabic_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _wbwTextMeta =
      const VerificationMeta('wbwText');
  @override
  late final GeneratedColumn<String> wbwText = GeneratedColumn<String>(
      'wbw_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
      'page', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _juzMeta = const VerificationMeta('juz');
  @override
  late final GeneratedColumn<int> juz = GeneratedColumn<int>(
      'juz', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [surahId, verseId, absoluteId, arabicText, wbwText, page, juz];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'verses';
  @override
  VerificationContext validateIntegrity(Insertable<VerseEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('surah_id')) {
      context.handle(_surahIdMeta,
          surahId.isAcceptableOrUnknown(data['surah_id']!, _surahIdMeta));
    } else if (isInserting) {
      context.missing(_surahIdMeta);
    }
    if (data.containsKey('verse_id')) {
      context.handle(_verseIdMeta,
          verseId.isAcceptableOrUnknown(data['verse_id']!, _verseIdMeta));
    } else if (isInserting) {
      context.missing(_verseIdMeta);
    }
    if (data.containsKey('absolute_id')) {
      context.handle(
          _absoluteIdMeta,
          absoluteId.isAcceptableOrUnknown(
              data['absolute_id']!, _absoluteIdMeta));
    }
    if (data.containsKey('arabic_text')) {
      context.handle(
          _arabicTextMeta,
          arabicText.isAcceptableOrUnknown(
              data['arabic_text']!, _arabicTextMeta));
    }
    if (data.containsKey('wbw_text')) {
      context.handle(_wbwTextMeta,
          wbwText.isAcceptableOrUnknown(data['wbw_text']!, _wbwTextMeta));
    }
    if (data.containsKey('page')) {
      context.handle(
          _pageMeta, page.isAcceptableOrUnknown(data['page']!, _pageMeta));
    }
    if (data.containsKey('juz')) {
      context.handle(
          _juzMeta, juz.isAcceptableOrUnknown(data['juz']!, _juzMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {surahId, verseId};
  @override
  VerseEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VerseEntry(
      surahId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}surah_id'])!,
      verseId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}verse_id'])!,
      absoluteId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}absolute_id']),
      arabicText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}arabic_text']),
      wbwText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}wbw_text']),
      page: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}page']),
      juz: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}juz']),
    );
  }

  @override
  $VersesTable createAlias(String alias) {
    return $VersesTable(attachedDatabase, alias);
  }
}

class VerseEntry extends DataClass implements Insertable<VerseEntry> {
  final int surahId;
  final int verseId;
  final int? absoluteId;
  final String? arabicText;
  final String? wbwText;
  final int? page;
  final int? juz;
  const VerseEntry(
      {required this.surahId,
      required this.verseId,
      this.absoluteId,
      this.arabicText,
      this.wbwText,
      this.page,
      this.juz});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['surah_id'] = Variable<int>(surahId);
    map['verse_id'] = Variable<int>(verseId);
    if (!nullToAbsent || absoluteId != null) {
      map['absolute_id'] = Variable<int>(absoluteId);
    }
    if (!nullToAbsent || arabicText != null) {
      map['arabic_text'] = Variable<String>(arabicText);
    }
    if (!nullToAbsent || wbwText != null) {
      map['wbw_text'] = Variable<String>(wbwText);
    }
    if (!nullToAbsent || page != null) {
      map['page'] = Variable<int>(page);
    }
    if (!nullToAbsent || juz != null) {
      map['juz'] = Variable<int>(juz);
    }
    return map;
  }

  VersesCompanion toCompanion(bool nullToAbsent) {
    return VersesCompanion(
      surahId: Value(surahId),
      verseId: Value(verseId),
      absoluteId: absoluteId == null && nullToAbsent
          ? const Value.absent()
          : Value(absoluteId),
      arabicText: arabicText == null && nullToAbsent
          ? const Value.absent()
          : Value(arabicText),
      wbwText: wbwText == null && nullToAbsent
          ? const Value.absent()
          : Value(wbwText),
      page: page == null && nullToAbsent ? const Value.absent() : Value(page),
      juz: juz == null && nullToAbsent ? const Value.absent() : Value(juz),
    );
  }

  factory VerseEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VerseEntry(
      surahId: serializer.fromJson<int>(json['surahId']),
      verseId: serializer.fromJson<int>(json['verseId']),
      absoluteId: serializer.fromJson<int?>(json['absoluteId']),
      arabicText: serializer.fromJson<String?>(json['arabicText']),
      wbwText: serializer.fromJson<String?>(json['wbwText']),
      page: serializer.fromJson<int?>(json['page']),
      juz: serializer.fromJson<int?>(json['juz']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'surahId': serializer.toJson<int>(surahId),
      'verseId': serializer.toJson<int>(verseId),
      'absoluteId': serializer.toJson<int?>(absoluteId),
      'arabicText': serializer.toJson<String?>(arabicText),
      'wbwText': serializer.toJson<String?>(wbwText),
      'page': serializer.toJson<int?>(page),
      'juz': serializer.toJson<int?>(juz),
    };
  }

  VerseEntry copyWith(
          {int? surahId,
          int? verseId,
          Value<int?> absoluteId = const Value.absent(),
          Value<String?> arabicText = const Value.absent(),
          Value<String?> wbwText = const Value.absent(),
          Value<int?> page = const Value.absent(),
          Value<int?> juz = const Value.absent()}) =>
      VerseEntry(
        surahId: surahId ?? this.surahId,
        verseId: verseId ?? this.verseId,
        absoluteId: absoluteId.present ? absoluteId.value : this.absoluteId,
        arabicText: arabicText.present ? arabicText.value : this.arabicText,
        wbwText: wbwText.present ? wbwText.value : this.wbwText,
        page: page.present ? page.value : this.page,
        juz: juz.present ? juz.value : this.juz,
      );
  VerseEntry copyWithCompanion(VersesCompanion data) {
    return VerseEntry(
      surahId: data.surahId.present ? data.surahId.value : this.surahId,
      verseId: data.verseId.present ? data.verseId.value : this.verseId,
      absoluteId:
          data.absoluteId.present ? data.absoluteId.value : this.absoluteId,
      arabicText:
          data.arabicText.present ? data.arabicText.value : this.arabicText,
      wbwText: data.wbwText.present ? data.wbwText.value : this.wbwText,
      page: data.page.present ? data.page.value : this.page,
      juz: data.juz.present ? data.juz.value : this.juz,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VerseEntry(')
          ..write('surahId: $surahId, ')
          ..write('verseId: $verseId, ')
          ..write('absoluteId: $absoluteId, ')
          ..write('arabicText: $arabicText, ')
          ..write('wbwText: $wbwText, ')
          ..write('page: $page, ')
          ..write('juz: $juz')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(surahId, verseId, absoluteId, arabicText, wbwText, page, juz);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VerseEntry &&
          other.surahId == this.surahId &&
          other.verseId == this.verseId &&
          other.absoluteId == this.absoluteId &&
          other.arabicText == this.arabicText &&
          other.wbwText == this.wbwText &&
          other.page == this.page &&
          other.juz == this.juz);
}

class VersesCompanion extends UpdateCompanion<VerseEntry> {
  final Value<int> surahId;
  final Value<int> verseId;
  final Value<int?> absoluteId;
  final Value<String?> arabicText;
  final Value<String?> wbwText;
  final Value<int?> page;
  final Value<int?> juz;
  final Value<int> rowid;
  const VersesCompanion({
    this.surahId = const Value.absent(),
    this.verseId = const Value.absent(),
    this.absoluteId = const Value.absent(),
    this.arabicText = const Value.absent(),
    this.wbwText = const Value.absent(),
    this.page = const Value.absent(),
    this.juz = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VersesCompanion.insert({
    required int surahId,
    required int verseId,
    this.absoluteId = const Value.absent(),
    this.arabicText = const Value.absent(),
    this.wbwText = const Value.absent(),
    this.page = const Value.absent(),
    this.juz = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : surahId = Value(surahId),
        verseId = Value(verseId);
  static Insertable<VerseEntry> custom({
    Expression<int>? surahId,
    Expression<int>? verseId,
    Expression<int>? absoluteId,
    Expression<String>? arabicText,
    Expression<String>? wbwText,
    Expression<int>? page,
    Expression<int>? juz,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (surahId != null) 'surah_id': surahId,
      if (verseId != null) 'verse_id': verseId,
      if (absoluteId != null) 'absolute_id': absoluteId,
      if (arabicText != null) 'arabic_text': arabicText,
      if (wbwText != null) 'wbw_text': wbwText,
      if (page != null) 'page': page,
      if (juz != null) 'juz': juz,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VersesCompanion copyWith(
      {Value<int>? surahId,
      Value<int>? verseId,
      Value<int?>? absoluteId,
      Value<String?>? arabicText,
      Value<String?>? wbwText,
      Value<int?>? page,
      Value<int?>? juz,
      Value<int>? rowid}) {
    return VersesCompanion(
      surahId: surahId ?? this.surahId,
      verseId: verseId ?? this.verseId,
      absoluteId: absoluteId ?? this.absoluteId,
      arabicText: arabicText ?? this.arabicText,
      wbwText: wbwText ?? this.wbwText,
      page: page ?? this.page,
      juz: juz ?? this.juz,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (surahId.present) {
      map['surah_id'] = Variable<int>(surahId.value);
    }
    if (verseId.present) {
      map['verse_id'] = Variable<int>(verseId.value);
    }
    if (absoluteId.present) {
      map['absolute_id'] = Variable<int>(absoluteId.value);
    }
    if (arabicText.present) {
      map['arabic_text'] = Variable<String>(arabicText.value);
    }
    if (wbwText.present) {
      map['wbw_text'] = Variable<String>(wbwText.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (juz.present) {
      map['juz'] = Variable<int>(juz.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VersesCompanion(')
          ..write('surahId: $surahId, ')
          ..write('verseId: $verseId, ')
          ..write('absoluteId: $absoluteId, ')
          ..write('arabicText: $arabicText, ')
          ..write('wbwText: $wbwText, ')
          ..write('page: $page, ')
          ..write('juz: $juz, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TranslationsTable extends Translations
    with TableInfo<$TranslationsTable, TranslationEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TranslationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _surahIdMeta =
      const VerificationMeta('surahId');
  @override
  late final GeneratedColumn<int> surahId = GeneratedColumn<int>(
      'surah_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _verseIdMeta =
      const VerificationMeta('verseId');
  @override
  late final GeneratedColumn<int> verseId = GeneratedColumn<int>(
      'verse_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _resourceIdMeta =
      const VerificationMeta('resourceId');
  @override
  late final GeneratedColumn<String> resourceId = GeneratedColumn<String>(
      'resource_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [surahId, verseId, resourceId, content];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'translations';
  @override
  VerificationContext validateIntegrity(Insertable<TranslationEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('surah_id')) {
      context.handle(_surahIdMeta,
          surahId.isAcceptableOrUnknown(data['surah_id']!, _surahIdMeta));
    } else if (isInserting) {
      context.missing(_surahIdMeta);
    }
    if (data.containsKey('verse_id')) {
      context.handle(_verseIdMeta,
          verseId.isAcceptableOrUnknown(data['verse_id']!, _verseIdMeta));
    } else if (isInserting) {
      context.missing(_verseIdMeta);
    }
    if (data.containsKey('resource_id')) {
      context.handle(
          _resourceIdMeta,
          resourceId.isAcceptableOrUnknown(
              data['resource_id']!, _resourceIdMeta));
    } else if (isInserting) {
      context.missing(_resourceIdMeta);
    }
    if (data.containsKey('text')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['text']!, _contentMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {surahId, verseId, resourceId};
  @override
  TranslationEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TranslationEntry(
      surahId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}surah_id'])!,
      verseId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}verse_id'])!,
      resourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}resource_id'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}text']),
    );
  }

  @override
  $TranslationsTable createAlias(String alias) {
    return $TranslationsTable(attachedDatabase, alias);
  }
}

class TranslationEntry extends DataClass
    implements Insertable<TranslationEntry> {
  final int surahId;
  final int verseId;
  final String resourceId;
  final String? content;
  const TranslationEntry(
      {required this.surahId,
      required this.verseId,
      required this.resourceId,
      this.content});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['surah_id'] = Variable<int>(surahId);
    map['verse_id'] = Variable<int>(verseId);
    map['resource_id'] = Variable<String>(resourceId);
    if (!nullToAbsent || content != null) {
      map['text'] = Variable<String>(content);
    }
    return map;
  }

  TranslationsCompanion toCompanion(bool nullToAbsent) {
    return TranslationsCompanion(
      surahId: Value(surahId),
      verseId: Value(verseId),
      resourceId: Value(resourceId),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
    );
  }

  factory TranslationEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TranslationEntry(
      surahId: serializer.fromJson<int>(json['surahId']),
      verseId: serializer.fromJson<int>(json['verseId']),
      resourceId: serializer.fromJson<String>(json['resourceId']),
      content: serializer.fromJson<String?>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'surahId': serializer.toJson<int>(surahId),
      'verseId': serializer.toJson<int>(verseId),
      'resourceId': serializer.toJson<String>(resourceId),
      'content': serializer.toJson<String?>(content),
    };
  }

  TranslationEntry copyWith(
          {int? surahId,
          int? verseId,
          String? resourceId,
          Value<String?> content = const Value.absent()}) =>
      TranslationEntry(
        surahId: surahId ?? this.surahId,
        verseId: verseId ?? this.verseId,
        resourceId: resourceId ?? this.resourceId,
        content: content.present ? content.value : this.content,
      );
  TranslationEntry copyWithCompanion(TranslationsCompanion data) {
    return TranslationEntry(
      surahId: data.surahId.present ? data.surahId.value : this.surahId,
      verseId: data.verseId.present ? data.verseId.value : this.verseId,
      resourceId:
          data.resourceId.present ? data.resourceId.value : this.resourceId,
      content: data.content.present ? data.content.value : this.content,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TranslationEntry(')
          ..write('surahId: $surahId, ')
          ..write('verseId: $verseId, ')
          ..write('resourceId: $resourceId, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(surahId, verseId, resourceId, content);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TranslationEntry &&
          other.surahId == this.surahId &&
          other.verseId == this.verseId &&
          other.resourceId == this.resourceId &&
          other.content == this.content);
}

class TranslationsCompanion extends UpdateCompanion<TranslationEntry> {
  final Value<int> surahId;
  final Value<int> verseId;
  final Value<String> resourceId;
  final Value<String?> content;
  final Value<int> rowid;
  const TranslationsCompanion({
    this.surahId = const Value.absent(),
    this.verseId = const Value.absent(),
    this.resourceId = const Value.absent(),
    this.content = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TranslationsCompanion.insert({
    required int surahId,
    required int verseId,
    required String resourceId,
    this.content = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : surahId = Value(surahId),
        verseId = Value(verseId),
        resourceId = Value(resourceId);
  static Insertable<TranslationEntry> custom({
    Expression<int>? surahId,
    Expression<int>? verseId,
    Expression<String>? resourceId,
    Expression<String>? content,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (surahId != null) 'surah_id': surahId,
      if (verseId != null) 'verse_id': verseId,
      if (resourceId != null) 'resource_id': resourceId,
      if (content != null) 'text': content,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TranslationsCompanion copyWith(
      {Value<int>? surahId,
      Value<int>? verseId,
      Value<String>? resourceId,
      Value<String?>? content,
      Value<int>? rowid}) {
    return TranslationsCompanion(
      surahId: surahId ?? this.surahId,
      verseId: verseId ?? this.verseId,
      resourceId: resourceId ?? this.resourceId,
      content: content ?? this.content,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (surahId.present) {
      map['surah_id'] = Variable<int>(surahId.value);
    }
    if (verseId.present) {
      map['verse_id'] = Variable<int>(verseId.value);
    }
    if (resourceId.present) {
      map['resource_id'] = Variable<String>(resourceId.value);
    }
    if (content.present) {
      map['text'] = Variable<String>(content.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TranslationsCompanion(')
          ..write('surahId: $surahId, ')
          ..write('verseId: $verseId, ')
          ..write('resourceId: $resourceId, ')
          ..write('content: $content, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TafsirTable extends Tafsir with TableInfo<$TafsirTable, TafsirEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TafsirTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _surahIdMeta =
      const VerificationMeta('surahId');
  @override
  late final GeneratedColumn<int> surahId = GeneratedColumn<int>(
      'surah_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _verseIdMeta =
      const VerificationMeta('verseId');
  @override
  late final GeneratedColumn<int> verseId = GeneratedColumn<int>(
      'verse_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _resourceIdMeta =
      const VerificationMeta('resourceId');
  @override
  late final GeneratedColumn<String> resourceId = GeneratedColumn<String>(
      'resource_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [surahId, verseId, resourceId, content];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tafsir';
  @override
  VerificationContext validateIntegrity(Insertable<TafsirEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('surah_id')) {
      context.handle(_surahIdMeta,
          surahId.isAcceptableOrUnknown(data['surah_id']!, _surahIdMeta));
    } else if (isInserting) {
      context.missing(_surahIdMeta);
    }
    if (data.containsKey('verse_id')) {
      context.handle(_verseIdMeta,
          verseId.isAcceptableOrUnknown(data['verse_id']!, _verseIdMeta));
    } else if (isInserting) {
      context.missing(_verseIdMeta);
    }
    if (data.containsKey('resource_id')) {
      context.handle(
          _resourceIdMeta,
          resourceId.isAcceptableOrUnknown(
              data['resource_id']!, _resourceIdMeta));
    } else if (isInserting) {
      context.missing(_resourceIdMeta);
    }
    if (data.containsKey('text')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['text']!, _contentMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {surahId, verseId, resourceId};
  @override
  TafsirEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TafsirEntry(
      surahId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}surah_id'])!,
      verseId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}verse_id'])!,
      resourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}resource_id'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}text']),
    );
  }

  @override
  $TafsirTable createAlias(String alias) {
    return $TafsirTable(attachedDatabase, alias);
  }
}

class TafsirEntry extends DataClass implements Insertable<TafsirEntry> {
  final int surahId;
  final int verseId;
  final String resourceId;
  final String? content;
  const TafsirEntry(
      {required this.surahId,
      required this.verseId,
      required this.resourceId,
      this.content});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['surah_id'] = Variable<int>(surahId);
    map['verse_id'] = Variable<int>(verseId);
    map['resource_id'] = Variable<String>(resourceId);
    if (!nullToAbsent || content != null) {
      map['text'] = Variable<String>(content);
    }
    return map;
  }

  TafsirCompanion toCompanion(bool nullToAbsent) {
    return TafsirCompanion(
      surahId: Value(surahId),
      verseId: Value(verseId),
      resourceId: Value(resourceId),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
    );
  }

  factory TafsirEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TafsirEntry(
      surahId: serializer.fromJson<int>(json['surahId']),
      verseId: serializer.fromJson<int>(json['verseId']),
      resourceId: serializer.fromJson<String>(json['resourceId']),
      content: serializer.fromJson<String?>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'surahId': serializer.toJson<int>(surahId),
      'verseId': serializer.toJson<int>(verseId),
      'resourceId': serializer.toJson<String>(resourceId),
      'content': serializer.toJson<String?>(content),
    };
  }

  TafsirEntry copyWith(
          {int? surahId,
          int? verseId,
          String? resourceId,
          Value<String?> content = const Value.absent()}) =>
      TafsirEntry(
        surahId: surahId ?? this.surahId,
        verseId: verseId ?? this.verseId,
        resourceId: resourceId ?? this.resourceId,
        content: content.present ? content.value : this.content,
      );
  TafsirEntry copyWithCompanion(TafsirCompanion data) {
    return TafsirEntry(
      surahId: data.surahId.present ? data.surahId.value : this.surahId,
      verseId: data.verseId.present ? data.verseId.value : this.verseId,
      resourceId:
          data.resourceId.present ? data.resourceId.value : this.resourceId,
      content: data.content.present ? data.content.value : this.content,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TafsirEntry(')
          ..write('surahId: $surahId, ')
          ..write('verseId: $verseId, ')
          ..write('resourceId: $resourceId, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(surahId, verseId, resourceId, content);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TafsirEntry &&
          other.surahId == this.surahId &&
          other.verseId == this.verseId &&
          other.resourceId == this.resourceId &&
          other.content == this.content);
}

class TafsirCompanion extends UpdateCompanion<TafsirEntry> {
  final Value<int> surahId;
  final Value<int> verseId;
  final Value<String> resourceId;
  final Value<String?> content;
  final Value<int> rowid;
  const TafsirCompanion({
    this.surahId = const Value.absent(),
    this.verseId = const Value.absent(),
    this.resourceId = const Value.absent(),
    this.content = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TafsirCompanion.insert({
    required int surahId,
    required int verseId,
    required String resourceId,
    this.content = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : surahId = Value(surahId),
        verseId = Value(verseId),
        resourceId = Value(resourceId);
  static Insertable<TafsirEntry> custom({
    Expression<int>? surahId,
    Expression<int>? verseId,
    Expression<String>? resourceId,
    Expression<String>? content,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (surahId != null) 'surah_id': surahId,
      if (verseId != null) 'verse_id': verseId,
      if (resourceId != null) 'resource_id': resourceId,
      if (content != null) 'text': content,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TafsirCompanion copyWith(
      {Value<int>? surahId,
      Value<int>? verseId,
      Value<String>? resourceId,
      Value<String?>? content,
      Value<int>? rowid}) {
    return TafsirCompanion(
      surahId: surahId ?? this.surahId,
      verseId: verseId ?? this.verseId,
      resourceId: resourceId ?? this.resourceId,
      content: content ?? this.content,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (surahId.present) {
      map['surah_id'] = Variable<int>(surahId.value);
    }
    if (verseId.present) {
      map['verse_id'] = Variable<int>(verseId.value);
    }
    if (resourceId.present) {
      map['resource_id'] = Variable<String>(resourceId.value);
    }
    if (content.present) {
      map['text'] = Variable<String>(content.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TafsirCompanion(')
          ..write('surahId: $surahId, ')
          ..write('verseId: $verseId, ')
          ..write('resourceId: $resourceId, ')
          ..write('content: $content, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SurahMetadataTable surahMetadata = $SurahMetadataTable(this);
  late final $VersesTable verses = $VersesTable(this);
  late final $TranslationsTable translations = $TranslationsTable(this);
  late final $TafsirTable tafsir = $TafsirTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [surahMetadata, verses, translations, tafsir];
}

typedef $$SurahMetadataTableCreateCompanionBuilder = SurahMetadataCompanion
    Function({
  Value<int> number,
  Value<String?> nameArabic,
  Value<String?> nameTajik,
  Value<int?> versesCount,
  Value<String?> revelationType,
  Value<String?> description,
});
typedef $$SurahMetadataTableUpdateCompanionBuilder = SurahMetadataCompanion
    Function({
  Value<int> number,
  Value<String?> nameArabic,
  Value<String?> nameTajik,
  Value<int?> versesCount,
  Value<String?> revelationType,
  Value<String?> description,
});

class $$SurahMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $SurahMetadataTable> {
  $$SurahMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get number => $composableBuilder(
      column: $table.number, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameArabic => $composableBuilder(
      column: $table.nameArabic, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameTajik => $composableBuilder(
      column: $table.nameTajik, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get versesCount => $composableBuilder(
      column: $table.versesCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get revelationType => $composableBuilder(
      column: $table.revelationType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));
}

class $$SurahMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $SurahMetadataTable> {
  $$SurahMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get number => $composableBuilder(
      column: $table.number, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameArabic => $composableBuilder(
      column: $table.nameArabic, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameTajik => $composableBuilder(
      column: $table.nameTajik, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get versesCount => $composableBuilder(
      column: $table.versesCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get revelationType => $composableBuilder(
      column: $table.revelationType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));
}

class $$SurahMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $SurahMetadataTable> {
  $$SurahMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get nameArabic => $composableBuilder(
      column: $table.nameArabic, builder: (column) => column);

  GeneratedColumn<String> get nameTajik =>
      $composableBuilder(column: $table.nameTajik, builder: (column) => column);

  GeneratedColumn<int> get versesCount => $composableBuilder(
      column: $table.versesCount, builder: (column) => column);

  GeneratedColumn<String> get revelationType => $composableBuilder(
      column: $table.revelationType, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);
}

class $$SurahMetadataTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SurahMetadataTable,
    SurahMetadataEntry,
    $$SurahMetadataTableFilterComposer,
    $$SurahMetadataTableOrderingComposer,
    $$SurahMetadataTableAnnotationComposer,
    $$SurahMetadataTableCreateCompanionBuilder,
    $$SurahMetadataTableUpdateCompanionBuilder,
    (
      SurahMetadataEntry,
      BaseReferences<_$AppDatabase, $SurahMetadataTable, SurahMetadataEntry>
    ),
    SurahMetadataEntry,
    PrefetchHooks Function()> {
  $$SurahMetadataTableTableManager(_$AppDatabase db, $SurahMetadataTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SurahMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SurahMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SurahMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> number = const Value.absent(),
            Value<String?> nameArabic = const Value.absent(),
            Value<String?> nameTajik = const Value.absent(),
            Value<int?> versesCount = const Value.absent(),
            Value<String?> revelationType = const Value.absent(),
            Value<String?> description = const Value.absent(),
          }) =>
              SurahMetadataCompanion(
            number: number,
            nameArabic: nameArabic,
            nameTajik: nameTajik,
            versesCount: versesCount,
            revelationType: revelationType,
            description: description,
          ),
          createCompanionCallback: ({
            Value<int> number = const Value.absent(),
            Value<String?> nameArabic = const Value.absent(),
            Value<String?> nameTajik = const Value.absent(),
            Value<int?> versesCount = const Value.absent(),
            Value<String?> revelationType = const Value.absent(),
            Value<String?> description = const Value.absent(),
          }) =>
              SurahMetadataCompanion.insert(
            number: number,
            nameArabic: nameArabic,
            nameTajik: nameTajik,
            versesCount: versesCount,
            revelationType: revelationType,
            description: description,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SurahMetadataTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SurahMetadataTable,
    SurahMetadataEntry,
    $$SurahMetadataTableFilterComposer,
    $$SurahMetadataTableOrderingComposer,
    $$SurahMetadataTableAnnotationComposer,
    $$SurahMetadataTableCreateCompanionBuilder,
    $$SurahMetadataTableUpdateCompanionBuilder,
    (
      SurahMetadataEntry,
      BaseReferences<_$AppDatabase, $SurahMetadataTable, SurahMetadataEntry>
    ),
    SurahMetadataEntry,
    PrefetchHooks Function()>;
typedef $$VersesTableCreateCompanionBuilder = VersesCompanion Function({
  required int surahId,
  required int verseId,
  Value<int?> absoluteId,
  Value<String?> arabicText,
  Value<String?> wbwText,
  Value<int?> page,
  Value<int?> juz,
  Value<int> rowid,
});
typedef $$VersesTableUpdateCompanionBuilder = VersesCompanion Function({
  Value<int> surahId,
  Value<int> verseId,
  Value<int?> absoluteId,
  Value<String?> arabicText,
  Value<String?> wbwText,
  Value<int?> page,
  Value<int?> juz,
  Value<int> rowid,
});

class $$VersesTableFilterComposer
    extends Composer<_$AppDatabase, $VersesTable> {
  $$VersesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get surahId => $composableBuilder(
      column: $table.surahId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get verseId => $composableBuilder(
      column: $table.verseId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get absoluteId => $composableBuilder(
      column: $table.absoluteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get arabicText => $composableBuilder(
      column: $table.arabicText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get wbwText => $composableBuilder(
      column: $table.wbwText, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get page => $composableBuilder(
      column: $table.page, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get juz => $composableBuilder(
      column: $table.juz, builder: (column) => ColumnFilters(column));
}

class $$VersesTableOrderingComposer
    extends Composer<_$AppDatabase, $VersesTable> {
  $$VersesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get surahId => $composableBuilder(
      column: $table.surahId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get verseId => $composableBuilder(
      column: $table.verseId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get absoluteId => $composableBuilder(
      column: $table.absoluteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get arabicText => $composableBuilder(
      column: $table.arabicText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get wbwText => $composableBuilder(
      column: $table.wbwText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get page => $composableBuilder(
      column: $table.page, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get juz => $composableBuilder(
      column: $table.juz, builder: (column) => ColumnOrderings(column));
}

class $$VersesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VersesTable> {
  $$VersesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get surahId =>
      $composableBuilder(column: $table.surahId, builder: (column) => column);

  GeneratedColumn<int> get verseId =>
      $composableBuilder(column: $table.verseId, builder: (column) => column);

  GeneratedColumn<int> get absoluteId => $composableBuilder(
      column: $table.absoluteId, builder: (column) => column);

  GeneratedColumn<String> get arabicText => $composableBuilder(
      column: $table.arabicText, builder: (column) => column);

  GeneratedColumn<String> get wbwText =>
      $composableBuilder(column: $table.wbwText, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<int> get juz =>
      $composableBuilder(column: $table.juz, builder: (column) => column);
}

class $$VersesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VersesTable,
    VerseEntry,
    $$VersesTableFilterComposer,
    $$VersesTableOrderingComposer,
    $$VersesTableAnnotationComposer,
    $$VersesTableCreateCompanionBuilder,
    $$VersesTableUpdateCompanionBuilder,
    (VerseEntry, BaseReferences<_$AppDatabase, $VersesTable, VerseEntry>),
    VerseEntry,
    PrefetchHooks Function()> {
  $$VersesTableTableManager(_$AppDatabase db, $VersesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VersesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VersesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VersesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> surahId = const Value.absent(),
            Value<int> verseId = const Value.absent(),
            Value<int?> absoluteId = const Value.absent(),
            Value<String?> arabicText = const Value.absent(),
            Value<String?> wbwText = const Value.absent(),
            Value<int?> page = const Value.absent(),
            Value<int?> juz = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VersesCompanion(
            surahId: surahId,
            verseId: verseId,
            absoluteId: absoluteId,
            arabicText: arabicText,
            wbwText: wbwText,
            page: page,
            juz: juz,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int surahId,
            required int verseId,
            Value<int?> absoluteId = const Value.absent(),
            Value<String?> arabicText = const Value.absent(),
            Value<String?> wbwText = const Value.absent(),
            Value<int?> page = const Value.absent(),
            Value<int?> juz = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VersesCompanion.insert(
            surahId: surahId,
            verseId: verseId,
            absoluteId: absoluteId,
            arabicText: arabicText,
            wbwText: wbwText,
            page: page,
            juz: juz,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VersesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VersesTable,
    VerseEntry,
    $$VersesTableFilterComposer,
    $$VersesTableOrderingComposer,
    $$VersesTableAnnotationComposer,
    $$VersesTableCreateCompanionBuilder,
    $$VersesTableUpdateCompanionBuilder,
    (VerseEntry, BaseReferences<_$AppDatabase, $VersesTable, VerseEntry>),
    VerseEntry,
    PrefetchHooks Function()>;
typedef $$TranslationsTableCreateCompanionBuilder = TranslationsCompanion
    Function({
  required int surahId,
  required int verseId,
  required String resourceId,
  Value<String?> content,
  Value<int> rowid,
});
typedef $$TranslationsTableUpdateCompanionBuilder = TranslationsCompanion
    Function({
  Value<int> surahId,
  Value<int> verseId,
  Value<String> resourceId,
  Value<String?> content,
  Value<int> rowid,
});

class $$TranslationsTableFilterComposer
    extends Composer<_$AppDatabase, $TranslationsTable> {
  $$TranslationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get surahId => $composableBuilder(
      column: $table.surahId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get verseId => $composableBuilder(
      column: $table.verseId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get resourceId => $composableBuilder(
      column: $table.resourceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));
}

class $$TranslationsTableOrderingComposer
    extends Composer<_$AppDatabase, $TranslationsTable> {
  $$TranslationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get surahId => $composableBuilder(
      column: $table.surahId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get verseId => $composableBuilder(
      column: $table.verseId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get resourceId => $composableBuilder(
      column: $table.resourceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));
}

class $$TranslationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TranslationsTable> {
  $$TranslationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get surahId =>
      $composableBuilder(column: $table.surahId, builder: (column) => column);

  GeneratedColumn<int> get verseId =>
      $composableBuilder(column: $table.verseId, builder: (column) => column);

  GeneratedColumn<String> get resourceId => $composableBuilder(
      column: $table.resourceId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);
}

class $$TranslationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TranslationsTable,
    TranslationEntry,
    $$TranslationsTableFilterComposer,
    $$TranslationsTableOrderingComposer,
    $$TranslationsTableAnnotationComposer,
    $$TranslationsTableCreateCompanionBuilder,
    $$TranslationsTableUpdateCompanionBuilder,
    (
      TranslationEntry,
      BaseReferences<_$AppDatabase, $TranslationsTable, TranslationEntry>
    ),
    TranslationEntry,
    PrefetchHooks Function()> {
  $$TranslationsTableTableManager(_$AppDatabase db, $TranslationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TranslationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TranslationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TranslationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> surahId = const Value.absent(),
            Value<int> verseId = const Value.absent(),
            Value<String> resourceId = const Value.absent(),
            Value<String?> content = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TranslationsCompanion(
            surahId: surahId,
            verseId: verseId,
            resourceId: resourceId,
            content: content,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int surahId,
            required int verseId,
            required String resourceId,
            Value<String?> content = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TranslationsCompanion.insert(
            surahId: surahId,
            verseId: verseId,
            resourceId: resourceId,
            content: content,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TranslationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TranslationsTable,
    TranslationEntry,
    $$TranslationsTableFilterComposer,
    $$TranslationsTableOrderingComposer,
    $$TranslationsTableAnnotationComposer,
    $$TranslationsTableCreateCompanionBuilder,
    $$TranslationsTableUpdateCompanionBuilder,
    (
      TranslationEntry,
      BaseReferences<_$AppDatabase, $TranslationsTable, TranslationEntry>
    ),
    TranslationEntry,
    PrefetchHooks Function()>;
typedef $$TafsirTableCreateCompanionBuilder = TafsirCompanion Function({
  required int surahId,
  required int verseId,
  required String resourceId,
  Value<String?> content,
  Value<int> rowid,
});
typedef $$TafsirTableUpdateCompanionBuilder = TafsirCompanion Function({
  Value<int> surahId,
  Value<int> verseId,
  Value<String> resourceId,
  Value<String?> content,
  Value<int> rowid,
});

class $$TafsirTableFilterComposer
    extends Composer<_$AppDatabase, $TafsirTable> {
  $$TafsirTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get surahId => $composableBuilder(
      column: $table.surahId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get verseId => $composableBuilder(
      column: $table.verseId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get resourceId => $composableBuilder(
      column: $table.resourceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));
}

class $$TafsirTableOrderingComposer
    extends Composer<_$AppDatabase, $TafsirTable> {
  $$TafsirTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get surahId => $composableBuilder(
      column: $table.surahId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get verseId => $composableBuilder(
      column: $table.verseId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get resourceId => $composableBuilder(
      column: $table.resourceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));
}

class $$TafsirTableAnnotationComposer
    extends Composer<_$AppDatabase, $TafsirTable> {
  $$TafsirTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get surahId =>
      $composableBuilder(column: $table.surahId, builder: (column) => column);

  GeneratedColumn<int> get verseId =>
      $composableBuilder(column: $table.verseId, builder: (column) => column);

  GeneratedColumn<String> get resourceId => $composableBuilder(
      column: $table.resourceId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);
}

class $$TafsirTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TafsirTable,
    TafsirEntry,
    $$TafsirTableFilterComposer,
    $$TafsirTableOrderingComposer,
    $$TafsirTableAnnotationComposer,
    $$TafsirTableCreateCompanionBuilder,
    $$TafsirTableUpdateCompanionBuilder,
    (TafsirEntry, BaseReferences<_$AppDatabase, $TafsirTable, TafsirEntry>),
    TafsirEntry,
    PrefetchHooks Function()> {
  $$TafsirTableTableManager(_$AppDatabase db, $TafsirTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TafsirTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TafsirTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TafsirTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> surahId = const Value.absent(),
            Value<int> verseId = const Value.absent(),
            Value<String> resourceId = const Value.absent(),
            Value<String?> content = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TafsirCompanion(
            surahId: surahId,
            verseId: verseId,
            resourceId: resourceId,
            content: content,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int surahId,
            required int verseId,
            required String resourceId,
            Value<String?> content = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TafsirCompanion.insert(
            surahId: surahId,
            verseId: verseId,
            resourceId: resourceId,
            content: content,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TafsirTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TafsirTable,
    TafsirEntry,
    $$TafsirTableFilterComposer,
    $$TafsirTableOrderingComposer,
    $$TafsirTableAnnotationComposer,
    $$TafsirTableCreateCompanionBuilder,
    $$TafsirTableUpdateCompanionBuilder,
    (TafsirEntry, BaseReferences<_$AppDatabase, $TafsirTable, TafsirEntry>),
    TafsirEntry,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SurahMetadataTableTableManager get surahMetadata =>
      $$SurahMetadataTableTableManager(_db, _db.surahMetadata);
  $$VersesTableTableManager get verses =>
      $$VersesTableTableManager(_db, _db.verses);
  $$TranslationsTableTableManager get translations =>
      $$TranslationsTableTableManager(_db, _db.translations);
  $$TafsirTableTableManager get tafsir =>
      $$TafsirTableTableManager(_db, _db.tafsir);
}
