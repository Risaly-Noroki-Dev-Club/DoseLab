/// Source-metadata envelope used everywhere we surface FDA data.
/// The shape mirrors `scripts/fda_query.py` so log captures from the
/// two clients stay diff-comparable.
class FdaEnvelope {
  FdaEnvelope({
    required this.results,
    required this.meta,
    required this.endpoint,
    required this.searchQuery,
    required this.requestUrl,
    required this.retrievedAt,
  });

  final List<Map<String, dynamic>> results;
  final Map<String, dynamic> meta;
  final String endpoint;
  final String searchQuery;

  /// URL with `api_key=***` redacted, safe to persist.
  final String requestUrl;
  final DateTime retrievedAt;

  String? get lastUpdated =>
      (meta['results'] as Map?)?['total']?.toString() == null
          ? null
          : meta['last_updated']?.toString();
}

/// Convenience: an empty envelope used when openFDA returns 404.
FdaEnvelope emptyEnvelope({
  required String endpoint,
  required String search,
  required String url,
}) {
  return FdaEnvelope(
    results: const [],
    meta: const {
      'results': {'total': 0},
    },
    endpoint: endpoint,
    searchQuery: search,
    requestUrl: url,
    retrievedAt: DateTime.now().toUtc(),
  );
}
