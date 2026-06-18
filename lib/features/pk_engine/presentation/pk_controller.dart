import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/storage/local_db.dart';
import '../../settings/settings_controller.dart';
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
  });
  final PkSettings settings;
  final PkCurve curve;
  final double heightCm;
  final double weightKg;
  final double? timeToThresholdHours;
  final double? bsa;
  final double? doseMgPerKg;
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
    final hl = cached?.halfLifeHours ?? AppConstants.defaultHalfLifeHours;
    final s = ref.read(settingsControllerProvider);
    final settings = PkSettings(
      doseMg: drug.doseMg,
      intervalHours: drug.intervalHours,
      simHours: AppConstants.defaultSimHours,
      halfLifeHours: hl,
    );
    state = _buildState(settings, s.heightCm, s.weightKg);
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

  PkViewState _buildState(PkSettings st, double heightCm, double weightKg) {
    final curve = _simulate(st);
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
    );
  }

  PkCurve _simulate(PkSettings s) {
    final schedule = _calc.buildRegularSchedule(
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
}

final pkControllerProvider =
    NotifierProvider.family<PkController, PkViewState?, String>(
  PkController.new,
);

extension on Iterable<Drug> {
  Drug? get firstOrNull => isEmpty ? null : first;
}
