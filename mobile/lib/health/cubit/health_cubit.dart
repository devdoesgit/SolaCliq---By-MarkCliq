import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:solacliq/health/data/health_repository.dart';

part 'health_state.dart';

/// Checks the API's health. A new check cancels the one in flight, and
/// closing the cubit cancels any request still running.
class HealthCubit extends Cubit<HealthState> {
  new(this._repository) : super(const HealthChecking());

  final HealthRepository _repository;
  CancelToken? _inFlight;

  Future<void> check() async {
    _inFlight?.cancel();
    final token = _inFlight = CancelToken();
    emit(const HealthChecking());
    try {
      final report = await _repository.fetch(cancelToken: token);
      if (!isClosed) emit(HealthLoaded(report));
    } on HealthUnreachableException {
      if (!isClosed) emit(const HealthUnreachable());
    } on DioException catch (error) {
      // Cancelled by a newer check or by close(); nothing to report.
      if (!CancelToken.isCancel(error)) rethrow;
    } finally {
      if (identical(_inFlight, token)) _inFlight = null;
    }
  }

  @override
  Future<void> close() {
    _inFlight?.cancel();
    _inFlight = null;
    return super.close();
  }
}
