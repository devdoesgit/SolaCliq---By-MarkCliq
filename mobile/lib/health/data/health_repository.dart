import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

/// What `GET /health` reported.
class HealthReport extends Equatable {
  const new({required this.databaseOk, required this.version});

  /// Whether the backend could reach its database.
  final bool databaseOk;

  /// Backend build version.
  final String version;

  @override
  List<Object> get props => [databaseOk, version];
}

/// The API could not be reached, or answered with something unexpected.
class HealthUnreachableException implements Exception {
  const new([this.cause]);

  final Object? cause;

  @override
  String toString() => 'HealthUnreachableException($cause)';
}

/// Reads the API's health through the generated client.
class HealthRepository {
  const new(this._api);

  final SystemApi _api;

  /// Fetches the health report. A 503 is a valid answer (database down), not
  /// an error. Throws [HealthUnreachableException] when there is no usable
  /// answer, and rethrows a cancellation from [cancelToken] unchanged.
  Future<HealthReport> fetch({CancelToken? cancelToken}) async {
    try {
      final response = await _api.getHealth(
        cancelToken: cancelToken,
        validateStatus: (status) => status == 200 || status == 503,
      );
      final health = response.data;
      if (health == null) throw const HealthUnreachableException();
      return HealthReport(
        databaseOk:
            health.status == HealthStatusEnum.ok &&
            health.database == HealthDatabaseEnum.ok,
        version: health.version,
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) rethrow;
      throw HealthUnreachableException(error);
    }
  }
}
