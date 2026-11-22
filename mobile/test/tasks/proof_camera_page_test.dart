import 'package:bloc_test/bloc_test.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:solacliq/tasks/cubit/task_cubit.dart';
import 'package:solacliq/tasks/view/proof_camera_page.dart';

import '../helpers/helpers.dart';
import 'task_fixtures.dart';

class _MockTaskCubit extends MockCubit<TaskState> implements TaskCubit;

/// A camera the person said "Don't allow" to: opening it fails.
class _DeniedCamera extends CameraPlatform with MockPlatformInterfaceMixin {
  int opens = 0;

  @override
  Future<List<CameraDescription>> availableCameras() async => const [
    CameraDescription(
      name: '0',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 90,
    ),
  ];

  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() =>
      const Stream.empty();

  @override
  Future<int> createCameraWithSettings(
    CameraDescription cameraDescription,
    MediaSettings? mediaSettings,
  ) async {
    opens++;
    throw CameraException('CameraAccessDenied', 'denied');
  }
}

/// Location the person said "Don't allow" to.
class _DeniedLocation extends GeolocatorPlatform
    with MockPlatformInterfaceMixin {
  int asks = 0;
  int settingsOpened = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.denied;

  @override
  Future<LocationPermission> requestPermission() async {
    asks++;
    return LocationPermission.denied;
  }

  @override
  Future<bool> openAppSettings() async {
    settingsOpened++;
    return true;
  }
}

void main() {
  late _DeniedCamera camera;
  late _DeniedLocation location;
  late _MockTaskCubit cubit;

  setUp(() {
    camera = _DeniedCamera();
    location = _DeniedLocation();
    CameraPlatform.instance = camera;
    GeolocatorPlatform.instance = location;
    cubit = _MockTaskCubit();
    when(() => cubit.state)
        .thenReturn(TaskState(task: assignedTask(), loading: false));
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpApp(
      BlocProvider<TaskCubit>.value(
        value: cubit,
        child: const ProofCameraPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> dialogClosed(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
  }

  group('denied camera and location', () {
    testWidgets('asks once each, even as the dialogs come and go', (
      tester,
    ) async {
      await pump(tester);
      expect(camera.opens, 1);
      expect(location.asks, 1);
      // A permission dialog pauses and resumes the app: no asking again.
      await dialogClosed(tester);
      await dialogClosed(tester);
      expect(camera.opens, 1);
      expect(location.asks, 1);
      expect(find.text('Camera not allowed'), findsOneWidget);
      expect(find.textContaining('Location not allowed'), findsOneWidget);
    });

    testWidgets('the location chip opens the settings that fix it', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('camera_location_settings')));
      await dialogClosed(tester);
      expect(location.settingsOpened, 1);
      expect(location.asks, 2);
    });

    testWidgets('back from Settings, it tries again', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('camera_settings')));
      await dialogClosed(tester);
      expect(camera.opens, 2);
    });
  });
}
