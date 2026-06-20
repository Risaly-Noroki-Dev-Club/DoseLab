import 'package:flutter/cupertino.dart';
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

    return CupertinoPageScaffold(
      navigationBar:
          CupertinoNavigationBar(middle: Text(t.interactionsTitle)),
      child: SafeArea(
        child: Column(
          children: [
            const DisclaimerBanner(dense: true),
            Expanded(
              child: hits.isEmpty
                  ? EmptyState(
                      message: t.interactionsNone,
                      icon: CupertinoIcons.checkmark_circle,
                    )
                  : ListView(
                      children: [
                        for (var i = 0; i < hits.length; i++) ...[
                          if (i > 0)
                            Container(
                              height: 0.5,
                              color: CupertinoDynamicColor.resolve(
                                CupertinoColors.separator,
                                context,
                              ),
                              margin: const EdgeInsets.only(left: 56),
                            ),
                          _InteractionRow(hit: hits[i]),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractionRow extends StatelessWidget {
  const _InteractionRow({required this.hit});
  final _Hit hit;

  @override
  Widget build(BuildContext context) {
    final summary =
        Localizations.localeOf(context).languageCode == 'zh'
            ? hit.rule.summaryZh
            : hit.rule.summary;
    final severityColor = switch (hit.rule.severity) {
      InteractionSeverity.caution => CupertinoColors.systemYellow,
      InteractionSeverity.warning => CupertinoColors.systemOrange,
      InteractionSeverity.severe => CupertinoColors.systemRed,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 24,
              color: severityColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${hit.a}  \u2194  ${hit.b}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  summary,
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
