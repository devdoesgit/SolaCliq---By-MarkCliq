import 'dart:convert';

import 'package:dio/dio.dart';

/// Why an auth request failed, from the API's problem `code` or the network.
enum AuthFailureCode {
  invalidCredentials('auth.invalid_credentials'),
  emailUnverified('account.email_unverified'),

  /// Created for the person by an agent or admin; no password chosen yet.
  passwordNotSet('account.password_not_set'),
  codeInvalid('auth.code_invalid'),
  codeExpired('auth.code_expired'),
  tooManyAttempts('auth.too_many_attempts'),
  passwordTooWeak('auth.password_too_weak'),
  sessionExpired('auth.session_expired'),
  validation('validation.failed'),
  network(null),
  unknown(null);

  new(this.apiCode);

  /// The problem+json `code`, when the API sent one.
  final String? apiCode;
}

/// An auth request failed. Screens map [code] to a message.
class AuthFailure implements Exception {
  const new(this.code, [this.cause]);

  /// Reads the problem+json body of a failed request, or classifies a
  /// network failure.
  factory fromDio(DioException error) {
    final response = error.response;
    if (response == null) return AuthFailure(AuthFailureCode.network, error);
    final apiCode = _problemCode(response.data);
    final code = AuthFailureCode.values.firstWhere(
      (c) => c.apiCode != null && c.apiCode == apiCode,
      orElse: () => switch (response.statusCode) {
        401 => AuthFailureCode.invalidCredentials,
        422 => AuthFailureCode.validation,
        429 => AuthFailureCode.tooManyAttempts,
        _ => AuthFailureCode.unknown,
      },
    );
    return AuthFailure(code, error);
  }

  final AuthFailureCode code;
  final Object? cause;

  static String? _problemCode(Object? data) {
    try {
      final body = data is String ? jsonDecode(data) : data;
      if (body is Map && body['code'] is String) return body['code'] as String;
    } on FormatException {
      return null;
    }
    return null;
  }

  @override
  String toString() => 'AuthFailure($code)';
}
