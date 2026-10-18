import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solacliq/health/data/health_repository.dart';

import '../helpers/helpers.dart';

Response<Health> _response(Health health, int status) => Response(
  requestOptions: RequestOptions(path: '/health'),
  statusCode: status,
  data: health,
);

void main() {
  late MockSystemApi api;
  late HealthRepository repository;

  setUp(() {
    api = MockSystemApi();
    repository = HealthRepository(api);
  });

  void stubHealth(Future<Response<Health>> Function() answer) {
    when(
      () => api.getHealth(
        cancelToken: any(named: 'cancelToken'),
        validateStatus: any(named: 'validateStatus'),
      ),
    ).thenAnswer((_) => answer());
  }

  group(HealthRepository, () {
    test('ok when API and database are up', () async {
      stubHealth(
        () async => _response(
          Health(
            status: HealthStatusEnum.ok,
            version: '0.1.0',
            database: HealthDatabaseEnum.ok,
          ),
          200,
        ),
      );
      expect(
        await repository.fetch(),
        const HealthReport(databaseOk: true, version: '0.1.0'),
      );
    });

    test('a 503 is a report with the database down, not an error', () async {
      stubHealth(
        () async => _response(
          Health(
            status: HealthStatusEnum.degraded,
            version: '0.1.0',
            database: HealthDatabaseEnum.unavailable,
          ),
          503,
        ),
      );
      expect(
        await repository.fetch(),
        const HealthReport(databaseOk: false, version: '0.1.0'),
      );
    });

    test('accepts 200 and 503 only', () async {
      ValidateStatus? captured;
      when(
        () => api.getHealth(
          cancelToken: any(named: 'cancelToken'),
          validateStatus: any(named: 'validateStatus'),
        ),
      ).thenAnswer((invocation) async {
        captured =
            invocation.namedArguments[#validateStatus] as ValidateStatus?;
        return _response(
          Health(
            status: HealthStatusEnum.ok,
            version: '0.1.0',
            database: HealthDatabaseEnum.ok,
          ),
          200,
        );
      });
      await repository.fetch();
      expect(captured!(200), isTrue);
      expect(captured!(503), isTrue);
      expect(captured!(500), isFalse);
      expect(captured!(404), isFalse);
    });

    test('network failure becomes HealthUnreachableException', () async {
      stubHealth(
        () => Future.error(
          DioException.connectionError(
            requestOptions: RequestOptions(path: '/health'),
            reason: 'offline',
          ),
        ),
      );
      expect(repository.fetch(), throwsA(isA<HealthUnreachableException>()));
    });

    test('cancellation is rethrown unchanged', () async {
      stubHealth(
        () => Future.error(
          DioException.requestCancelled(
            requestOptions: RequestOptions(path: '/health'),
            reason: 'cancelled',
          ),
        ),
      );
      expect(
        repository.fetch(),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
    });
  });
}
