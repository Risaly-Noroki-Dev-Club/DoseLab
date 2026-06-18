/// Static, conservative interaction rules. MVP scope explicitly
/// excludes a "full clinical interaction database" (see
/// docs/PRODUCT.md non-goals), so this list intentionally covers
/// only a handful of high-impact pairs. Anything not listed surfaces
/// as "no interaction detected" — never as endorsement.
class InteractionRule {
  const InteractionRule({
    required this.a,
    required this.b,
    required this.severity,
    required this.summary,
    required this.summaryZh,
  });

  final String a;
  final String b;
  final InteractionSeverity severity;
  final String summary;
  final String summaryZh;

  bool matches(String x, String y) {
    final xa = x.toLowerCase();
    final yb = y.toLowerCase();
    return (xa.contains(a) && yb.contains(b)) ||
        (xa.contains(b) && yb.contains(a));
  }
}

enum InteractionSeverity { caution, warning, severe }

const interactionRules = <InteractionRule>[
  InteractionRule(
    a: 'sertraline',
    b: 'tramadol',
    severity: InteractionSeverity.severe,
    summary:
        'SSRI + tramadol increases serotonin syndrome risk. Reference only.',
    summaryZh: 'SSRI 与 tramadol 合用可能增加血清素综合征风险。仅供参考。',
  ),
  InteractionRule(
    a: 'fluoxetine',
    b: 'tramadol',
    severity: InteractionSeverity.severe,
    summary:
        'SSRI + tramadol increases serotonin syndrome risk. Reference only.',
    summaryZh: 'SSRI 与 tramadol 合用可能增加血清素综合征风险。仅供参考。',
  ),
  InteractionRule(
    a: 'warfarin',
    b: 'ibuprofen',
    severity: InteractionSeverity.warning,
    summary: 'NSAID can increase bleeding risk with warfarin. Reference only.',
    summaryZh: 'NSAID 与 warfarin 合用可能增加出血风险。仅供参考。',
  ),
  InteractionRule(
    a: 'lithium',
    b: 'ibuprofen',
    severity: InteractionSeverity.warning,
    summary: 'NSAIDs can raise lithium levels. Reference only.',
    summaryZh: 'NSAID 可能升高 lithium 水平。仅供参考。',
  ),
  InteractionRule(
    a: 'monoamine',
    b: 'tyramine',
    severity: InteractionSeverity.severe,
    summary: 'MAOI + tyramine: hypertensive crisis risk. Reference only.',
    summaryZh: 'MAOI 与 tyramine 相关组合可能有高血压危象风险。仅供参考。',
  ),
  InteractionRule(
    a: 'aspirin',
    b: 'ibuprofen',
    severity: InteractionSeverity.warning,
    summary: 'Multiple NSAIDs increase GI bleed risk. Reference only.',
    summaryZh: '多种 NSAID 合用可能增加肠胃出血风险。仅供参考。',
  ),
  InteractionRule(
    a: 'digoxin',
    b: 'furosemide',
    severity: InteractionSeverity.warning,
    summary:
        'Loop diuretic may cause hypokalemia, increasing digoxin toxicity risk. Reference only.',
    summaryZh: '利尿剂可能导致低钾，增加 digoxin 中毒风险。仅供参考。',
  ),
  InteractionRule(
    a: 'methotrexate',
    b: 'ibuprofen',
    severity: InteractionSeverity.severe,
    summary: 'NSAIDs can increase methotrexate levels. Reference only.',
    summaryZh: 'NSAID 可能升高 methotrexate 水平。仅供参考。',
  ),
  InteractionRule(
    a: 'citalopram',
    b: 'tramadol',
    severity: InteractionSeverity.severe,
    summary:
        'SSRI + tramadol increases serotonin syndrome risk. Reference only.',
    summaryZh: 'SSRI 与 tramadol 合用可能增加血清素综合征风险。仅供参考。',
  ),
  InteractionRule(
    a: 'ativan',
    b: 'xanax',
    severity: InteractionSeverity.warning,
    summary: 'Combined benzodiazepines increase sedation risk. Reference only.',
    summaryZh: '多种苯二氮卓类药物合用可能加重镇静作用。仅供参考。',
  ),
  InteractionRule(
    a: 'metformin',
    b: 'furosemide',
    severity: InteractionSeverity.caution,
    summary:
        'Diuretic may affect glucose control. Monitor levels. Reference only.',
    summaryZh: '利尿剂可能影响血糖控制，建议监测。仅供参考。',
  ),
  InteractionRule(
    a: 'omeprazole',
    b: 'clopidogrel',
    severity: InteractionSeverity.warning,
    summary: 'PPI may reduce clopidogrel activation. Reference only.',
    summaryZh: 'PPI 可能降低 clopidogrel 的活化效果。仅供参考。',
  ),
  InteractionRule(
    a: 'simvastatin',
    b: 'warfarin',
    severity: InteractionSeverity.caution,
    summary: 'Statin may potentiate warfarin effect. Reference only.',
    summaryZh: 'Statin 可能增强 warfarin 作用。仅供参考。',
  ),
  InteractionRule(
    a: 'ciprofloxacin',
    b: 'warfarin',
    severity: InteractionSeverity.warning,
    summary: 'Antibiotic may potentiate warfarin effect. Reference only.',
    summaryZh: '抗生素可能增强 warfarin 作用。仅供参考。',
  ),
  InteractionRule(
    a: 'paracetamol',
    b: 'warfarin',
    severity: InteractionSeverity.caution,
    summary:
        'High-dose paracetamol may increase INR with warfarin. Reference only.',
    summaryZh: '大剂量 paracetamol 可能影响 warfarin 的 INR。仅供参考。',
  ),
];
