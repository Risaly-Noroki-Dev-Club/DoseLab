import 'package:flutter/cupertino.dart';
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
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text(t.pkData)),
        child: const SafeArea(child: LoadingIndicator()),
      );
    }
    final s = state.settings;
    final schedule = [
      for (var x = 0.0; x < s.simHours; x += s.intervalHours) x,
    ];
    final threshold = s.doseMg * AppConstants.dangerThresholdMultiplier;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(t.pkData)),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DisclaimerBanner(dense: true),
              const SizedBox(height: 16),

              _SectionHeader(title: t.pkParams),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  _NumField(
                    label: t.dose,
                    suffix: 'mg',
                    value: s.doseMg,
                    onChanged: (v) => ref
                        .read(pkControllerProvider(drugId).notifier)
                        .update(s.copyWith(doseMg: v)),
                  ),
                  _NumField(
                    label: t.every,
                    suffix: 'h',
                    value: s.intervalHours,
                    onChanged: (v) => ref
                        .read(pkControllerProvider(drugId).notifier)
                        .update(s.copyWith(intervalHours: v)),
                  ),
                  _NumField(
                    label: 'sim',
                    suffix: 'h',
                    value: s.simHours,
                    onChanged: (v) => ref
                        .read(pkControllerProvider(drugId).notifier)
                        .update(s.copyWith(simHours: v)),
                  ),
                  _NumField(
                    label: 't\u00bd',
                    suffix: 'h',
                    value: s.halfLifeHours,
                    onChanged: (v) => ref
                        .read(pkControllerProvider(drugId).notifier)
                        .update(s.copyWith(halfLifeHours: v)),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _SectionHeader(title: t.bodyData),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  _NumField(
                    label: t.heightLabel,
                    suffix: t.heightUnit,
                    value: state.heightCm,
                    onChanged: (v) => ref
                        .read(pkControllerProvider(drugId).notifier)
                        .setHeight(v),
                  ),
                  _NumField(
                    label: t.weightLabel,
                    suffix: t.weightUnit,
                    value: state.weightKg,
                    onChanged: (v) => ref
                        .read(pkControllerProvider(drugId).notifier)
                        .setWeight(v),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _SectionHeader(title: t.stopSimTitle),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: CupertinoDynamicColor.resolve(
                    CupertinoColors.secondarySystemGroupedBackground,
                    context,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.bsa != null)
                      Text(
                        '${t.bsaLabel}: ${state.bsa!.toStringAsFixed(2)} m\u00b2'
                        ' \u00b7 ${state.doseMgPerKg?.toStringAsFixed(2) ?? '\u2014'} mg/kg',
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoTheme.of(context)
                                  .textTheme
                                  .textStyle
                                  .color ??
                              CupertinoColors.secondaryLabel,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${t.currentPeak}: ${state.curve.peakValue.toStringAsFixed(1)} mg',
                      style: TextStyle(
                        fontSize: 13,
                        color: CupertinoTheme.of(context)
                                .textTheme
                                .textStyle
                                .color ??
                            CupertinoColors.secondaryLabel,
                      ),
                    ),
                    Text(
                      '${t.minEffectiveConc}: ${threshold.toStringAsFixed(1)} mg',
                      style: TextStyle(
                        fontSize: 13,
                        color: CupertinoTheme.of(context)
                                .textTheme
                                .textStyle
                                .color ??
                            CupertinoColors.secondaryLabel,
                      ),
                    ),
                    if (state.timeToThresholdHours != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            CupertinoIcons.clock,
                            size: 18,
                            color: CupertinoColors.systemOrange,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${t.timeToThreshold}: ${state.timeToThresholdHours!.toStringAsFixed(1)} h',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      t.disclaimer,
                      style: TextStyle(
                        fontSize: 10,
                        color: CupertinoTheme.of(context)
                                .textTheme
                                .textStyle
                                .color ??
                            CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                height: 320,
                child: PkChart(
                  curve: state.curve,
                  doseMg: s.doseMg,
                  scheduleHours: schedule,
                  thresholdX: state.timeToThresholdHours,
                  thresholdY: threshold,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _NumField extends StatefulWidget {
  const _NumField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.suffix,
  });
  final String label;
  final double value;
  final String? suffix;
  final ValueChanged<double> onChanged;

  @override
  State<_NumField> createState() => _NumFieldState();
}

class _NumFieldState extends State<_NumField> {
  late TextEditingController _c;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.value.toStringAsFixed(0));
  }

  @override
  void didUpdateWidget(covariant _NumField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _c.text = widget.value.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: CupertinoTextField(
        controller: _c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        placeholder: widget.label,
        suffix: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Text(
            widget.suffix ?? '',
            style: TextStyle(
              color: CupertinoTheme.of(context).textTheme.textStyle.color ??
                  CupertinoColors.secondaryLabel,
            ),
          ),
        ),
        onSubmitted: (s) {
          final v = double.tryParse(s);
          if (v != null) widget.onChanged(v);
        },
      ),
    );
  }
}
