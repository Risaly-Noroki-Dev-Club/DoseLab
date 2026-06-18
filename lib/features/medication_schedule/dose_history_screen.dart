import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/di/providers.dart';
import '../../core/storage/local_db.dart';
import '../../shared/l10n/app_localizations.dart';

class DoseHistoryScreen extends ConsumerStatefulWidget {
  const DoseHistoryScreen({super.key, required this.drugId});
  final String drugId;

  @override
  ConsumerState<DoseHistoryScreen> createState() => _DoseHistoryScreenState();
}

class _DoseHistoryScreenState extends ConsumerState<DoseHistoryScreen> {
  List<DoseLog> _logs = const [];
  Drug? _drug;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(localDbProvider);
    final drugs = await db.getAllDrugs();
    _drug = drugs.where((d) => d.id == widget.drugId).firstOrNull;
    final logs = await db.doseLogsFor(widget.drugId);
    logs.sort((a, b) => b.takenAt.compareTo(a.takenAt)); // newest first
    if (mounted) {
      setState(() {
        _logs = logs;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final df = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(_drug?.brandName ?? t.logDose),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(child: Text(t.noDoseHistory))
              : ListView.separated(
                  itemCount: _logs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final l = _logs[i];
                    return ListTile(
                      title: Text(
                        '${l.doseMg.toStringAsFixed(0)} mg',
                      ),
                      subtitle: Text(df.format(l.takenAt)),
                      trailing: l.note != null && l.note!.isNotEmpty
                          ? Text(
                              l.note!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            )
                          : null,
                    );
                  },
                ),
    );
  }
}
