/// Domain-wide constants used by multiple features. Keep this file
/// dependency-free so it can be imported anywhere.
class AppConstants {
  const AppConstants._();

  /// Therapeutic band heuristic multipliers, ported verbatim from the
  /// original PWA. They are NOT clinically validated thresholds — they
  /// are visual cues for the PK chart.
  static const double bandMinMultiplier = 0.25;
  static const double bandTherapeuticLow = 0.4;
  static const double bandTherapeuticHigh = 1.0;
  static const double bandToxic = 1.5;

  /// Default PK simulation parameters when no FDA label is available.
  static const double defaultHalfLifeHours = 26.0;
  static const double defaultDoseMg = 50.0;
  static const double defaultIntervalHours = 24.0;
  static const double defaultSimHours = 72.0;

  /// User physiology defaults for PK personalisation.
  static const double defaultHeightCm = 170.0;
  static const double defaultWeightKg = 70.0;

  /// Generic volume-of-distribution factor (L/kg), water-soluble drugs.
  static const double volumeOfDistributionLPerKg = 0.7;

  /// When concentration falls below dose × this multiplier after the
  /// last dose it is considered below the minimum effective level.
  static const double dangerThresholdMultiplier = 0.25;

  /// The exact disclaimer copy the UI must render alongside FDA-derived
  /// content. Wording matches what was shipped in the original PWA.
  static const String disclaimerEn = 'Reference only — not medical advice';
  static const String disclaimerZh = '仅供参考 — 非医疗建议';

  /// Notification channel.
  static const String notificationChannelId = 'doselab_dose_reminders';
  static const String notificationChannelName = 'Dose reminders';
}
