import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solacliq/auth/data/auth_failure.dart';

DioException problem(int status, Map<String, Object?> body) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: status, data: body),
  );
}

void main() {
  group(AuthFailure, () {
    test('reads the code and keeps the server detail', () {
      final f = AuthFailure.fromDio(
        problem(409, {
          'code': 'registration.duplicate',
          'detail': 'Meena registered this customer on 14 Nov 2026 (SC-0002).',
        }),
      );
      expect(f.code, AuthFailureCode.registrationDuplicate);
      expect(f.detail, contains('Meena'));
    });

    test('each flow error has its own code', () {
      for (final (api, code) in [
        ('task.locked', AuthFailureCode.taskLocked),
        ('task.incomplete', AuthFailureCode.taskIncomplete),
        ('expense.locked', AuthFailureCode.expenseLocked),
        ('registration.locked', AuthFailureCode.registrationLocked),
        ('upload.unavailable', AuthFailureCode.uploadUnavailable),
      ]) {
        expect(AuthFailure.fromDio(problem(409, {'code': api})).code, code);
      }
    });

    test('a field error on an upload id means the file did not arrive', () {
      for (final field in ['upload_id', 'receipt_upload_id', 'documents']) {
        final f = AuthFailure.fromDio(
          problem(422, {
            'code': 'validation.failed',
            'errors': [
              {'field': field, 'message': "The file didn't finish uploading."},
            ],
          }),
        );
        expect(f.code, AuthFailureCode.uploadIncomplete, reason: field);
      }
      final other = AuthFailure.fromDio(
        problem(422, {
          'code': 'validation.failed',
          'errors': [
            {'field': 'amount', 'message': 'Too big.'},
          ],
        }),
      );
      expect(other.code, AuthFailureCode.validation);
      expect(other.fields, {'amount': 'Too big.'});
      expect(AuthFailure.fromDio(problem(409, {'code': 'x'})).fields, isEmpty);
    });

    test('an unknown code falls back on the status', () {
      expect(
        AuthFailure.fromDio(problem(409, {'code': 'something.new'})).code,
        AuthFailureCode.unknown,
      );
      expect(
        AuthFailure.fromDio(problem(422, {'code': 'something.new'})).code,
        AuthFailureCode.validation,
      );
    });
  });
}
