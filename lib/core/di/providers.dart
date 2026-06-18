import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import '../storage/local_db.dart';

/// Single source of truth for all process-singleton dependencies.
/// Feature modules should `ref.read` / `ref.watch` from here rather
/// than constructing their own clients.

final secureStorageProvider = Provider<FlutterSecureStorage>((_) {
  return const FlutterSecureStorage();
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((_) {
  return SharedPreferences.getInstance();
});

final localDbProvider = Provider<LocalDb>((ref) {
  final db = LocalDb();
  ref.onDispose(db.close);
  return db;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(secureStorage: ref.watch(secureStorageProvider));
});
