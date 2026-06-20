import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeMode;
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

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(t.settingsTitle)),
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 12),
            _SettingsRow(
              label: t.settingsLanguage,
              value: s.locale.languageCode == 'zh' ? '中文' : 'English',
              onTap: () => _showLanguagePicker(context, ref, s),
            ),
            _Separator(),
            _SettingsRow(
              label: t.settingsTheme,
              value: switch (s.themeMode) {
                ThemeMode.system => t.themeSystem,
                ThemeMode.light => t.themeLight,
                ThemeMode.dark => t.themeDark,
              },
              onTap: () => _showThemePicker(context, ref, s, t),
            ),
            _Separator(),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.appLock),
                        Text(
                          t.appLockSubtitle,
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
                  CupertinoSwitch(
                    value: auth.requiresUnlock,
                    onChanged: (v) => ref
                        .read(authControllerProvider.notifier)
                        .setLockEnabled(v),
                  ),
                ],
              ),
            ),
            _Separator(),
            _SettingsRow(
              label: t.settingsWebDav,
              value: t.webDavSubtitle,
              showArrow: true,
              onTap: () => _showWebDavDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.leading,
    this.showArrow = false,
    this.isDestructive = false,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final IconData? leading;
  final bool showArrow;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        child: Row(
          children: [
            if (leading != null) ...[
              Icon(
                leading,
                size: 22,
                color: isDestructive ? CupertinoColors.systemRed : null,
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isDestructive ? CupertinoColors.systemRed : null,
                ),
              ),
            ),
            if (value.isNotEmpty)
              Text(
                value,
                style: TextStyle(
                  color: CupertinoTheme.of(context)
                          .textTheme
                          .textStyle
                          .color ??
                      CupertinoColors.secondaryLabel,
                ),
              ),
            if (showArrow) ...[
              const SizedBox(width: 4),
              const Icon(
                CupertinoIcons.chevron_right,
                size: 18,
                color: CupertinoColors.tertiaryLabel,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      color: CupertinoDynamicColor.resolve(
        CupertinoColors.separator,
        context,
      ),
      margin: const EdgeInsets.only(left: 20),
    );
  }
}

void _showLanguagePicker(
  BuildContext context,
  WidgetRef ref,
  SettingsState s,
) {
  showCupertinoModalPopup(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: Text(AppLocalizations.of(context).settingsLanguage),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () {
            ref
                .read(settingsControllerProvider.notifier)
                .setLocale(const Locale('en'));
            Navigator.pop(ctx);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('English'),
              if (s.locale.languageCode == 'en')
                const Icon(CupertinoIcons.checkmark_alt, size: 20),
            ],
          ),
        ),
        CupertinoActionSheetAction(
          onPressed: () {
            ref
                .read(settingsControllerProvider.notifier)
                .setLocale(const Locale('zh'));
            Navigator.pop(ctx);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('中文'),
              if (s.locale.languageCode == 'zh')
                const Icon(CupertinoIcons.checkmark_alt, size: 20),
            ],
          ),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.pop(ctx),
        child: const Text('Cancel'),
      ),
    ),
  );
}

void _showThemePicker(
  BuildContext context,
  WidgetRef ref,
  SettingsState s,
  AppLocalizations t,
) {
  showCupertinoModalPopup(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: Text(t.settingsTheme),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () {
            ref
                .read(settingsControllerProvider.notifier)
                .setThemeMode(ThemeMode.system);
            Navigator.pop(ctx);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.themeSystem),
              if (s.themeMode == ThemeMode.system)
                const Icon(CupertinoIcons.checkmark_alt, size: 20),
            ],
          ),
        ),
        CupertinoActionSheetAction(
          onPressed: () {
            ref
                .read(settingsControllerProvider.notifier)
                .setThemeMode(ThemeMode.light);
            Navigator.pop(ctx);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.themeLight),
              if (s.themeMode == ThemeMode.light)
                const Icon(CupertinoIcons.checkmark_alt, size: 20),
            ],
          ),
        ),
        CupertinoActionSheetAction(
          onPressed: () {
            ref
                .read(settingsControllerProvider.notifier)
                .setThemeMode(ThemeMode.dark);
            Navigator.pop(ctx);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.themeDark),
              if (s.themeMode == ThemeMode.dark)
                const Icon(CupertinoIcons.checkmark_alt, size: 20),
            ],
          ),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.pop(ctx),
        child: const Text('Cancel'),
      ),
    ),
  );
}

void _showWebDavDialog(BuildContext context, WidgetRef ref) {
  final urlC = TextEditingController();
  final userC = TextEditingController();
  final passC = TextEditingController();

  final storage = ref.read(secureStorageProvider);
  storage.read(key: StorageKeys.webdavUrl).then((v) {
    if (v != null) urlC.text = v;
  });
  storage.read(key: StorageKeys.webdavUser).then((v) {
    if (v != null) userC.text = v;
  });

  showCupertinoDialog(
    context: context,
    builder: (dCtx) => CupertinoAlertDialog(
      title: const Text('WebDAV'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoTextField(
            controller: urlC,
            placeholder: 'URL',
            prefix: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(CupertinoIcons.link, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          CupertinoTextField(
            controller: userC,
            placeholder: 'User',
            prefix: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(CupertinoIcons.person, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          CupertinoTextField(
            controller: passC,
            obscureText: true,
            placeholder: 'Password',
            prefix: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(CupertinoIcons.lock, size: 20),
            ),
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
              await storage.write(
                key: StorageKeys.webdavPassword,
                value: pass,
              );
            }
            if (dCtx.mounted) Navigator.pop(dCtx);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
