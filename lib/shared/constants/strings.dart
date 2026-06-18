/// String constants that are not user-facing translations
/// (e.g. preference keys, storage keys, API paths).
class StorageKeys {
  const StorageKeys._();
  static const accessToken = 'access_token';
  static const refreshToken = 'refresh_token';
  static const language = 'language';
  static const themeMode = 'theme_mode';
  static const lastUserId = 'last_user_id';
  static const lockEnabled = 'lock_enabled';
  static const webdavUrl = 'webdav_url';
  static const webdavUser = 'webdav_user';
  static const webdavPassword = 'webdav_password';
  static const heightCm = 'height_cm';
  static const weightKg = 'weight_kg';
}

class ApiPaths {
  const ApiPaths._();
  static const authLogin = '/auth/login';
  static const authRegister = '/auth/register';
  static const authRefresh = '/auth/refresh';
  static const drugs = '/drugs';
  static const pkCompute = '/pk/compute';
  static const interactions = '/interactions/check';
  static const syncPush = '/sync/push';
  static const syncPull = '/sync/pull';
  static const reportGenerate = '/reports/generate';
}

class FdaPaths {
  const FdaPaths._();
  static const ndc = '/drug/ndc.json';
  static const label = '/drug/label.json';
}
