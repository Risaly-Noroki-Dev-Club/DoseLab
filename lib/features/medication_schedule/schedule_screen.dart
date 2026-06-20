import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../shared/l10n/app_localizations.dart';
import '../../shared/widgets/empty_state.dart';
import 'schedule_controller.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meds = ref.watch(scheduleControllerProvider);
    final t = AppLocalizations.of(context);
    final df = DateFormat('yyyy-MM-dd HH:mm');

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(t.tabSchedule)),
      child: SafeArea(
        child: meds.isEmpty
            ? EmptyState(
                message: t.noMedications,
                icon: CupertinoIcons.capsule,
              )
            : ListView(
                children: [
                  for (var i = 0; i < meds.length; i++) ...[
                    if (i > 0)
                      Container(
                        height: 0.5,
                        color: CupertinoDynamicColor.resolve(
                          CupertinoColors.separator,
                          context,
                        ),
                        margin: const EdgeInsets.only(left: 56),
                      ),
                    _MedRow(
                      med: meds[i],
                      df: df,
                      t: t,
                      ref: ref,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _MedRow extends ConsumerWidget {
  const _MedRow({
    required this.med,
    required this.df,
    required this.t,
    required this.ref,
  });

  final dynamic med;
  final DateFormat df;
  final AppLocalizations t;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final next = med.lastDoseAt?.add(
      Duration(milliseconds: (med.intervalHours * 3600000).toInt()),
    );

    return GestureDetector(
      onTap: () => context.go('/pk/${med.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(CupertinoIcons.chart_bar, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med.brandName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${med.doseMg.toStringAsFixed(0)} mg · '
                    '${t.every} ${med.intervalHours.toStringAsFixed(0)}h'
                    '${next != null ? '  \u2022  ${t.nextDose}${df.format(next)}' : ''}',
                    style: TextStyle(
                      fontSize: 13,
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
            _ActionBtn(
              icon: CupertinoIcons.clock,
              tooltip: t.logDose,
              onTap: () =>
                  ref.read(scheduleControllerProvider.notifier).logDoseNow(
                        med.id,
                      ),
            ),
            _ActionBtn(
              icon: CupertinoIcons.list_bullet,
              tooltip: t.doseHistory,
              onTap: () => context.push('/dose-history/${med.id}'),
            ),
            _ActionBtn(
              icon: CupertinoIcons.pencil,
              tooltip: t.editDrug,
              onTap: () => _showEditDialog(
                context,
                med.id,
                med.brandName,
                med.doseMg,
                med.intervalHours,
                ref,
              ),
            ),
            _ActionBtn(
              icon: med.notify
                  ? CupertinoIcons.bell_fill
                  : CupertinoIcons.bell_slash,
              tooltip: t.notifyEnable,
              onTap: () =>
                  ref.read(scheduleControllerProvider.notifier).toggleNotify(
                        med.id,
                      ),
            ),
            _ActionBtn(
              icon: CupertinoIcons.trash,
              tooltip: t.remove,
              onTap: () =>
                  ref.read(scheduleControllerProvider.notifier).remove(med.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.all(8),
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Icon(icon, size: 20),
    );
  }
}

void _showEditDialog(
  BuildContext ctx,
  String id,
  String name,
  double dose,
  double interval,
  WidgetRef ref,
) {
  final doseC = TextEditingController(text: dose.toStringAsFixed(0));
  final intervalC = TextEditingController(text: interval.toStringAsFixed(0));
  showCupertinoDialog(
    context: ctx,
    builder: (dCtx) => CupertinoAlertDialog(
      title: Text(name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoTextField(
            controller: doseC,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            placeholder: 'Dose (mg)',
          ),
          const SizedBox(height: 10),
          CupertinoTextField(
            controller: intervalC,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            placeholder: 'Interval (h)',
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(dCtx),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          onPressed: () {
            final d = double.tryParse(doseC.text);
            final iv = double.tryParse(intervalC.text);
            if (d != null && d > 0 && iv != null && iv > 0) {
              ref
                  .read(scheduleControllerProvider.notifier)
                  .updateDrug(id, doseMg: d, intervalHours: iv);
            }
            Navigator.pop(dCtx);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
