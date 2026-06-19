import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../shared/l10n/app_localizations.dart';
import '../../shared/widgets/disclaimer_banner.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../medication_schedule/schedule_controller.dart';
import 'drug_search_controller.dart';
import 'fda_envelope.dart';

class DrugSearchScreen extends ConsumerStatefulWidget {
  const DrugSearchScreen({super.key});

  @override
  ConsumerState<DrugSearchScreen> createState() => _DrugSearchScreenState();
}

class _DrugSearchScreenState extends ConsumerState<DrugSearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go() {
    ref.read(drugSearchControllerProvider.notifier).search(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(drugSearchControllerProvider);
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.tabSearch)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: t.searchHint,
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _go(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _go, child: Text(t.tabSearch)),
              ],
            ),
          ),
          const DisclaimerBanner(dense: true),
          Expanded(
            child: state.when(
              data: (s) => switch (s) {
                SearchIdle() => EmptyState(
                    message: t.searchHint,
                    icon: Icons.search,
                  ),
                SearchLoading() => LoadingIndicator(message: t.searching),
                SearchUnmappedChinese() => EmptyState(
                    message: t.unmappedChinese,
                    icon: Icons.translate,
                  ),
                SearchError(failure: final f) => EmptyState(
                    message: f.toString(),
                    icon: Icons.error_outline,
                  ),
                SearchSuccess(envelope: final env) => _ResultsList(env: env),
              },
              loading: () => LoadingIndicator(message: t.searching),
              error: (e, _) => EmptyState(
                message: '$e',
                icon: Icons.error_outline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsList extends ConsumerStatefulWidget {
  const _ResultsList({required this.env});
  final FdaEnvelope env;

  @override
  ConsumerState<_ResultsList> createState() => _ResultsListState();
}

class _ResultsListState extends ConsumerState<_ResultsList> {
  final _added = <String>{};
  String? _adding;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (widget.env.results.isEmpty) {
      return EmptyState(message: t.searchEmpty, icon: Icons.inbox_outlined);
    }
    return ListView.separated(
      itemCount: widget.env.results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final r = widget.env.results[i];
        final brand = (r['brand_name'] ?? r['generic_name'] ?? '').toString();
        final generic = (r['generic_name'] ?? '').toString();
        final ndc = (r['product_ndc'] ?? '').toString();
        final ingredients = (r['active_ingredients'] as List?) ?? const [];
        final strength = ingredients
            .map((a) => (a as Map)['strength'])
            .where((s) => s != null)
            .join(', ');
        return ListTile(
          title: Text(brand),
          subtitle: Text(
            [
              if (generic.isNotEmpty) generic,
              if (strength.isNotEmpty) strength,
              if (ndc.isNotEmpty) 'NDC $ndc',
            ].join(' · '),
          ),
          trailing: FilledButton.tonal(
            onPressed: _adding != null || _added.contains(ndc)
                ? null
                : () => _showAddDialog(ctx, ndc, brand, generic, strength),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeInCubic,
              child: _adding == ndc
                  ? const SizedBox(
                      key: ValueKey('adding'),
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _added.contains(ndc) ? t.added : t.add,
                      key: ValueKey(_added.contains(ndc)),
                    ),
            ),
          ),
        );
      },
    );
  }

  void _showAddDialog(
    BuildContext ctx,
    String ndc,
    String brand,
    String generic,
    String strength,
  ) {
    final doseC = TextEditingController(text: '50');
    final intervalC = TextEditingController(text: '24');
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: Text(brand),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (generic.isNotEmpty || strength.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  [
                    if (generic.isNotEmpty) generic,
                    if (strength.isNotEmpty) strength,
                  ].join(' · '),
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(dCtx).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
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
            onPressed: () async {
              final dose = double.tryParse(doseC.text) ?? 50;
              final interval = double.tryParse(intervalC.text) ?? 24;
              Navigator.pop(dCtx);
              setState(() => _adding = ndc);
              try {
                await ref.read(scheduleControllerProvider.notifier).addFromFda(
                      productNdc: ndc,
                      brandName: brand.isEmpty ? generic : brand,
                      genericName: generic,
                      strength: strength,
                      doseMg: dose,
                      intervalHours: interval,
                    );
                if (!ctx.mounted) return;
                setState(() {
                  _added.add(ndc);
                  _adding = null;
                });
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(ctx).added),
                  ),
                );
                ctx.go(Routes.dashboard);
              } catch (e) {
                if (!ctx.mounted) return;
                setState(() => _adding = null);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('$e')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
