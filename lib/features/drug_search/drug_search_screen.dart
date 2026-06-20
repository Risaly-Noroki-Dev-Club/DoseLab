import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

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

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(t.tabSearch),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoSearchTextField(
                      controller: _controller,
                      placeholder: t.searchHint,
                      onSubmitted: (_) => _go(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton.filled(
                    onPressed: _controller.text.trim().isEmpty
                        ? null
                        : _go,
                    child: Text(t.tabSearch),
                  ),
                ],
              ),
            ),
            const DisclaimerBanner(dense: true),
            Expanded(
              child: state.when(
                data: (s) => switch (s) {
                  SearchIdle() => EmptyState(
                      message: t.searchHint,
                      icon: CupertinoIcons.search,
                    ),
                  SearchLoading() => LoadingIndicator(message: t.searching),
                  SearchUnmappedChinese() => EmptyState(
                      message: t.unmappedChinese,
                      icon: CupertinoIcons.globe,
                    ),
                  SearchError(failure: final f) => EmptyState(
                      message: f.toString(),
                      icon: CupertinoIcons.exclamationmark_circle,
                    ),
                  SearchSuccess(envelope: final env) =>
                    _ResultsList(env: env),
                },
                loading: () => LoadingIndicator(message: t.searching),
                error: (e, _) => EmptyState(
                  message: '$e',
                  icon: CupertinoIcons.exclamationmark_circle,
                ),
              ),
            ),
          ],
        ),
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
      return EmptyState(
        message: t.searchEmpty,
        icon: CupertinoIcons.tray,
      );
    }
    return ListView(
      children: [
        for (var i = 0; i < widget.env.results.length; i++) ...[
          if (i > 0)
            Container(
              height: 0.5,
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.separator,
                context,
              ),
              margin: const EdgeInsets.only(left: 56),
            ),
          _buildItem(context, t, widget.env.results[i]),
        ],
      ],
    );
  }

  Widget _buildItem(BuildContext context, AppLocalizations t, Map r) {
    final brand = (r['brand_name'] ?? r['generic_name'] ?? '').toString();
    final generic = (r['generic_name'] ?? '').toString();
    final ndc = (r['product_ndc'] ?? '').toString();
    final ingredients = (r['active_ingredients'] as List?) ?? const [];
    final strength = ingredients
        .map((a) => (a as Map)['strength'])
        .where((s) => s != null)
        .join(', ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brand,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (generic.isNotEmpty) generic,
                    if (strength.isNotEmpty) strength,
                    if (ndc.isNotEmpty) 'NDC $ndc',
                  ].join(' · '),
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        CupertinoTheme.of(context).textTheme.textStyle.color ??
                            CupertinoColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: _adding == ndc
                ? const CupertinoActivityIndicator(
                    key: ValueKey('adding'),
                    radius: 10,
                  )
                : _added.contains(ndc)
                    ? Text(
                        t.added,
                        key: const ValueKey('added'),
                        style: TextStyle(
                          fontSize: 15,
                          color: CupertinoTheme.of(context).primaryColor,
                        ),
                      )
                    : CupertinoButton(
                        key: const ValueKey('add-btn'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        color: CupertinoTheme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(8),
                        minimumSize: Size.zero,
                        onPressed: () =>
                            _showAddDialog(context, ndc, brand, generic, strength),
                        child: Text(
                          t.add,
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
          ),
        ],
      ),
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
    showCupertinoDialog(
      context: ctx,
      builder: (dCtx) => CupertinoAlertDialog(
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
                    color: CupertinoTheme.of(dCtx)
                            .textTheme
                            .textStyle
                            .color ??
                        CupertinoColors.secondaryLabel,
                  ),
                ),
              ),
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
            onPressed: () async {
              final dose = double.tryParse(doseC.text) ?? 50;
              final interval = double.tryParse(intervalC.text) ?? 24;
              Navigator.pop(dCtx);
              setState(() => _adding = ndc);
              try {
                await ref
                    .read(scheduleControllerProvider.notifier)
                    .addFromFda(
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
              } catch (e) {
                if (!ctx.mounted) return;
                setState(() => _adding = null);
                if (ctx.mounted) {
                  showCupertinoDialog(
                    context: ctx,
                    builder: (errCtx) => CupertinoAlertDialog(
                      title: const Text('Error'),
                      content: Text('$e'),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () => Navigator.pop(errCtx),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
