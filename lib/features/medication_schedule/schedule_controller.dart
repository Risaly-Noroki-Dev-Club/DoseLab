import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/storage/local_db.dart';
import '../../shared/utils/uuid.dart';
import 'notification_service.dart';

/// Source of truth for the "my meds" list. Wraps the Drift database
/// behind a Riverpod-friendly stream so the dashboard can rebuild on
/// every add/remove/log event.
class ScheduleController extends Notifier<List<Drug>> {
  late final LocalDb _db;

  @override
  List<Drug> build() {
    _db = ref.watch(localDbProvider);
    _refresh();
    return const [];
  }

  Future<void> _refresh() async {
    state = await _db.getAllDrugs();
    for (final m in state) {
      if (m.notify) _scheduleNext(m);
    }
  }

  Future<Drug> addFromFda({
    required String productNdc,
    required String brandName,
    String? genericName,
    String? strength,
    double doseMg = 50,
    double intervalHours = 24,
  }) async {
    final id = newId();
    final addedAt = DateTime.now();
    await _db.upsertDrug(
      DrugsCompanion.insert(
        id: id,
        productNdc: Value(productNdc),
        brandName: brandName,
        genericName: Value(genericName),
        strength: Value(strength),
        doseMg: Value(doseMg),
        intervalHours: Value(intervalHours),
        addedAt: Value(addedAt),
      ),
    );
    await _refresh();
    return Drug(
      id: id,
      productNdc: productNdc,
      brandName: brandName,
      genericName: genericName,
      strength: strength,
      doseMg: doseMg,
      intervalHours: intervalHours,
      notify: false,
      addedAt: addedAt,
    );
  }

  Future<void> remove(String id) async {
    await NotificationService.instance.cancel(id.hashCode);
    await _db.deleteDrug(id);
    await _refresh();
  }

  Future<void> logDoseNow(String id) async {
    final drug = state.firstWhere((d) => d.id == id);
    await _db.insertDoseLog(
      DoseLogsCompanion.insert(
        id: newId(),
        drugId: drug.id,
        doseMg: drug.doseMg,
        takenAt: DateTime.now(),
      ),
    );
    await _db.upsertDrug(
      drug.copyWith(lastDoseAt: Value(DateTime.now())).toCompanion(true),
    );
    await _refresh();
  }

  Future<void> toggleNotify(String id) async {
    final drug = state.firstWhere((d) => d.id == id);
    final next = !drug.notify;
    if (next) {
      await NotificationService.instance.requestPermission();
    }
    await _db.upsertDrug(
      drug.copyWith(notify: next).toCompanion(true),
    );
    await _refresh();
  }

  Future<void> updateDrug(
    String id, {
    double? doseMg,
    double? intervalHours,
  }) async {
    final drug = state.firstWhere((d) => d.id == id);
    await _db.upsertDrug(
      drug
          .copyWith(
            doseMg: doseMg ?? drug.doseMg,
            intervalHours: intervalHours ?? drug.intervalHours,
          )
          .toCompanion(true),
    );
    await _refresh();
  }

  Future<void> _scheduleNext(Drug drug) async {
    final last = drug.lastDoseAt;
    if (last == null) return;
    final next = last.add(
      Duration(
        milliseconds: (drug.intervalHours * 3600000).toInt(),
      ),
    );
    await NotificationService.instance.scheduleReminder(
      id: drug.id.hashCode,
      title: drug.brandName,
      body: '${drug.doseMg.toStringAsFixed(0)} mg',
      when: next,
    );
  }
}

final scheduleControllerProvider =
    NotifierProvider<ScheduleController, List<Drug>>(ScheduleController.new);
