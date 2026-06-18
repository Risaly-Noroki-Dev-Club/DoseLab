import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../shared/constants/strings.dart';
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
              _showWebDavDialog(context, ref);
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

void _showWebDavDialog(BuildContext context, WidgetRef ref) {
  final urlC = TextEditingController();
  final userC = TextEditingController();
  final passC = TextEditingController();

  // Pre-fill from secure storage
  final storage = ref.read(secureStorageProvider);
  storage.read(key: StorageKeys.webdavUrl).then((v) {
    if (v != null) urlC.text = v;
  });
  storage.read(key: StorageKeys.webdavUser).then((v) {
    if (v != null) userC.text = v;
  });

  showDialog(
    context: context,
    builder: (dCtx) => AlertDialog(
      title: const Text('WebDAV'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: urlC,
            decoration: const InputDecoration(
              labelText: 'URL',
              hintText: 'https://your-server.com/remote.php/dav',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: userC,
            decoration: const InputDecoration(labelText: 'User'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: passC,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
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
            final url = urlC.text.trim();
            final user = userC.text.trim();
            final pass = passC.text.trim();
            if (url.isNotEmpty) {
              await storage.write(key: StorageKeys.webdavUrl, value: url);
            }
            if (user.isNotEmpty) {
              await storage.write(key: StorageKeys.webdavUser, value: user);
            }
            if (pass.isNotEmpty) {
              await storage.write(key: StorageKeys.webdavPassword, value: pass);
            }
            if (dCtx.mounted) Navigator.pop(dCtx);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
