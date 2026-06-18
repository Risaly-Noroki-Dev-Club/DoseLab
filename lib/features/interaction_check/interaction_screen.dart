import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/l10n/app_localizations.dart';
import '../../shared/widgets/disclaimer_banner.dart';
import '../../shared/widgets/empty_state.dart';
import '../medication_schedule/schedule_controller.dart';
import 'interaction_rules.dart';

class InteractionScreen extends ConsumerWidget {
  const InteractionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meds = ref.watch(scheduleControllerProvider);
    final t = AppLocalizations.of(context);

    final hits = <_Hit>[];
    for (var i = 0; i < meds.length; i++) {
      for (var j = i + 1; j < meds.length; j++) {
        final a = '${meds[i].brandName} ${meds[i].genericName ?? ''}';
        final b = '${meds[j].brandName} ${meds[j].genericName ?? ''}';
        for (final r in interactionRules) {
          if (r.matches(a, b)) {
            hits.add(_Hit(meds[i].brandName, meds[j].brandName, r));
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.interactionsTitle)),
      body: Column(
        children: [
          const DisclaimerBanner(dense: true),
          Expanded(
            child: hits.isEmpty
                ? EmptyState(
                    message: t.interactionsNone,
                    icon: Icons.check_circle_outline,
                  )
                : ListView.separated(
                    itemCount: hits.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final h = hits[i];
                      final summary =
                          Localizations.localeOf(context).languageCode == 'zh'
                              ? h.rule.summaryZh
                              : h.rule.summary;
                      return ListTile(
                        leading: Icon(
                          Icons.warning_amber_outlined,
                          color: switch (h.rule.severity) {
                            InteractionSeverity.caution => Colors.amber,
                            InteractionSeverity.warning => Colors.orange,
                            InteractionSeverity.severe => Colors.red,
                          },
                        ),
                        title: Text('${h.a}  ↔  ${h.b}'),
                        subtitle: Text(summary),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _Hit {
  _Hit(this.a, this.b, this.rule);
  final String a;
  final String b;
  final InteractionRule rule;
}
