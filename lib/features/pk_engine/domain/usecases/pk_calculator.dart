import 'dart:math' as math;

import '../../../../core/config/constants.dart';

/// One scheduled or recorded dose.
class DoseEvent {
  const DoseEvent({required this.hoursFromOrigin, required this.amountMg});
  final double hoursFromOrigin;
  final double amountMg;
}

/// PK simulation input.
class PkInput {
  const PkInput({
    required this.halfLifeHours,
    required this.schedule,
    this.simHours = AppConstants.defaultSimHours,
    this.stepHours = 0.5,
  });

  final double halfLifeHours;
  final List<DoseEvent> schedule;
  final double simHours;
  final double stepHours;
}

/// Output: a sampled concentration curve plus convenience peaks.
class PkCurve {
  PkCurve({
    required this.times,
    required this.concentrations,
    required this.peakValue,
    required this.peakHour,
  });
  final List<double> times;
  final List<double> concentrations;
  final double peakValue;
  final double peakHour;
}

/// Pure-Dart PK engine. Implements first-order exponential decay
/// summed over every dose so far:
///
///   C(t) = Σ dose_i * 0.5 ^ ((t - t_i) / half_life)   for t ≥ t_i
///
/// Matches the formula used by `concentration()` in the original
/// PWA. No external dependencies → trivially testable, runs offline,
/// and can be invoked from isolates if needed.
class PkCalculator {
  const PkCalculator();

  double concentrationAt({
    required double tHours,
    required double halfLifeHours,
    required List<DoseEvent> schedule,
  }) {
    if (halfLifeHours <= 0) return 0;
    var c = 0.0;
    for (final d in schedule) {
      if (tHours < d.hoursFromOrigin) continue;
      c += d.amountMg *
          math.pow(0.5, (tHours - d.hoursFromOrigin) / halfLifeHours);
    }
    return c;
  }

  PkCurve simulate(PkInput input) {
    final times = <double>[];
    final values = <double>[];
    var peakV = 0.0;
    var peakT = 0.0;
    for (var t = 0.0; t <= input.simHours; t += input.stepHours) {
      final c = concentrationAt(
        tHours: t,
        halfLifeHours: input.halfLifeHours,
        schedule: input.schedule,
      );
      times.add(t);
      values.add(c);
      if (c > peakV) {
        peakV = c;
        peakT = t;
      }
    }
    return PkCurve(
      times: times,
      concentrations: values,
      peakValue: peakV,
      peakHour: peakT,
    );
  }

  /// Build a repeating dose schedule for [simHours] hours given a
  /// fixed [doseMg] taken every [intervalHours].
  List<DoseEvent> buildRegularSchedule({
    required double simHours,
    required double doseMg,
    required double intervalHours,
  }) {
    final out = <DoseEvent>[];
    for (var t = 0.0; t < simHours; t += intervalHours) {
      out.add(DoseEvent(hoursFromOrigin: t, amountMg: doseMg));
    }
    return out;
  }

  /// DuBois body surface area from height (cm) and weight (kg).
  static double estimateBsa(double heightCm, double weightKg) {
    return 0.007184 * math.pow(heightCm, 0.725) * math.pow(weightKg, 0.425);
  }

  /// Crude volume-of-distribution estimate (L), water-soluble drugs.
  static double estimateVd(double weightKg) {
    return weightKg * AppConstants.volumeOfDistributionLPerKg;
  }

  /// Time (hours) for the concentration to decay from [cStart] to
  /// at most [threshold] given first-order elimination.
  /// Returns double.infinity when the threshold cannot be reached.
  static double timeToThreshold({
    required double cStart,
    required double halfLifeHours,
    required double threshold,
  }) {
    if (cStart <= 0 || threshold <= 0) return double.infinity;
    if (cStart <= threshold) return 0;
    if (halfLifeHours <= 0) return double.infinity;
    final ratio = cStart / threshold;
    return halfLifeHours * (math.log(ratio) / math.ln2);
  }
}
