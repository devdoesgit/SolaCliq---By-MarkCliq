import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:solacliq/auth/data/auth_failure.dart';

enum SubmitStatus { idle, submitting, success, failure }

class SubmitState extends Equatable {
  const new({this.status = SubmitStatus.idle, this.failure});

  final SubmitStatus status;

  /// Why the last submit failed; set only with [SubmitStatus.failure].
  final AuthFailureCode? failure;

  bool get isSubmitting => status == SubmitStatus.submitting;

  @override
  List<Object?> get props => [status, failure];
}

/// Runs one form's request and reports its progress. Every auth form uses
/// it; the form validates its fields first and passes the request in.
class SubmitCubit extends Cubit<SubmitState> {
  new() : super(const SubmitState());

  /// Runs [request] unless one is already running. An [AuthFailure] becomes
  /// a failure state; anything else is a bug and is rethrown.
  Future<void> submit(Future<void> Function() request) async {
    if (state.isSubmitting) return;
    emit(const SubmitState(status: SubmitStatus.submitting));
    try {
      await request();
      if (!isClosed) emit(const SubmitState(status: SubmitStatus.success));
    } on AuthFailure catch (failure) {
      if (!isClosed) {
        emit(SubmitState(status: SubmitStatus.failure, failure: failure.code));
      }
    }
  }

  /// Back to idle, e.g. when the person edits a field after an error.
  void reset() {
    if (state.status != SubmitStatus.idle) emit(const SubmitState());
  }
}
