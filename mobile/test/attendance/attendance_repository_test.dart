import 'dart:async';
import 'dart:convert';

import 'package:api_client/api_client.dart' show AttendanceApi;
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solacliq/attendance/data/attendance_repository.dart';
import 'package:solacliq/auth/auth.dart';

import '../helpers/helpers.dart';

/*
  The server, as the tests need it: each request is answered by the next
  of [answers] (a status and an optional problem code), or 201/200 with a
  day once they run out. `null` status means no answer at all (offline)
*/
class _Server {
  final requests = <RequestOptions>[];
  final answers = <(int?, String?)>[];

  Future<ResponseBody> handle(RequestOptions o) async {
    requests.add(o);
    if (answers.isNotEmpty) {
      final (status, code) = answers.removeAt(0);
      if (status == null) {
        throw DioException(
          requestOptions: o,
          type: DioExceptionType.connectionError,
        );
      }
      if (status >= 400) {
        return jsonBody(status, problem(status, code ?? 'common.internal'));
      }
    }
    final end = o.path.endsWith('/end');
    return jsonBody(end ? 200 : 201, {
      'date': '2026-12-01',
      'status': end ? 'ended' : 'working',
      'start': {'at': '2026-12-01T03:42:00Z', 'sent_late': false},
      if (end) 'end': {'at': '2026-12-01T13:10:00Z', 'sent_late': false},
      if (end) 'minutes': 568,
    });
  }

  List<String> get kinds => [for (final r in requests) r.path.split('/').last];
  Map<String, dynamic> body(int i) {
    final data = requests[i].data;
    return (data is String ? jsonDecode(data) : data) as Map<String, dynamic>;
  }

  String key(int i) => requests[i].headers['Idempotency-Key'] as String;
}

void main() {
  // 1 Dec 2026, 09:12 in India.
  var now = DateTime.utc(2026, 12, 1, 3, 42);
  late _Server server;
  late MemoryAttendanceStore store;

  AttendanceRepository repository() => AttendanceRepository(
    AttendanceApi(
      Dio(BaseOptions(baseUrl: 'http://api'))
        ..httpClientAdapter = FakeAdapter(server.handle),
    ),
    store,
    clock: () => now,
  );

  setUp(() {
    now = DateTime.utc(2026, 12, 1, 3, 42);
    server = _Server();
    store = MemoryAttendanceStore();
  });

  group(AttendanceRepository, () {
    test('sends a tap with its key and both phone times', () async {
      final repo = repository();
      final tap = await repo.tap('u1', 'o1', TapKind.start);
      now = now.add(const Duration(seconds: 2));
      final outcome = await repo.send('u1', 'o1');

      expect(server.kinds, ['start']);
      expect(server.requests.single.path, '/orgs/o1/me/attendance/start');
      expect(server.key(0), tap.key);
      expect(server.body(0), {
        'phone_at': '2026-12-01T03:42:00.000Z',
        'sent_at': '2026-12-01T03:42:02.000Z',
      });
      expect(outcome.day?.status, AttendanceStatus.working);
      expect(outcome.waiting, isFalse);
      expect(await repo.pending('u1', 'o1'), isEmpty);
    });

    test('offline: keeps the tap, and retries it as the same request with '
        'a new send time', () async {
      final repo = repository();
      await repo.tap('u1', 'o1', TapKind.start);
      server.answers.add((null, null));
      final offline = await repo.send('u1', 'o1');
      expect(offline.waiting, isTrue);
      expect(offline.day, isNull);
      expect(await repo.pending('u1', 'o1'), hasLength(1));

      now = now.add(const Duration(minutes: 40));
      await repo.send('u1', 'o1');
      expect(server.requests, hasLength(2));
      expect(server.key(1), server.key(0));
      expect(server.body(1)['phone_at'], server.body(0)['phone_at']);
      expect(server.body(1)['sent_at'], '2026-12-01T04:22:00.000Z');
      expect(await repo.pending('u1', 'o1'), isEmpty);
    });

    test('sends the start before the end, and never the end alone', () async {
      final repo = repository();
      await repo.tap('u1', 'o1', TapKind.start);
      now = now.add(const Duration(hours: 9));
      await repo.tap('u1', 'o1', TapKind.end);

      // The start can't get through: the end waits behind it.
      server.answers.add((null, null));
      await repo.send('u1', 'o1');
      expect(server.kinds, ['start']);

      await repo.send('u1', 'o1');
      expect(server.kinds, ['start', 'start', 'end']);
      expect(await repo.pending('u1', 'o1'), isEmpty);
    });

    test('a server error or an expired login is tried again', () async {
      final repo = repository();
      await repo.tap('u1', 'o1', TapKind.start);
      for (final answer in [
        (500, null),
        (503, null),
        (401, null),
        (429, null),
      ]) {
        server.answers.add(answer);
        expect(
          (await repo.send('u1', 'o1')).waiting,
          isTrue,
          reason: '$answer',
        );
        expect(await repo.pending('u1', 'o1'), hasLength(1));
      }
      expect((await repo.send('u1', 'o1')).waiting, isFalse);
      expect(await repo.pending('u1', 'o1'), isEmpty);
    });

    test(
      '"already started" or "already ended" means the server has it',
      () async {
        final repo = repository();
        await repo.tap('u1', 'o1', TapKind.start);
        await repo.tap('u1', 'o1', TapKind.end);
        server.answers
          ..add((409, 'attendance.already_started'))
          ..add((409, 'attendance.already_ended'));
        final outcome = await repo.send('u1', 'o1');
        expect(outcome.refused, isEmpty);
        expect(outcome.dropped, isNull);
        expect(await repo.pending('u1', 'o1'), isEmpty);
      },
    );

    test('a tap refused for good is dropped and reported', () async {
      final repo = repository();
      final start = await repo.tap('u1', 'o1', TapKind.start);
      final end = await repo.tap('u1', 'o1', TapKind.end);
      server.answers
        ..add((422, 'attendance.too_old'))
        ..add((409, 'attendance.not_started'));
      final outcome = await repo.send('u1', 'o1');
      expect(outcome.refused, [
        (start, AuthFailureCode.attendanceTooOld),
        (end, AuthFailureCode.attendanceNotStarted),
      ]);
      expect(outcome.dropped, AuthFailureCode.attendanceNotStarted);
      expect(outcome.waiting, isFalse);
      expect(await repo.pending('u1', 'o1'), isEmpty);
    });

    test(
      'a second tap of the same kind the same day is the same tap',
      () async {
        final repo = repository();
        final first = await repo.tap('u1', 'o1', TapKind.start);
        now = now.add(const Duration(minutes: 1));
        expect(await repo.tap('u1', 'o1', TapKind.start), first);
        expect(await repo.pending('u1', 'o1'), [first]);

        // The next India date is a new day (1 Dec 18:30 UTC is midnight).
        now = DateTime.utc(2026, 12, 1, 18, 30);
        final next = await repo.tap('u1', 'o1', TapKind.start);
        expect(next, isNot(first));
        expect(await repo.pending('u1', 'o1'), [first, next]);
      },
    );

    test("each person's taps go only with that person and company", () async {
      final repo = repository();
      await repo.tap('u1', 'o1', TapKind.start);
      await repo.tap('u1', 'o2', TapKind.start);
      await repo.tap('u2', 'o1', TapKind.start);

      await repo.send('u2', 'o1');
      expect(server.requests.single.path, '/orgs/o1/me/attendance/start');
      expect(await repo.pending('u2', 'o1'), isEmpty);
      expect(await repo.pending('u1', 'o1'), hasLength(1));
      expect(await repo.pending('u1', 'o2'), hasLength(1));
    });

    test(
      'taps outlive the app: a new run sends what the last one kept',
      () async {
        server.answers.add((null, null));
        final first = repository();
        final tap = await first.tap('u1', 'o1', TapKind.start);
        await first.send('u1', 'o1');

        final next = repository();
        expect(await next.pending('u1', 'o1'), [tap]);
        await next.send('u1', 'o1');
        expect(server.key(1), tap.key);
      },
    );

    test('two sends at once post each tap once', () async {
      final repo = repository();
      await repo.tap('u1', 'o1', TapKind.start);
      await Future.wait([repo.send('u1', 'o1'), repo.send('u1', 'o1')]);
      expect(server.kinds, ['start']);
    });

    test('saving a tap never waits for a slow send', () async {
      final slow = Completer<void>();
      final repo = AttendanceRepository(
        AttendanceApi(
          Dio(BaseOptions(baseUrl: 'http://api'))
            ..httpClientAdapter = FakeAdapter((o) async {
              await slow.future;
              return await server.handle(o);
            }),
        ),
        store,
        clock: () => now,
      );
      await repo.tap('u1', 'o1', TapKind.start);
      final sending = repo.send('u1', 'o1');
      // While the start is on its way, the end is saved at once.
      final end = await repo
          .tap('u1', 'o1', TapKind.end)
          .timeout(const Duration(seconds: 1));
      expect(end.kind, TapKind.end);
      slow.complete();
      await sending;
      expect(server.kinds, ['start', 'end']);
    });

    test('a damaged store is read as empty, never guessed at', () async {
      for (final raw in ['not json', '{"a": 1}', '[{"kind": "start"}]', '']) {
        store.value = raw;
        expect(await repository().pending('u1', 'o1'), isEmpty, reason: raw);
      }
      store.value = jsonEncode([
        {
          'user_id': 'u1',
          'org_id': 'o1',
          'kind': 'nap',
          'phone_at': 'x',
          'key': 'k',
        },
      ]);
      expect(await repository().pending('u1', 'o1'), isEmpty);
    });
  });

  test('indiaDate turns at midnight in India', () {
    expect(indiaDate(DateTime.utc(2026, 12, 1, 18, 29)), '2026-12-01');
    expect(indiaDate(DateTime.utc(2026, 12, 1, 18, 30)), '2026-12-02');
    expect(indiaDate(DateTime.utc(2026, 12, 31, 18, 30)), '2027-01-01');
  });
}
