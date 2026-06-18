import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/constants.dart';
import '../../../shared/l10n/app_localizations.dart';
import '../../../shared/widgets/disclaimer_banner.dart';
import '../../../shared/widgets/loading_indicator.dart';
import 'pk_chart.dart';
import 'pk_controller.dart';

class PkScreen extends ConsumerWidget {
  const PkScreen({super.key, required this.drugId});
  final String drugId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pkControllerProvider(drugId));
    final t = AppLocalizations.of(context);

    if (state == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.pkData)),
        body: const LoadingIndicator(),
      );
    }
    final s = state.settings;
    final schedule = [
      for (var x = 0.0; x < s.simHours; x += s.intervalHours) x,
    ];
    final threshold = s.doseMg * AppConstants.dangerThresholdMultiplier;

    return Scaffold(
      appBar: AppBar(title: Text(t.pkData)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const DisclaimerBanner(dense: true),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _NumField(
                    label: t.dose,
                    value: s.doseMg,
                    onChanged: (v) => ref
                        .read(pkControllerProvider(drugId).notifier)
                        .update(s.copyWith(doseMg: v)),
                  ),
                  _NumField(
                    label: '${t.every} h',
                    value: s.intervalHours,
                    onChanged: (v) => ref
                        .read(pkControllerProvider(drugId).notifier)
                        .update(s.copyWith(intervalHours: v)),
                  ),
                  _NumField(
                    label: t.simulationHours,
                    value: s.simHours,
                    onChanged: (v) => ref
                        .read(pkControllerProvider(drugId).notifier)
                        .update(s.copyWith(simHours: v)),
                  ),
                  _NumField(
                    label: 't½',
                    value: s.halfLifeHours,
                    onChanged: (v) => ref
                        .read(pkControllerProvider(drugId).notifier)
                        .update(s.copyWith(halfLifeHours: v)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _NumField(
                    label: '${t.heightLabel} (${t.heightUnit})',
                    value: state.heightCm,
                    onChanged: (v) => ref
                        .read(pkControllerProvider(drugId).notifier)
                        .setHeight(v),
                  ),
                  _NumField(
                    label: '${t.weightLabel} (${t.weightUnit})',
                    value: state.weightKg,
                    onChanged: (v) => ref
                        .read(pkControllerProvider(drugId).notifier)
                        .setWeight(v),
                  ),
                ],
              ),
            ),
            Card(
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.stopSimTitle,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    if (state.bsa != null)
                      Text(
                        '${t.bsaLabel}: ${state.bsa!.toStringAsFixed(2)} m²'
                        ' · ${state.doseMgPerKg?.toStringAsFixed(2) ?? '—'} mg/kg',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${t.currentPeak}: ${state.curve.peakValue.toStringAsFixed(1)} mg',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${t.minEffectiveConc}: ${threshold.toStringAsFixed(1)} mg',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (state.timeToThresholdHours != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${t.timeToThreshold}: ${state.timeToThresholdHours!.toStringAsFixed(1)} h',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      t.disclaimer,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: PkChart(
                  curve: state.curve,
                  doseMg: s.doseMg,
                  scheduleHours: schedule,
                  thresholdX: state.timeToThresholdHours,
                  thresholdY: threshold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumField extends StatefulWidget {
  const _NumField({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  State<_NumField> createState() => _NumFieldState();
}

class _NumFieldState extends State<_NumField> {
  late final TextEditingController _c =
      TextEditingController(text: widget.value.toStringAsFixed(0));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: TextField(
        controller: _c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: widget.label),
        onSubmitted: (s) {
          final v = double.tryParse(s);
          if (v != null) widget.onChanged(v);
        },
      ),
    );
  }
}
