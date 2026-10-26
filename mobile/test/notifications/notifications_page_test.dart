import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solacliq/notifications/data/notification_repository.dart';
import 'package:solacliq/notifications/view/notifications_page.dart';

import '../helpers/helpers.dart';

void main() {
  late MockNotificationRepository notifications;

  setUp(() {
    notifications = MockNotificationRepository();
    when(() => notifications.list(any())).thenAnswer(
      (_) async => [
        AppNotification(
          id: 'n1',
          kind: NotificationKind.taskReturned,
          title: 'Task returned',
          body: 'Retake the clamp close-up',
          at: DateTime.now(),
          read: false,
          taskId: 't1',
        ),
        AppNotification(
          id: 'n2',
          kind: NotificationKind.expensePaid,
          title: 'Expense paid',
          body: 'EXP-1 was paid',
          at: DateTime.now().subtract(const Duration(days: 3)),
          read: true,
          expenseId: 'e1',
        ),
      ],
    );
    when(() => notifications.markAllRead(any())).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpApp(
      const NotificationsPage(orgId: 'o1'),
      repositories: [
        RepositoryProvider<NotificationRepository>.value(value: notifications),
      ],
    );
    await tester.pumpAndSettle();
  }

  group(NotificationsPage, () {
    testWidgets('groups by day and opens what changed', (tester) async {
      await pump(tester);
      expect(find.text('Task returned'), findsOneWidget);
      expect(find.text('Expense paid'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('notification_n2')));
      await tester.pumpAndSettle();
      expect(find.text('route:/expenses/e1'), findsOneWidget);
    });

    testWidgets('reads all', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('notifications_read_all')));
      await tester.pumpAndSettle();
      verify(() => notifications.markAllRead('o1')).called(1);
      expect(find.byKey(const Key('notifications_read_all')), findsNothing);
    });
  });
}
