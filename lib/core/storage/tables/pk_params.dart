import 'package:drift/drift.dart';

/// Cached PK parameters parsed from openFDA `drug/label.json`.
/// Mirrors the IndexedDB `labels` store from the original PWA
/// (`key: 'label:<term>'`, TTL 24 h).
class PkParams extends Table {
  TextColumn get key => text()();
  TextColumn get brandTerm => text()();
  RealColumn get halfLifeHours => real().nullable()();
  TextColumn get tmaxText => text().nullable()();
  TextColumn get steadyState => text().nullable()();
  TextColumn get sourceUrl => text().nullable()();
  TextColumn get sourceLastUpdated => text().nullable()();
  DateTimeColumn get fetchedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
