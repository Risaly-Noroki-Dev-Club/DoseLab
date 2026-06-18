import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/error/failures.dart';
import '../../core/network/api_client.dart';
import '../../shared/constants/strings.dart';
import 'fda_envelope.dart';

/// Direct openFDA client. We could route everything through our own
/// backend but the original PWA hits openFDA directly, and the
/// local-first stance means the app must keep working without the
/// DoseLab backend reachable.
class FdaClient {
  FdaClient(this._dio);
  final Dio _dio;

  Future<FdaEnvelope> searchNdc(String term, {int limit = 20}) {
    final q = 'brand_name:"$term"+generic_name:"$term"';
    return _query(FdaPaths.ndc, q, limit);
  }

  Future<FdaEnvelope> searchNdcLoose(String term, {int limit = 20}) {
    final q = 'brand_name:$term+generic_name:$term';
    return _query(FdaPaths.ndc, q, limit);
  }

  Future<FdaEnvelope> searchLabel(String brandTerm) {
    final q = 'openfda.brand_name:"$brandTerm"';
    return _query(FdaPaths.label, q, 1);
  }

  Future<FdaEnvelope> _query(String endpoint, String search, int limit) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        endpoint,
        queryParameters: {'search': search, 'limit': limit, 'skip': 0},
      );
      final data = resp.data ?? const <String, dynamic>{};
      final reqUrl = ApiClient.redactApiKey(
        resp.requestOptions.uri.toString(),
      );
      return FdaEnvelope(
        results: List<Map<String, dynamic>>.from(
          (data['results'] as List?) ?? const [],
        ),
        meta: Map<String, dynamic>.from(
          (data['meta'] as Map?) ?? const {},
        ),
        endpoint: endpoint,
        searchQuery: search,
        requestUrl: reqUrl,
        retrievedAt: DateTime.now().toUtc(),
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final url = ApiClient.redactApiKey(
        e.requestOptions.uri.toString(),
      );
      // openFDA returns 404 when a query yields zero hits; treat as
      // an empty result rather than a network error so the UI can
      // show the "no results" state.
      if (code == 404) {
        return emptyEnvelope(
          endpoint: endpoint,
          search: search,
          url: url,
        );
      }
      throw Failure.network(
        message: e.message ?? 'FDA request failed',
        statusCode: code,
      );
    }
  }
}

final fdaClientProvider = Provider<FdaClient>((ref) {
  final api = ref.watch(apiClientProvider);
  return FdaClient(api.fda);
});
