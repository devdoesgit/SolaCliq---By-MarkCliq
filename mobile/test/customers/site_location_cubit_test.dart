import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:solacliq/customers/cubit/site_location_cubit.dart';
import 'package:solacliq/customers/data/site_point.dart';

import '../helpers/fake_location.dart';

void main() {
  late FakeLocation phone;
  late SiteLocationCubit cubit;

  setUp(() {
    phone = FakeLocation();
    GeolocatorPlatform.instance = phone;
    cubit = SiteLocationCubit();
  });

  tearDown(() => cubit.close());

  test("doesn't read the location until asked", () {
    expect(cubit.state, const SiteLocationState());
    expect(phone.reads + phone.asks, 0);
  });

  test('takes whatever position the phone gives, judging nothing', () async {
    await cubit.locate();
    expect(cubit.state.point, const SitePoint(30.7046, 76.7179));
    expect(cubit.state.problem, isNull);
  });

  test('location switched off', () async {
    phone.on = false;
    await cubit.locate();
    expect(cubit.state.problem, SiteLocationProblem.off);
    expect(cubit.state.locating, isFalse);
  });

  for (final permission in [
    LocationPermission.denied,
    LocationPermission.deniedForever,
  ]) {
    test('not allowed ($permission)', () async {
      phone.permission = permission;
      await cubit.locate();
      expect(cubit.state.problem, SiteLocationProblem.denied);
      expect(phone.reads, 0);
    });
  }

  for (final (name, error, problem) in [
    ('no fix in time', TimeoutException('none'), SiteLocationProblem.notFound),
    (
      'switched off meanwhile',
      const LocationServiceDisabledException(),
      SiteLocationProblem.off,
    ),
    (
      'the plugin failed',
      PlatformException(code: 'IO_ERROR'),
      SiteLocationProblem.notFound,
    ),
  ]) {
    test(name, () async {
      phone.error = error;
      await cubit.locate();
      expect(cubit.state.problem, problem);
      expect(cubit.state.locating, isFalse);
    });
  }

  test('a failed retake keeps the point it had', () async {
    await cubit.locate();
    phone.error = TimeoutException('none');
    await cubit.locate();
    expect(cubit.state.point, const SitePoint(30.7046, 76.7179));
    expect(cubit.state.problem, SiteLocationProblem.notFound);
  });

  test('a second tap while finding reads once', () async {
    await Future.wait([cubit.locate(), cubit.locate()]);
    expect(phone.reads, 1);
  });

  test('closing while finding is safe', () async {
    final finding = cubit.locate();
    await cubit.close();
    await expectLater(finding, completes);
  });
}
