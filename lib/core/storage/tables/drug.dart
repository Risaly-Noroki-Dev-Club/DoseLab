import 'package:drift/drift.dart';

/// "My meds" entries. Schema mirrors the IndexedDB `meds` store that
/// shipped in the original PWA so existing exports remain readable.
class Drugs extends Table {
  TextColumn get id => text()();
  TextColumn get productNdc => text().nullable()();
  TextColumn get brandName => text()();
  TextColumn get genericName => text().nullable()();
  TextColumn get strength => text().nullable()();
  RealColumn get doseMg => real().withDefault(const Constant(50))();
  RealColumn get intervalHours => real().withDefault(const Constant(24))();
  BoolColumn get notify => boolean().withDefault(const Constant(false))();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastDoseAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
