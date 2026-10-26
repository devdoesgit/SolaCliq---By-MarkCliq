import 'dart:async';

import 'package:dio/dio.dart';
import 'package:solacliq/auth/data/auth_repository.dart';

/// Adds the access token to API requests, and on a 401 refreshes it once
/// and retries the request. A 403 from a company's endpoint re-reads the
/// account, since the person may have been removed or the company
/// suspended.
///
/// Auth endpoints (log in, refresh, codes) go out untouched, so a refresh
/// can never loop.
class AuthInterceptor extends Interceptor {
  new({required this._repository, required this._dio});

  final AuthRepository _repository;
  final Dio _dio;
  static const _retriedKey = 'solacliq.auth_retried';

  static bool _isPublicAuthPath(RequestOptions options) =>
      options.path.startsWith('/auth/') && options.path != '/auth/logout';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublicAuthPath(options)) {
      final token = await _repository.accessToken();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (err.response?.statusCode == 403 && options.path.startsWith('/orgs/')) {
      unawaited(_repository.refreshAccount(force: true));
    }
    final retry =
        err.response?.statusCode == 401 &&
        !_isPublicAuthPath(options) &&
        options.extra[_retriedKey] != true;
    if (!retry) return handler.next(err);

    final token = await _repository.refreshAccessToken();
    if (token == null) return handler.next(err);
    options
      ..headers['Authorization'] = 'Bearer $token'
      ..extra[_retriedKey] = true;
    try {
      handler.resolve(await _dio.fetch<Object?>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}
