import 'package:dio/dio.dart';
import 'package:solacliq/auth/data/auth_failure.dart';

/// Runs an API request, turning a network or server error into an
/// [AuthFailure] that screens show through `SubmitCubit`.
Future<T> apiCall<T>(Future<T> Function() request) async {
  try {
    return await request();
  } on DioException catch (error) {
    throw AuthFailure.fromDio(error);
  }
}
