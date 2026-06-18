import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/extensions/string_x.dart';

/// Chinese → English drug-name lookup. openFDA does not accept CJK
/// terms, so any CJK query must be resolved here before it can be
/// forwarded. Mirrors the `resolveQuery()` / `matchZh()` pair from
/// the original PWA, but the inline core list is no longer hardcoded
/// — both core and extended entries live in
/// `assets/data/zh_drug_map.json`.
class ZhMapping {
  const ZhMapping({required this.en, required this.zh, this.category});
  final String en;
  final List<String> zh;
  final String? category;
}

class ZhResolution {
  const ZhResolution({
    required this.english,
    required this.matched,
    this.category,
  });
  final String english;
  final String matched;
  final String? category;
}

class ZhResolver {
  ZhResolver(this._entries);
  final List<ZhMapping> _entries;

  /// If [query] is plain ASCII, return it unchanged. If it contains
  /// CJK, look up the English canonical name; returns null when no
  /// mapping is known so the caller can show "unmapped" guidance
  /// rather than spamming openFDA with Chinese text.
  ZhResolution? resolve(String query) {
    if (!query.hasCjk) {
      return ZhResolution(english: query, matched: query);
    }
    final lq = query.toLowerCase();
    for (final e in _entries) {
      for (final n in e.zh) {
        if (n.toLowerCase().looseContains(lq)) {
          return ZhResolution(english: e.en, matched: n, category: e.category);
        }
      }
    }
    return null;
  }
}

/// Loads (and caches) the bundled zh→en map asset on first read.
final zhResolverProvider = FutureProvider<ZhResolver>((ref) async {
  final raw = await rootBundle.loadString('assets/data/zh_drug_map.json');
  final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  final entries = [
    for (final row in list)
      ZhMapping(
        en: row['en'] as String,
        zh: List<String>.from(row['zh'] as List),
        category: row['category'] as String?,
      ),
  ];
  return ZhResolver(entries);
});
