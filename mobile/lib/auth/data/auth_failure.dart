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

  /// Company registration: a GSTIN that fails the checksum, or one
  /// already registered.
  gstinInvalid('org.gstin_invalid'),
  gstinTaken('org.gstin_taken'),

  /// A task no longer with the worker (submitted, approved, cancelled).
  taskLocked('task.locked'),

  /// Submit with photos or checklist items still missing.
  taskIncomplete('task.incomplete'),

  /// A new receipt for an expense the admin didn't send back.
  expenseLocked('expense.locked'),

  /// The company already has this customer; `detail` says who and when.
  registrationDuplicate('registration.duplicate'),

  /// A new copy of a document the admin didn't send back.
  registrationLocked('registration.locked'),

  /// The server has no file storage set up.
  uploadUnavailable('upload.unavailable'),

  /// My install before the company has set it up.
  installNotStarted('install.not_started'),

  /// A payment claimed that isn't due (already claimed or paid).
  paymentNotDue('payment.not_due'),

  /// A file didn't reach storage whole (the server's field error on an
  /// upload id): send it again.
  uploadIncomplete(null),
  network(null),
  unknown(null);

  new(this.apiCode);

  /// The problem+json `code`, when the API sent one.
  final String? apiCode;
}

/// An auth request failed. Screens map [code] to a message.
class AuthFailure implements Exception {
  const new(this.code, [this.cause, this.detail]);

  /// Reads the problem+json body of a failed request, or classifies a
  /// network failure.
  factory fromDio(DioException error) {
    final response = error.response;
    if (response == null) return AuthFailure(AuthFailureCode.network, error);
    final body = _problem(response.data);
    final apiCode = body?['code'] as String?;
    if (apiCode == 'validation.failed' && _uploadField(body)) {
      return AuthFailure(AuthFailureCode.uploadIncomplete, error);
    }
    final code = AuthFailureCode.values.firstWhere(
      (c) => c.apiCode != null && c.apiCode == apiCode,
      orElse: () => switch (response.statusCode) {
        401 => AuthFailureCode.invalidCredentials,
        422 => AuthFailureCode.validation,
        429 => AuthFailureCode.tooManyAttempts,
        _ => AuthFailureCode.unknown,
      },
    );
    final detail = body?['detail'];
    return AuthFailure(code, error, detail is String ? detail : null);
  }

  final AuthFailureCode code;
  final Object? cause;

  /// The server's explanation, safe to show (problem+json `detail`), e.g.
  /// who registered a customer first.
  final String? detail;

  /// The fields that carry an upload id: a field error there means the
  /// file itself didn't arrive.
  static const _uploadFields = {'upload_id', 'receipt_upload_id', 'documents'};

  static Map<String, dynamic>? _problem(Object? data) {
    try {
      final body = data is String ? jsonDecode(data) : data;
      if (body is Map<String, dynamic>) return body;
    } on FormatException {
      return null;
    }
    return null;
  }

  static bool _uploadField(Map<String, dynamic>? body) {
    final errors = body?['errors'];
    return errors is List &&
        errors.any((e) => e is Map && _uploadFields.contains(e['field']));
  }

  @override
  String toString() => 'AuthFailure($code)';
}
