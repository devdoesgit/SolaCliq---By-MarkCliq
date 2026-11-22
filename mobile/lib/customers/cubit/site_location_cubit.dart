import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:solacliq/customers/data/site_point.dart';

/// Why the phone gave no position.
enum SiteLocationProblem { off, denied, notFound }

class SiteLocationState extends Equatable {
  const new({this.point, this.locating = false, this.problem});

  /// The last position taken; a failed retake keeps it.
  final SitePoint? point;
  final bool locating;
  final SiteLocationProblem? problem;

  @override
  List<Object?> get props => [point, locating, problem];
}

/*
  The site's lat and long, from the agent's phone
  ----------------------------------------------------------------------
  - read once, only when the agent taps for it; never followed
  - optional: no GPS or no permission never stops a registration
  - whatever the phone gives is taken: no accuracy, distance or mock
    checks (owner, 2026-11-22)
  - lives for the whole form, so a fix that lands after "Next" is kept
*/
class SiteLocationCubit extends Cubit<SiteLocationState> {
  new() : super(const SiteLocationState());

  // Indoors GPS may never answer; the agent shouldn't wait on it.
  static const _wait = Duration(seconds: 20);

  Future<void> locate() async {
    if (state.locating) return;
    emit(SiteLocationState(point: state.point, locating: true));
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return _failed(SiteLocationProblem.off);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _failed(SiteLocationProblem.denied);
      }
      final at = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(timeLimit: _wait),
      );
      if (isClosed) return;
      emit(SiteLocationState(point: SitePoint(at.latitude, at.longitude)));
    } on LocationServiceDisabledException {
      _failed(SiteLocationProblem.off);
    } on Exception {
      // No fix in time, or the plugin's own (a request already showing).
      _failed(SiteLocationProblem.notFound);
    }
  }

  /// The settings page that fixes the problem.
  Future<void> openSettings() async {
    if (state.problem == SiteLocationProblem.off) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  void _failed(SiteLocationProblem problem) {
    if (isClosed) return;
    emit(SiteLocationState(point: state.point, problem: problem));
  }
}
