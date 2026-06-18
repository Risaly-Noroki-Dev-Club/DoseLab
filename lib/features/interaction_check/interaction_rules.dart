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
];
