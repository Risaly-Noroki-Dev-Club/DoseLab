import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/constants.dart';
import '../../core/di/providers.dart';
import '../../shared/constants/strings.dart';

class SettingsState {
  const SettingsState({
    this.locale = const Locale('zh'),
    this.themeMode = ThemeMode.system,
    this.heightCm = AppConstants.defaultHeightCm,
    this.weightKg = AppConstants.defaultWeightKg,
  });
  final Locale locale;
  final ThemeMode themeMode;
  final double heightCm;
  final double weightKg;

  SettingsState copyWith({
    Locale? locale,
    ThemeMode? themeMode,
    double? heightCm,
    double? weightKg,
  }) =>
      SettingsState(
        locale: locale ?? this.locale,
        themeMode: themeMode ?? this.themeMode,
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
      );
}

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    _load();
    return const SettingsState();
  }

  Future<void> _load() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final lang = prefs.getString(StorageKeys.language);
    final theme = prefs.getString(StorageKeys.themeMode);
    final h = prefs.getDouble(StorageKeys.heightCm);
    final w = prefs.getDouble(StorageKeys.weightKg);
    state = SettingsState(
      locale: lang == 'en' ? const Locale('en') : const Locale('zh'),
      themeMode: switch (theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      heightCm: h ?? AppConstants.defaultHeightCm,
      weightKg: w ?? AppConstants.defaultWeightKg,
    );
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(StorageKeys.language, locale.languageCode);
    state = state.copyWith(locale: locale);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(
      StorageKeys.themeMode,
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    );
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setHeight(double cm) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setDouble(StorageKeys.heightCm, cm);
    state = state.copyWith(heightCm: cm);
  }

  Future<void> setWeight(double kg) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setDouble(StorageKeys.weightKg, kg);
    state = state.copyWith(weightKg: kg);
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(
  SettingsController.new,
);
