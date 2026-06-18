import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/l10n/app_localizations.dart';
import '../auth/auth_controller.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final s = ref.watch(settingsControllerProvider);
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.settingsTitle)),
      body: ListView(
        children: [
          ListTile(
            title: Text(t.settingsLanguage),
            trailing: DropdownButton<Locale>(
              value: s.locale,
              items: const [
                DropdownMenuItem(value: Locale('en'), child: Text('English')),
                DropdownMenuItem(value: Locale('zh'), child: Text('中文')),
              ],
              onChanged: (v) {
                if (v != null) {
                  ref.read(settingsControllerProvider.notifier).setLocale(v);
                }
              },
            ),
          ),
          ListTile(
            title: Text(t.settingsTheme),
            trailing: DropdownButton<ThemeMode>(
              value: s.themeMode,
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(t.themeSystem),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(t.themeLight),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(t.themeDark),
                ),
              ],
              onChanged: (v) {
                if (v != null) {
                  ref.read(settingsControllerProvider.notifier).setThemeMode(v);
                }
              },
            ),
          ),
          SwitchListTile(
            title: Text(t.appLock),
            subtitle: Text(t.appLockSubtitle),
            value: auth.requiresUnlock,
            onChanged: (v) =>
                ref.read(authControllerProvider.notifier).setLockEnabled(v),
          ),
          ListTile(
            title: Text(t.settingsWebDav),
            subtitle: Text(t.webDavSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: WebDAV credentials form.
            },
          ),
          if (auth.isAuthenticated)
            ListTile(
              title: Text(t.signOut),
              leading: const Icon(Icons.logout),
              onTap: () => ref.read(authControllerProvider.notifier).signOut(),
            ),
        ],
      ),
    );
  }
}
