import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/storage/local_db.dart';
import '../../drug_search/fda_client.dart';
import '../../settings/settings_controller.dart';
import '../domain/pk_label_parser.dart';
import '../domain/usecases/pk_calculator.dart';

@immutable
class PkSettings {
  const PkSettings({
    required this.doseMg,
    required this.intervalHours,
    required this.simHours,
    required this.halfLifeHours,
  });

  final double doseMg;
  final double intervalHours;
  final double simHours;
  final double halfLifeHours;

  PkSettings copyWith({
    double? doseMg,
    double? intervalHours,
    double? simHours,
    double? halfLifeHours,
  }) =>
      PkSettings(
        doseMg: doseMg ?? this.doseMg,
        intervalHours: intervalHours ?? this.intervalHours,
        simHours: simHours ?? this.simHours,
        halfLifeHours: halfLifeHours ?? this.halfLifeHours,
      );
}

@immutable
class PkViewState {
  const PkViewState({
    required this.settings,
    required this.curve,
    this.heightCm = AppConstants.defaultHeightCm,
    this.weightKg = AppConstants.defaultWeightKg,
    this.timeToThresholdHours,
    this.bsa,
    this.doseMgPerKg,
    this.usingRealLogs = false,
  });
  final PkSettings settings;
  final PkCurve curve;
  final double heightCm;
  final double weightKg;
  final double? timeToThresholdHours;
  final double? bsa;
  final double? doseMgPerKg;
  final bool usingRealLogs;
}

class PkController extends FamilyNotifier<PkViewState?, String> {
  static const _calc = PkCalculator();

  @override
  PkViewState? build(String drugId) {
    _load();
    return null;
  }

  Future<void> _load() async {
    final db = ref.read(localDbProvider);
    final drug = (await db.getAllDrugs()).where((d) => d.id == arg).firstOrNull;
    if (drug == null) return;
    final brand = drug.brandName;
    final cached = await db.getPkParam('label:$brand');
    var hl = cached?.halfLifeHours;
    hl ??= await _fetchAndCacheHalfLife(db, brand);
    hl ??= AppConstants.defaultHalfLifeHours;
    final s = ref.read(settingsControllerProvider);

    // Fetch real dose logs and convert to DoseEvents
    final rawLogs = await db.doseLogsFor(arg);
    rawLogs.sort((a, b) => a.takenAt.compareTo(b.takenAt));
    final List<DoseEvent> doseSchedule;
    if (rawLogs.isNotEmpty) {
      final origin = rawLogs.first.takenAt;
      doseSchedule = rawLogs
          .map(
            (l) => DoseEvent(
              hoursFromOrigin:
                  l.takenAt.difference(origin).inMilliseconds / 3600000.0,
              amountMg: l.doseMg,
            ),
          )
          .toList();
    } else {
      doseSchedule = const [];
    }

    final settings = PkSettings(
      doseMg: drug.doseMg,
      intervalHours: drug.intervalHours,
      simHours: AppConstants.defaultSimHours,
      halfLifeHours: hl,
    );
    state = _buildState(
      settings,
      s.heightCm,
      s.weightKg,
      doseSchedule: doseSchedule,
    );
  }

  void update(PkSettings next) {
    final s = ref.read(settingsControllerProvider);
    state = _buildState(next, s.heightCm, s.weightKg);
  }

  Future<void> setHeight(double cm) async {
    await ref.read(settingsControllerProvider.notifier).setHeight(cm);
    if (state case final current?) {
      state = _buildState(current.settings, cm, current.weightKg);
    }
  }

  Future<void> setWeight(double kg) async {
    await ref.read(settingsControllerProvider.notifier).setWeight(kg);
    if (state case final current?) {
      state = _buildState(current.settings, current.heightCm, kg);
    }
  }

  PkViewState _buildState(
    PkSettings st,
    double heightCm,
    double weightKg, {
    List<DoseEvent> doseSchedule = const [],
  }) {
    final curve = _simulate(st, doseSchedule: doseSchedule);
    final bsa = PkCalculator.estimateBsa(heightCm, weightKg);
    final doseMgPerKg = weightKg > 0 ? st.doseMg / weightKg : st.doseMg;
    final threshold = st.doseMg * AppConstants.dangerThresholdMultiplier;
    final t2t = PkCalculator.timeToThreshold(
      cStart: curve.peakValue,
      halfLifeHours: st.halfLifeHours,
      threshold: threshold,
    );
    return PkViewState(
      settings: st,
      curve: curve,
      heightCm: heightCm,
      weightKg: weightKg,
      timeToThresholdHours: t2t.isFinite && t2t < st.simHours ? t2t : null,
      bsa: bsa,
      doseMgPerKg: doseMgPerKg,
      usingRealLogs: doseSchedule.isNotEmpty,
    );
  }

  PkCurve _simulate(PkSettings s, {List<DoseEvent> doseSchedule = const []}) {
    final schedule = doseSchedule.isNotEmpty
        ? doseSchedule
        : _calc.buildRegularSchedule(
            simHours: s.simHours,
            doseMg: s.doseMg,
            intervalHours: s.intervalHours,
          );
    return _calc.simulate(
      PkInput(
        halfLifeHours: s.halfLifeHours,
        schedule: schedule,
        simHours: s.simHours,
      ),
    );
  }

  Future<double?> _fetchAndCacheHalfLife(LocalDb db, String brand) async {
    try {
      final fda = ref.read(fdaClientProvider);
      final env = await fda.searchLabel(brand);
      const parser = PkLabelParser();
      final parsed = parser.parse(env.toJson());
      if (parsed != null && parsed.halfLifeHours != null) {
        await db.upsertPkParam(
          PkParamsCompanion.insert(
            key: 'label:$brand',
            brandTerm: brand,
            halfLifeHours: Value(parsed.halfLifeHours!),
            tmaxText: Value(parsed.tmaxText),
            steadyState: Value(parsed.steadyState),
            sourceUrl: Value(env.requestUrl),
          ),
        );
        return parsed.halfLifeHours;
      }
    } catch (_) {
      // Label not available or parse failed — use default
    }
    return null;
  }
}

final pkControllerProvider =
    NotifierProvider.family<PkController, PkViewState?, String>(
  PkController.new,
);

extension on Iterable<Drug> {
  Drug? get firstOrNull => isEmpty ? null : first;
}
