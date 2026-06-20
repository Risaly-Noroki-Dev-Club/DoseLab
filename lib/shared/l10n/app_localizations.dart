import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Hand-rolled localization. Kept dependency-free so the project
/// compiles before running `flutter gen-l10n`; if/when ARB files
/// are added, this class can be replaced by the generated one
/// without changing call sites.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('zh')];

  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  String get _lang => locale.languageCode == 'zh' ? 'zh' : 'en';
  String _s(String en, String zh) => _lang == 'zh' ? zh : en;

  String get appTitle => 'DoseLab';
  String get disclaimer => _s(
        'Reference only — not medical advice',
        '仅供参考 — 非医疗建议',
      );

  String get searchHint => _s(
        'Search medications (e.g. sertraline, ibuprofen)...',
        '搜索药品（如 sertraline, ibuprofen）…',
      );
  String get searchEmpty => _s('No results found', '未找到结果');
  String get searching => _s('Searching…', '搜索中…');
  String get unmappedChinese => _s(
        'No English mapping for this Chinese drug name yet',
        '暂未收录这个中文药名的英文映射',
      );

  String get tabDashboard => _s('Home', '主页');
  String get tabSearch => _s('Search', '搜索');
  String get tabSchedule => _s('Schedule', '计划');
  String get tabInteractions => _s('Check', '检查');
  String get tabSettings => _s('Settings', '设置');

  String get unlock => _s('Unlock', '解锁');
  String get unlockTitle => _s('Unlock DoseLab', '解锁 DoseLab');

  String get myMedications => _s('My Medications', '我的药品');
  String get noMedications => _s(
        'Search for a medication and tap Add',
        '搜索药品后点击添加',
      );
  String get add => _s('Add', '添加');
  String get added => _s('Added', '已添加');
  String get editDrug => _s('Edit', '编辑');
  String get remove => _s('Remove', '移除');
  String get logDose => _s('Log dose now', '记录此刻用药');
  String get noDoseHistory => _s('No dose history yet', '暂无服药记录');
  String get doseHistory => _s('History', '记录');

  String get halfLife => _s('Half-life', '半衰期');
  String get tmax => _s('Tmax', '达峰时间');
  String get steadyState => _s('Steady state', '达稳态');
  String get pkData => _s('PK data', 'PK 数据');
  String get pkParams => _s('PK parameters', '药物参数');
  String get bodyData => _s('Body data', '身体数据');
  String get tapForPk => _s('Tap for PK curve', '点击查看曲线');
  String get dose => _s('Dose', '剂量');
  String get every => _s('every', '每');
  String get hours => _s('hours', '小时');

  String get therapeutic => _s('therapeutic window', '治疗窗');
  String get warning => _s('warning zone', '警戒区');
  String get toxic => _s('toxic zone', '中毒区');
  String get peak => _s('peak', '峰浓度');

  String get nextDose => _s('Next: ', '下次: ');
  String get overdue => _s('OVERDUE', '已超时');

  String get notifyEnable => _s(
        'Enable notifications for medication reminders',
        '开启通知以提醒用药',
      );

  String get interactionsTitle => _s('Interaction check', '相互作用检查');
  String get interactionsNone => _s('No interactions detected', '未检测到相互作用');
  String get reportTitle => _s('Generate report', '生成报告');
  String get reportHeader => _s('DoseLab Report', 'DoseLab 报告');
  String get reportGenerated => _s('Generated', '生成时间');
  String get reportMedications => _s('Medications', '药品');
  String get reportNoMedications => _s(
        'No medications recorded.',
        '暂无药品记录。',
      );
  String get reportDoseLog => _s(
        'Dose log (last 30 days)',
        '服药记录（最近 30 天）',
      );
  List<String> get reportMedicationHeaders => _lang == 'zh'
      ? const ['商品名', '通用名', '剂量', '间隔']
      : const ['Brand', 'Generic', 'Dose', 'Interval'];
  List<String> get reportDoseLogHeaders => _lang == 'zh'
      ? const ['服药时间', '剂量 (mg)', '备注']
      : const ['Taken at', 'Dose (mg)', 'Note'];
  String get settingsTitle => _s('Settings', '设置');
  String get settingsLanguage => _s('Language', '语言');
  String get settingsTheme => _s('Theme', '主题');
  String get settingsAccount => _s('Account', '账户');
  String get settingsWebDav => _s('WebDAV sync', 'WebDAV 同步');
  String get themeSystem => _s('System', '跟随系统');
  String get themeLight => _s('Light', '浅色');
  String get themeDark => _s('Dark', '深色');
  String get appLock => _s('App lock', '应用锁');
  String get appLockSubtitle => _s(
        'Require unlock screen at launch',
        '启动时显示解锁页面',
      );
  String get webDavSubtitle => _s(
        'Configure remote sync endpoint',
        '配置远程同步地址',
      );
  String get signOut => _s('Sign out', '退出登录');
  String get simulationHours => _s('sim h', '模拟小时');

  String get stopSimTitle => _s('Stop-medication simulation', '停药模拟');
  String get heightLabel => _s('Height', '身高');
  String get heightUnit => _s('cm', '厘米');
  String get weightLabel => _s('Weight', '体重');
  String get weightUnit => _s('kg', '公斤');
  String get currentPeak => _s('Current peak', '当前峰值浓度');
  String get minEffectiveConc => _s('Min effective conc.', '最低有效浓度');
  String get timeToThreshold => _s(
        'Time below threshold after stopping',
        '停药后低于阈值所需时间',
      );
  String get hourUnit => _s('h', '小时');
  String get bsaLabel => _s('BSA', '体表面积');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales
      .map((l) => l.languageCode)
      .contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
