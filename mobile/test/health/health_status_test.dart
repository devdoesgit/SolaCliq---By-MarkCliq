import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solacliq/health/health.dart';

import '../helpers/helpers.dart';

void main() {
  late MockHealthRepository repository;

  setUp(() {
    repository = MockHealthRepository();
  });

  void stubFetch(Future<HealthReport> Function() answer) {
    when(() => repository.fetch(cancelToken: any(named: 'cancelToken')))
        .thenAnswer((_) => answer());
  }

  group(HealthStatus, () {
    testWidgets('shows ok and the version', (tester) async {
      stubFetch(
        () async => const HealthReport(databaseOk: true, version: '0.1.0'),
      );
      await tester.pumpApp(const HealthStatus(), healthRepository: repository);
      await tester.pump();
      expect(find.text('Server ok'), findsOneWidget);
      expect(find.textContaining('0.1.0'), findsOneWidget);
    });

    testWidgets('shows when the database is down', (tester) async {
      stubFetch(
        () async => const HealthReport(databaseOk: false, version: '0.1.0'),
      );
      await tester.pumpApp(const HealthStatus(), healthRepository: repository);
      await tester.pump();
      expect(find.text('Database unavailable'), findsOneWidget);
    });

    testWidgets('unreachable shows a notice and retries', (tester) async {
      stubFetch(() => Future.error(const HealthUnreachableException()));
      await tester.pumpApp(const HealthStatus(), healthRepository: repository);
      await tester.pump();
      expect(find.text("Can't reach the server"), findsOneWidget);

      stubFetch(
        () async => const HealthReport(databaseOk: true, version: '0.1.0'),
      );
      await tester.tap(find.byKey(const Key('health_retry')));
      await tester.pump();
      await tester.pump();
      expect(find.text('Server ok'), findsOneWidget);
    });
  });
}
