import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../shared/extensions/duration_x.dart';
import '../../shared/l10n/app_localizations.dart';
import '../../shared/widgets/disclaimer_banner.dart';
import '../../shared/widgets/empty_state.dart';
import '../medication_schedule/schedule_controller.dart';

/// Home screen. Cards across the top mirror the original PWA's
/// horizontal "my meds" strip; below that is a quick-jump grid to
/// the feature screens.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meds = ref.watch(scheduleControllerProvider);
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.appTitle),
        actions: [
          IconButton(
            tooltip: t.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('${Routes.dashboard}settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          const DisclaimerBanner(dense: true),
          SizedBox(
            height: 130,
            child: meds.isEmpty
                ? EmptyState(
                    message: t.noMedications,
                    icon: Icons.medication_outlined,
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    itemCount: meds.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final m = meds[i];
                      final next = m.lastDoseAt?.add(
                        Duration(
                          milliseconds: (m.intervalHours * 3600000).toInt(),
                        ),
                      );
                      final remaining = next?.difference(DateTime.now());
                      return TweenAnimationBuilder<double>(
                        key: ValueKey(m.id),
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 360 + i * 70),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value.clamp(0, 1),
                            child: Transform.translate(
                              offset: Offset(24 * (1 - value), 0),
                              child: Transform.scale(
                                scale: 0.94 + value * 0.06,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: SizedBox(
                          width: 180,
                          child: Card(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => context.go('/pk/${m.id}'),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m.brandName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${m.doseMg.toStringAsFixed(0)} mg · '
                                      '${m.intervalHours.toStringAsFixed(0)}h',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      t.tapForPk,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                    if (remaining != null)
                                      Text(
                                        '${t.nextDose}${remaining.formatShort()}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: remaining.isNegative
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .error
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(12),
              childAspectRatio: 1.4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _AnimatedTile(
                  delay: 0,
                  icon: Icons.search,
                  label: t.tabSearch,
                  onTap: () => context.push('${Routes.dashboard}search'),
                ),
                _AnimatedTile(
                  delay: 80,
                  icon: Icons.calendar_today_outlined,
                  label: t.tabSchedule,
                  onTap: () => context.push('${Routes.dashboard}schedule'),
                ),
                _AnimatedTile(
                  delay: 160,
                  icon: Icons.warning_amber_outlined,
                  label: t.tabInteractions,
                  onTap: () => context.push('${Routes.dashboard}interactions'),
                ),
                _AnimatedTile(
                  delay: 240,
                  icon: Icons.picture_as_pdf_outlined,
                  label: t.reportTitle,
                  onTap: () => context.push('${Routes.dashboard}report'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedTile extends StatelessWidget {
  const _AnimatedTile({
    required this.delay,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final int delay;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + delay),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Transform.scale(
              scale: 0.92 + value * 0.08,
              child: child,
            ),
          ),
        );
      },
      child: _Tile(icon: icon, label: label, onTap: onTap),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
