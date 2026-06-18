import 'package:flutter/material.dart';
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

    return Scaffold(
      appBar: AppBar(title: Text(t.tabSchedule)),
      body: meds.isEmpty
          ? EmptyState(
              message: t.noMedications,
              icon: Icons.medication_outlined,
            )
          : ListView.separated(
              itemCount: meds.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final m = meds[i];
                final next = m.lastDoseAt?.add(
                  Duration(
                    milliseconds: (m.intervalHours * 3600000).toInt(),
                  ),
                );
                return ListTile(
                  title: Text(m.brandName),
                  subtitle: Text(
                    '${m.doseMg.toStringAsFixed(0)} mg · '
                    '${t.every} ${m.intervalHours.toStringAsFixed(0)}h'
                    '${next != null ? '  •  ${t.nextDose}${df.format(next)}' : ''}',
                  ),
                  onTap: () => context.go('/pk/${m.id}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: t.logDose,
                        icon: const Icon(Icons.history_outlined),
                        onPressed: () => ref
                            .read(scheduleControllerProvider.notifier)
                            .logDoseNow(m.id),
                      ),
                      IconButton(
                        tooltip: t.doseHistory,
                        icon: const Icon(Icons.list_alt),
                        onPressed: () => context.push('/dose-history/${m.id}'),
                      ),
                      IconButton(
                        tooltip: t.editDrug,
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showEditDialog(
                          ctx,
                          m.id,
                          m.brandName,
                          m.doseMg,
                          m.intervalHours,
                          ref,
                        ),
                      ),
                      IconButton(
                        tooltip: t.notifyEnable,
                        icon: Icon(
                          m.notify
                              ? Icons.notifications_active
                              : Icons.notifications_off_outlined,
                        ),
                        onPressed: () => ref
                            .read(scheduleControllerProvider.notifier)
                            .toggleNotify(m.id),
                      ),
                      IconButton(
                        tooltip: t.remove,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => ref
                            .read(scheduleControllerProvider.notifier)
                            .remove(m.id),
                      ),
                    ],
                  ),
                );
              },
            ),
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
  showDialog(
    context: ctx,
    builder: (dCtx) => AlertDialog(
      title: Text(name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: doseC,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Dose (mg)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: intervalC,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Interval (h)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dCtx),
          child: const Text('Cancel'),
        ),
        FilledButton(
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
