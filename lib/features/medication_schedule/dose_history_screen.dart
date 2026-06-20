import 'package:flutter/cupertino.dart';
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
    logs.sort((a, b) => b.takenAt.compareTo(a.takenAt));
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

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_drug?.brandName ?? t.logDose),
      ),
      child: SafeArea(
        child: _loading
            ? const Center(child: CupertinoActivityIndicator())
            : _logs.isEmpty
                ? Center(child: Text(t.noDoseHistory))
                : ListView(
                    children: [
                      for (var i = 0; i < _logs.length; i++) ...[
                        if (i > 0)
                          Container(
                            height: 0.5,
                            color: CupertinoDynamicColor.resolve(
                              CupertinoColors.separator,
                              context,
                            ),
                            margin: const EdgeInsets.only(left: 16),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_logs[i].doseMg.toStringAsFixed(0)} mg',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      df.format(_logs[i].takenAt),
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
                              if (_logs[i].note != null &&
                                  _logs[i].note!.isNotEmpty)
                                Text(
                                  _logs[i].note!,
                                  style: TextStyle(
                                    fontSize: 12,
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
                      ],
                    ],
                  ),
      ),
    );
  }
}
