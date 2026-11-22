import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The phone's location, as a test sets it.
class FakeLocation extends GeolocatorPlatform with MockPlatformInterfaceMixin {
  new({
    this.on = true,
    this.permission = LocationPermission.whileInUse,
    this.lat = 30.7046,
    this.lng = 76.7179,
  });

  bool on;
  LocationPermission permission;
  double lat;
  double lng;

  /// Thrown instead of a position.
  Exception? error;

  int reads = 0;
  int asks = 0;
  int settingsOpened = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => on;

  @override
  Future<LocationPermission> checkPermission() async =>
      permission == LocationPermission.deniedForever
      ? LocationPermission.denied
      : permission;

  @override
  Future<LocationPermission> requestPermission() async {
    asks++;
    return permission;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    reads++;
    if (error case final error?) throw error;
    return Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime(2026, 11, 22),
      // Rough, and reported as mocked: taken all the same, nothing is judged.
      accuracy: 900,
      isMocked: true,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  @override
  Future<bool> openAppSettings() async {
    settingsOpened++;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    settingsOpened++;
    return true;
  }
}
