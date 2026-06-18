import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../config/env.dart';

/// JWT-aware Dio interceptor. Reads the access token from secure
/// storage on every request and clears it on a 401 so the auth layer
/// can prompt re-login.
class _JwtInterceptor extends Interceptor {
  _JwtInterceptor(this._storage);

  static const _tokenKey = 'access_token';
  final FlutterSecureStorage _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: _tokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await _storage.delete(key: _tokenKey);
    }
    handler.next(err);
  }
}

/// Wraps two Dio instances: one for the DoseLab backend (`apiBaseUrl`)
/// and one for openFDA (`fdaBaseUrl`). They are split because:
///   * openFDA must never carry the user's JWT
///   * openFDA needs API-key redaction in logs
class ApiClient {
  ApiClient({required FlutterSecureStorage secureStorage})
      : backend = _buildBackendDio(secureStorage),
        fda = _buildFdaDio();

  final Dio backend;
  final Dio fda;

  static Dio _buildBackendDio(FlutterSecureStorage storage) {
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 10),
        headers: const {'Accept': 'application/json'},
      ),
    );
    dio.interceptors.add(_JwtInterceptor(storage));
    if (Env.enableNetworkLogs && Env.fdaApiKey.isEmpty) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: false,
        ),
      );
    }
    return dio;
  }

  static Dio _buildFdaDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.fdaBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        headers: const {'Accept': 'application/json'},
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (Env.fdaApiKey.isNotEmpty) {
            options.queryParameters['api_key'] = Env.fdaApiKey;
          }
          handler.next(options);
        },
      ),
    );
    if (Env.enableNetworkLogs) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: false,
        ),
      );
    }
    return dio;
  }

  /// Strip the API key from URLs before they are persisted or shown
  /// in the UI. Mirrors the redaction performed by the original PWA
  /// (see `web/index.html`’s `fdaFetch()`).
  static String redactApiKey(String url) =>
      url.replaceAllMapped(RegExp(r'(api_key=)[^&]+'), (match) {
        return '${match.group(1)}***';
      });
}
