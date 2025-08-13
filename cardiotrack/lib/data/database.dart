import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:drift/drift.dart';
import 'package:drift/web.dart' as drift_web;
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

class Readings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get systolic => integer()(); // PAS
  IntColumn get diastolic => integer()(); // PAD
  DateTimeColumn get takenAt => dateTime()();
  TextColumn get notes => text().withDefault(const Constant(''))();
}

@DriftDatabase(tables: [Readings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<int> insertReading(ReadingsCompanion entry) => into(readings).insert(entry);

  Future<List<Reading>> allReadings() => (select(readings)
        ..orderBy([(t) => OrderingTerm.desc(t.takenAt)]))
      .get();

  Stream<List<Reading>> watchReadings() => (select(readings)
        ..orderBy([(t) => OrderingTerm.asc(t.takenAt)]))
      .watch();

  Future<void> deleteReadingById(int id) => (delete(readings)..where((t) => t.id.equals(id))).go();

  Future<void> updateReading(Reading entry) => update(readings).replace(entry);
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    if (kIsWeb) {
      return drift_web.WebDatabase('cardiotrack_db');
    }
    final dir = await getApplicationDocumentsDirectory();
    final dbFile = p.join(dir.path, 'cardiotrack.sqlite');
    return SqfliteQueryExecutor(path: dbFile, logStatements: false);
  });
}