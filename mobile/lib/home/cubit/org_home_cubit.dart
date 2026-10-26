import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/home/data/home_repository.dart';

sealed class OrgHomeState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

final class OrgHomeLoading extends OrgHomeState {
  const new();
}

final class OrgHomeLoaded extends OrgHomeState {
  const new(this.summary);

  final HomeSummary summary;

  @override
  List<Object?> get props => [summary];
}

final class OrgHomeFailed extends OrgHomeState {
  const new(this.failure);

  final AuthFailureCode failure;

  @override
  List<Object?> get props => [failure];
}

/// Loads one company home for the person's role there.
class OrgHomeCubit extends Cubit<OrgHomeState> {
  new(this._homes, {required this.orgId, required this.role})
    : super(const OrgHomeLoading());

  final HomeRepository _homes;
  final String orgId;
  final OrgRole role;

  /// Loads, or reloads keeping what is shown until the new one arrives.
  Future<void> load() async {
    if (state is OrgHomeFailed) emit(const OrgHomeLoading());
    try {
      final summary = await _homes.orgHome(orgId, role);
      if (!isClosed) emit(OrgHomeLoaded(summary));
    } on AuthFailure catch (failure) {
      if (!isClosed && state is! OrgHomeLoaded) {
        emit(OrgHomeFailed(failure.code));
      }
    }
  }
}
