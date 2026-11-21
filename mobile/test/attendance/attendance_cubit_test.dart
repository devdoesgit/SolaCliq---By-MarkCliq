import 'dart:convert';

import 'package:api_client/api_client.dart' show AttendanceApi;
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solacliq/attendance/cubit/attendance_cubit.dart';
import 'package:solacliq/attendance/data/attendance_repository.dart';
import 'package:solacliq/auth/auth.dart';

import '../helpers/helpers.dart';

/*
  A server that records each day as the real one would answer it, for
  1 Dec 2026, and can be switched offline or made to refuse
*/
class _Server {
  final requests = <RequestOptions>[];
  bool offline = false;
  String? refuse;

  Future<ResponseBody> handle(RequestOptions o) async {
    requests.add(o);
    if (offline) {
      throw DioException(
        requestOptions: o,
        type: DioExceptionType.connectionError,
      );
    }
    if (refuse case final code?) return jsonBody(409, problem(409, code));
    final data = o.data;
    final body = (data is String ? jsonDecode(data) : data) as Map;
    final end = o.path.endsWith('/end');
    final at = body['phone_at'] as String;
    // Dated by the tap, as the server does.
    final date = indiaDate(DateTime.parse(at));
    return jsonBody(end ? 200 : 201, {
      'date': date,
      'status': end ? 'ended' : 'working',
      'start': {'at': end ? '${date}T03:42:00Z' : at, 'sent_late': false},
      if (end) 'end': {'at': at, 'sent_late': false},
      if (end) 'minutes': 60,
    });
  }
}

void main() {
  late DateTime now;
  late _Server server;
  late MemoryAttendanceStore store;
  late int sent;

  AttendanceRepository repository() => AttendanceRepository(
    AttendanceApi(
      Dio(BaseOptions(baseUrl: 'http://api'))
        ..httpClientAdapter = FakeAdapter(server.handle),
    ),
    store,
    clock: () => now,
  );

  AttendanceCubit cubit([AttendanceRepository? repo]) => AttendanceCubit(
    repo ?? repository(),
    userId: 'u1',
    orgId: 'o1',
    clock: () => now,
    onSent: () => sent++,
    retryEvery: const Duration(milliseconds: 20),
  );

  const notStarted = HomeAttendance(state: AttendanceState.notStarted);

  setUp(() {
    // 1 Dec 2026, 09:12 in India.
    now = DateTime.utc(2026, 12, 1, 3, 42);
    server = _Server();
    store = MemoryAttendanceStore();
    sent = 0;
  });

  group(AttendanceCubit, () {
    test('starts and ends the day', () async {
      final c = cubit();
      addTearDown(c.close);
      await c.seed(notStarted);
      expect(c.state.state, AttendanceState.notStarted);

      await c.start();
      expect(c.state.state, AttendanceState.working);
      expect(c.state.startAt, now);
      expect(c.state.waiting, isFalse);
      expect(sent, 1);

      now = now.add(const Duration(hours: 1));
      await c.end();
      expect(c.state.state, AttendanceState.ended);
      expect(c.state.endAt, now);
      expect(sent, 2);
      expect(server.requests, hasLength(2));
    });

    test(
      'offline: shows the day at once, waits, then sends by itself',
      () async {
        server.offline = true;
        final c = cubit();
        addTearDown(c.close);
        await c.seed(notStarted);
        await c.start();
        expect(c.state.state, AttendanceState.working);
        expect(c.state.startAt, now);
        expect(c.state.waiting, isTrue);
        expect(sent, 0);

        server.offline = false;
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(c.state.waiting, isFalse);
        expect(c.state.state, AttendanceState.working);
        expect(sent, 1);
        // Once through, the retries stop.
        final count = server.requests.length;
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(server.requests, hasLength(count));
      },
    );

    test('a tap shows before it is saved or sent', () async {
      final c = cubit();
      addTearDown(c.close);
      await c.seed(notStarted);
      final tapping = c.start();
      expect(c.state.state, AttendanceState.working);
      expect(c.state.startAt, now);
      await tapping;
      expect(c.state.state, AttendanceState.working);
    });

    test('offers only the next tap, one at a time', () async {
      final c = cubit();
      addTearDown(c.close);
      await c.seed(notStarted);
      await c.end();
      expect(server.requests, isEmpty);
      expect(c.state.state, AttendanceState.notStarted);

      // Three quick taps: one start.
      await Future.wait([c.start(), c.start(), c.start()]);
      expect(server.requests, hasLength(1));
      await c.start();
      expect(server.requests, hasLength(1));
    });

    test("follows the server's card, and today only", () async {
      final c = cubit();
      addTearDown(c.close);
      final day = AttendanceDay(
        date: '2026-12-01',
        status: AttendanceStatus.working,
        start: AttendanceTap(at: DateTime.utc(2026, 12, 1, 3)),
      );
      await c.seed(HomeAttendance(state: AttendanceState.working, day: day));
      expect(c.state.state, AttendanceState.working);
      expect(c.state.startAt, DateTime.utc(2026, 12, 1, 3));

      // Left open past midnight in India: a new day, not started.
      now = DateTime.utc(2026, 12, 1, 18, 31);
      await c.seed(HomeAttendance(state: AttendanceState.working, day: day));
      expect(c.state.state, AttendanceState.notStarted);
    });

    test('a refused tap goes back, with the reason', () async {
      server.refuse = 'attendance.not_tracked';
      final c = cubit();
      addTearDown(c.close);
      await c.seed(notStarted);
      await c.start();
      expect(c.state.state, AttendanceState.notStarted);
      expect(c.state.problem, AuthFailureCode.attendanceNotTracked);
      expect(c.state.waiting, isFalse);

      // The next tap clears it.
      server.refuse = null;
      await c.start();
      expect(c.state.problem, isNull);
      expect(c.state.state, AttendanceState.working);
    });

    test('"already started" from another phone counts as started', () async {
      server.refuse = 'attendance.already_started';
      final c = cubit();
      addTearDown(c.close);
      await c.seed(notStarted);
      await c.start();
      expect(c.state.state, AttendanceState.working);
      expect(c.state.problem, isNull);
      expect(c.state.waiting, isFalse);
    });

    test('a tap kept from the last run shows and is sent', () async {
      server.offline = true;
      final earlier = repository();
      await earlier.tap('u1', 'o1', TapKind.start);
      await earlier.send('u1', 'o1');
      server
        ..offline = false
        ..requests.clear();

      final c = cubit();
      addTearDown(c.close);
      await c.seed(notStarted);
      expect(server.requests, hasLength(1));
      expect(c.state.state, AttendanceState.working);
      expect(c.state.startAt, DateTime.utc(2026, 12, 1, 3, 42));
      expect(c.state.waiting, isFalse);
    });

    test("yesterday's unsent end is sent, without ending today", () async {
      server.offline = true;
      final earlier = repository();
      now = DateTime.utc(2026, 11, 30, 3, 30);
      await earlier.tap('u1', 'o1', TapKind.start);
      now = DateTime.utc(2026, 11, 30, 12, 30);
      await earlier.tap('u1', 'o1', TapKind.end);
      await earlier.send('u1', 'o1');

      now = DateTime.utc(2026, 12, 1, 3, 42);
      final c = cubit();
      addTearDown(c.close);
      await c.seed(notStarted);
      expect(c.state.state, AttendanceState.notStarted);
      expect(c.state.waiting, isTrue);
      server.offline = false;
      await c.send();
      expect(c.state.waiting, isFalse);
      expect(c.state.state, AttendanceState.notStarted);
    });

    test('closing stops the retries', () async {
      server.offline = true;
      final c = cubit();
      await c.seed(notStarted);
      await c.start();
      final count = server.requests.length;
      await c.close();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(server.requests, hasLength(count));
    });
  });
}
