import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

import '../../core/di/providers.dart';
import '../../core/storage/local_db.dart';
import '../../shared/constants/strings.dart';

/// WebDAV-backed JSON export/import. We deliberately push a plain
/// JSON document rather than the SQLite file so users can inspect or
/// edit their data outside the app, and so a partial sync from a
/// different device can still be merged.
class WebDavSync {
  WebDavSync({required this.client, required this.db});
  final webdav.Client client;
  final LocalDb db;

  static const remotePath = '/doselab/state.json';

  Future<void> push() async {
    final drugs = await db.getAllDrugs();
    final payload = jsonEncode({
      'version': 1,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'drugs': [
        for (final d in drugs)
          {
            'id': d.id,
            'product_ndc': d.productNdc,
            'brand_name': d.brandName,
            'generic_name': d.genericName,
            'strength': d.strength,
            'dose_mg': d.doseMg,
            'interval_hours': d.intervalHours,
            'notify': d.notify,
            'added_at': d.addedAt.toIso8601String(),
            'last_dose_at': d.lastDoseAt?.toIso8601String(),
          },
      ],
    });
    await client.write(remotePath, utf8.encode(payload));
  }

  Future<int> pull() async {
    final raw = await client.read(remotePath);
    final doc = jsonDecode(utf8.decode(raw)) as Map<String, dynamic>;
    final list = (doc['drugs'] as List).cast<Map<String, dynamic>>();
    for (final m in list) {
      await db.upsertDrug(
        DrugsCompanion.insert(
          id: m['id'] as String,
          productNdc: Value(m['product_ndc'] as String?),
          brandName: m['brand_name'] as String,
          genericName: Value(m['generic_name'] as String?),
          strength: Value(m['strength'] as String?),
          doseMg: Value((m['dose_mg'] as num).toDouble()),
          intervalHours: Value((m['interval_hours'] as num).toDouble()),
          notify: Value(m['notify'] as bool? ?? false),
          lastDoseAt: Value(
            m['last_dose_at'] == null
                ? null
                : DateTime.parse(m['last_dose_at'] as String),
          ),
        ),
      );
    }
    return list.length;
  }
}

final webDavSyncProvider = FutureProvider<WebDavSync?>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  final url = await storage.read(key: StorageKeys.webdavUrl);
  final user = await storage.read(key: StorageKeys.webdavUser);
  final pass = await storage.read(key: StorageKeys.webdavPassword);
  if (url == null || user == null || pass == null) return null;
  final client = webdav.newClient(url, user: user, password: pass);
  return WebDavSync(client: client, db: ref.watch(localDbProvider));
});
