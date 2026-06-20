import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../core/di/providers.dart';
import '../../core/storage/local_db.dart';
import '../../shared/l10n/app_localizations.dart';
import '../medication_schedule/schedule_controller.dart';
import 'report_builder.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _builder = ReportBuilder();
  bool _busy = false;

  Future<void> _shareReport() async {
    setState(() => _busy = true);
    try {
      final l10n = AppLocalizations.of(context);
      final db = ref.read(localDbProvider);
      final drugs = ref.read(scheduleControllerProvider);
      final logs = <String, List<DoseLog>>{};
      for (final d in drugs) {
        logs[d.id] = await db.doseLogsFor(d.id);
      }
      final doc = await _builder.build(
        drugs: drugs,
        logsByDrug: logs,
        l10n: l10n,
      );
      final bytes = await doc.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'doselab-report.pdf',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(t.reportTitle)),
      child: SafeArea(
        child: Center(
          child: _busy
              ? const CupertinoActivityIndicator(radius: 18)
              : CupertinoButton.filled(
                  onPressed: _shareReport,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.doc_text),
                      const SizedBox(width: 8),
                      Text(t.reportTitle),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
