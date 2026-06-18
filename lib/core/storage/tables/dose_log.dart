import 'package:drift/drift.dart';

import 'drug.dart';

/// One row per recorded dose. Used both by the schedule view and as
/// the input series for the PK calculator.
class DoseLogs extends Table {
  TextColumn get id => text()();
  TextColumn get drugId => text().references(Drugs, #id)();
  RealColumn get doseMg => real()();
  DateTimeColumn get takenAt => dateTime()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
