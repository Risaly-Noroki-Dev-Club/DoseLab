import 'package:flutter/cupertino.dart';

/// Cupertino (iOS-native) themes for light/dark. The primary accent
/// (activeBlue) matches the original blue from the Material 3 seed.
class AppTheme {
  const AppTheme._();

  static CupertinoThemeData light() {
    return const CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: Color(0xFF007AFF),
      scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
      barBackgroundColor: Color(0xF2F2F2F7),
      textTheme: CupertinoTextThemeData(
        navTitleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.41,
        ),
        navLargeTitleTextStyle: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.37,
        ),
        actionTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.41,
        ),
        tabLabelTextStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.24,
        ),
        pickerTextStyle: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.5,
        ),
        dateTimePickerTextStyle: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  static CupertinoThemeData dark() {
    return const CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: Color(0xFF0A84FF),
      scaffoldBackgroundColor: CupertinoColors.black,
      barBackgroundColor: Color(0xFF1C1C1E),
      textTheme: CupertinoTextThemeData(
        navTitleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.41,
        ),
        navLargeTitleTextStyle: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.37,
        ),
        actionTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.41,
        ),
        tabLabelTextStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.24,
        ),
        pickerTextStyle: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.5,
        ),
        dateTimePickerTextStyle: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

/// Semantic colours used by the PK chart bands. Kept outside
/// the theme because these convey clinical meaning, not branding.
class PkBandColors {
  const PkBandColors._();
  static const safe = Color(0xFF81C784);
  static const warn = Color(0xFFFFB74D);
  static const toxic = Color(0xFFCF6679);
  static const peak = Color(0xFFFF9800);
}
