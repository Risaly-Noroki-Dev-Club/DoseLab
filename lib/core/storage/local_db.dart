import 'package:drift/drift.dart';

import 'local_db_connection.dart';
import 'tables/dose_log.dart';
import 'tables/drug.dart';
import 'tables/pk_params.dart';

// Re-export the small slice of drift that callers need to build
// companion values, so feature code can stay free of direct drift
// imports and just depend on this database barrel.
export 'package:drift/drift.dart' show Value;

part 'local_db.g.dart';

@DriftDatabase(tables: [Drugs, DoseLogs, PkParams])
class LocalDb extends _$LocalDb {
  LocalDb() : super(openConnection());

  @override
  int get schemaVersion => 1;

  // ── Drugs ────────────────────────────────────────────────────────
  Future<List<Drug>> getAllDrugs() => select(drugs).get();
  Stream<List<Drug>> watchAllDrugs() => select(drugs).watch();
  Future<void> upsertDrug(DrugsCompanion entry) =>
      into(drugs).insertOnConflictUpdate(entry);
  Future<void> deleteDrug(String id) =>
      (delete(drugs)..where((t) => t.id.equals(id))).go();

  // ── Dose logs ────────────────────────────────────────────────────
  Future<List<DoseLog>> doseLogsFor(String drugId) =>
      (select(doseLogs)..where((t) => t.drugId.equals(drugId))).get();
  Future<void> insertDoseLog(DoseLogsCompanion entry) =>
      into(doseLogs).insert(entry);

  // ── PK params ────────────────────────────────────────────────────
  Future<PkParam?> getPkParam(String key) =>
      (select(pkParams)..where((t) => t.key.equals(key))).getSingleOrNull();
  Future<void> upsertPkParam(PkParamsCompanion entry) =>
      into(pkParams).insertOnConflictUpdate(entry);
}
