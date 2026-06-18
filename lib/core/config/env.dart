/// Environment-injected constants. Values are passed in via --dart-define
/// at `flutter run` / `flutter build` time; sensible defaults keep
/// local development frictionless.
class Env {
  const Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  static const String fdaBaseUrl = String.fromEnvironment(
    'FDA_BASE_URL',
    defaultValue: 'https://api.fda.gov',
  );

  static const String fdaApiKey = String.fromEnvironment('FDA_API_KEY');

  static const bool enableNetworkLogs = bool.fromEnvironment(
    'ENABLE_NETWORK_LOGS',
    defaultValue: true,
  );

  static const String appName = 'DoseLab';

  static const Duration labelCacheTtl = Duration(hours: 24);
}
