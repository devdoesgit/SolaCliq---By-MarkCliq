part of 'health_cubit.dart';

sealed class HealthState extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

final class HealthChecking extends HealthState {
  const new();
}

final class HealthLoaded extends HealthState {
  const new(this.report);

  final HealthReport report;

  @override
  List<Object> get props => [report];
}

final class HealthUnreachable extends HealthState {
  const new();
}
