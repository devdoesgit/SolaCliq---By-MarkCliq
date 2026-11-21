import 'dart:convert';

import 'package:api_client/api_client.dart' show AttendanceApi;
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:solacliq/attendance/data/attendance_repository.dart';
import 'package:solacliq/attendance/view/attendance_card.dart';

import '../helpers/helpers.dart';

void main() {
  late List<RequestOptions> requests;
  late bool offline;
  late int sent;

  // Answers each tap as the server would, dated by the tap.
  Future<ResponseBody> server(RequestOptions o) async {
    requests.add(o);
    if (offline) {
      throw DioException(
        requestOptions: o,
        type: DioExceptionType.connectionError,
      );
    }
    final data = o.data;
    final body = (data is String ? jsonDecode(data) : data) as Map;
    final at = body['phone_at'] as String;
    final end = o.path.endsWith('/end');
    return jsonBody(end ? 200 : 201, {
      'date': indiaDate(DateTime.parse(at)),
      'status': end ? 'ended' : 'working',
      'start': {'at': at, 'sent_late': false},
      if (end) 'end': {'at': at, 'sent_late': false},
      if (end) 'minutes': 0,
    });
  }

  setUp(() {
    requests = [];
    offline = false;
    sent = 0;
  });

  Future<void> pumpCard(WidgetTester tester, HomeAttendance server0) async {
    final repository = AttendanceRepository(
      AttendanceApi(
        Dio(BaseOptions(baseUrl: 'http://api'))
          ..httpClientAdapter = FakeAdapter(server),
      ),
      MemoryAttendanceStore(),
    );
    await tester.pumpApp(
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: AttendanceCard(
            userId: 'u1',
            orgId: 'o1',
            server: server0,
            onSent: () => sent++,
          ),
        ),
      ),
      repositories: [
        RepositoryProvider<AttendanceRepository>.value(value: repository),
      ],
    );
    await tester.pumpAndSettle();
  }

  // Today's working day, started now.
  HomeAttendance working() {
    final now = DateTime.now().toUtc();
    return HomeAttendance(
      state: AttendanceState.working,
      day: AttendanceDay(
        date: indiaDate(now),
        status: AttendanceStatus.working,
        start: AttendanceTap(at: now),
      ),
    );
  }

  group(AttendanceCard, () {
    testWidgets('Start day starts the day', (tester) async {
      await pumpCard(
        tester,
        const HomeAttendance(state: AttendanceState.notStarted),
      );
      expect(find.text('Not started'), findsOneWidget);
      expect(find.byKey(const Key('attendance_end')), findsNothing);

      await tester.tap(find.byKey(const Key('attendance_start')));
      await tester.pumpAndSettle();
      expect(requests.single.path, '/orgs/o1/me/attendance/start');
      expect(find.textContaining('Working since'), findsOneWidget);
      expect(find.byKey(const Key('attendance_start')), findsNothing);
      expect(find.byKey(const Key('attendance_end')), findsOneWidget);
      expect(find.byKey(const Key('attendance_waiting')), findsNothing);
      expect(sent, 1);
    });

    testWidgets('End day asks first; Keep working changes nothing', (
      tester,
    ) async {
      await pumpCard(tester, working());

      await tester.tap(find.byKey(const Key('attendance_end')));
      await tester.pumpAndSettle();
      expect(find.text('End your day?'), findsOneWidget);
      await tester.tap(find.text('Keep working'));
      await tester.pumpAndSettle();
      expect(requests, isEmpty);
      expect(find.textContaining('Working since'), findsOneWidget);

      await tester.tap(find.byKey(const Key('attendance_end')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('attendance_end_confirm')));
      await tester.pumpAndSettle();
      expect(requests.single.path, '/orgs/o1/me/attendance/end');
      expect(find.text('Day ended'), findsOneWidget);
      expect(find.textContaining('0 h 0 m'), findsOneWidget);
      expect(find.byKey(const Key('attendance_end')), findsNothing);
      expect(find.byKey(const Key('attendance_start')), findsNothing);
    });

    testWidgets('offline: the day shows at once, saved on the phone', (
      tester,
    ) async {
      offline = true;
      await pumpCard(
        tester,
        const HomeAttendance(state: AttendanceState.notStarted),
      );
      await tester.tap(find.byKey(const Key('attendance_start')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Working since'), findsOneWidget);
      expect(find.byKey(const Key('attendance_waiting')), findsOneWidget);
      expect(sent, 0);
    });

    testWidgets('reads as one labelled card', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpCard(
        tester,
        const HomeAttendance(state: AttendanceState.notStarted),
      );
      expect(
        find.bySemanticsLabel(
          'Attendance. Not started. Tap Start day when you begin work.',
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Start day'), findsOneWidget);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    });
  });
}
