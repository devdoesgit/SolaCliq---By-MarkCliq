/*
  Each role's main flow in the real app, against the real API and its seed
  ---------------------------------------------------------------------------
  - runs on the emulator: `make app-e2e` seeds the local API, then drives
    the app through log in and each role's main screens, with the same
    taps a person makes
  - one test per role; each logs out at the end, and starts by logging out
    if an earlier test stopped half way
  - the seed resets what these change (the expense, the claimed payment)
*/

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:solacliq/app/app.dart';

/// Pumps until [finder] shows, for up to [seconds]: network calls take real
/// time here, so pumpAndSettle alone isn't enough.
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  int seconds = 20,
}) async {
  for (var i = 0; i < seconds * 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  // What the screen says instead, to see why.
  final shown = find
      .byType(RichText)
      .evaluate()
      .map((e) => (e.widget as RichText).text.toPlainText())
      .where((t) => t.trim().isNotEmpty)
      .join(' | ');
  throw TestFailure('Not found after ${seconds}s: $finder\nOn screen: $shown');
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await waitFor(tester, finder);
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await waitFor(tester, finder);
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pump(const Duration(milliseconds: 300));
}

Finder field(String key) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byType(EditableText),
);

Future<void> start(WidgetTester tester) async {
  await tester.pumpWidget(App(config: AppConfig.development()));
  // Either the welcome screen, or a home left by a test that stopped half way.
  final welcome = find.byKey(const ValueKey('welcome_get_started'));
  final home = find.byKey(const ValueKey('tab_profile'));
  await waitFor(
    tester,
    find.byWidgetPredicate(
      (w) =>
          w.key == const ValueKey('welcome_get_started') ||
          w.key == const ValueKey('tab_profile'),
    ),
  );
  if (welcome.evaluate().isEmpty && home.evaluate().isNotEmpty) {
    await logOut(tester);
  }
}

Future<void> logIn(WidgetTester tester, String email) async {
  await tapKey(tester, 'welcome_get_started');
  await tapKey(tester, 'intro_skip');
  await waitFor(tester, field('login_email'));
  await tester.enterText(field('login_email'), email);
  await tester.enterText(field('login_password'), 'sunlight1');
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tapKey(tester, 'login_submit');
}

Future<void> logOut(WidgetTester tester) async {
  await tapKey(tester, 'tab_profile');
  await tapKey(tester, 'log_out');
  await waitFor(tester, find.byKey(const ValueKey('welcome_get_started')));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('an installer sees the day and logs an expense', (tester) async {
    await start(tester);
    await logIn(tester, 'ravi@example.com');
    await waitFor(tester, find.textContaining("'s day"));
    expect(find.text('Up next'), findsOneWidget);

    // Today's tasks, from the seed.
    await tapKey(tester, 'tab_tasks');
    // Each row: the customer, then "Panel installation · 10:00".
    final row = find.textContaining('Panel installation');
    await waitFor(tester, row);
    await tester.tap(row.first);
    await tester.pump(const Duration(milliseconds: 300));
    await waitFor(tester, find.text('Mount rails on structure'));
    await tapKey(tester, 'nav_back');

    // ₹450 for material, sent to the admin.
    await tapKey(tester, 'tab_expenses');
    await tapKey(tester, 'expenses_log');
    for (final k in ['4', '5', '0']) {
      await tapKey(tester, 'keypad_$k');
    }
    await tapText(tester, 'Material');
    await tester.enterText(field('expense_note'), 'Earthing clamps');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tapKey(tester, 'expense_submit');
    // Numbered after the seed's (EXP-0005 on a fresh seed; numbers are
    // never reused, so later runs count on).
    await waitFor(tester, find.text('Sent to admin'));
    expect(find.textContaining('· ₹450'), findsWidgets);
    await tapKey(tester, 'expense_sent_home');
    await logOut(tester);
  });

  testWidgets('an installer starts and ends the day', (tester) async {
    await start(tester);
    await logIn(tester, 'ravi@example.com');
    // The seed clears today's attendance.
    await waitFor(tester, find.text('Not started'));
    await tapKey(tester, 'attendance_start');
    await waitFor(tester, find.textContaining('Working since'));
    expect(find.byKey(const ValueKey('attendance_waiting')), findsNothing);

    // The server has it: after a refresh it's still started.
    await logOut(tester);
    await logIn(tester, 'ravi@example.com');
    await waitFor(tester, find.textContaining('Working since'));

    // Ending asks first.
    await tapKey(tester, 'attendance_end');
    await tapText(tester, 'Keep working');
    expect(find.textContaining('Working since'), findsOneWidget);
    await tapKey(tester, 'attendance_end');
    await tapKey(tester, 'attendance_end_confirm');
    await waitFor(tester, find.text('Day ended'));
    expect(find.byKey(const ValueKey('attendance_start')), findsNothing);
    await logOut(tester);
  });

  testWidgets('salaried sales mark attendance too', (tester) async {
    await start(tester);
    await logIn(tester, 'aman@example.com');
    await waitFor(tester, find.text('Not started'));
    expect(find.byKey(const ValueKey('attendance_start')), findsOneWidget);
    await logOut(tester);
  });

  testWidgets('an agent follows customers and sees a returned document', (
    tester,
  ) async {
    await start(tester);
    await logIn(tester, 'meena@example.com');
    await waitFor(tester, find.textContaining("'s customers"));
    expect(find.text('₹5,000'), findsOneWidget, reason: 'earnings: payable');
    // Commission agents don't mark attendance (F17).
    expect(find.byKey(const ValueKey('attendance_card')), findsNothing);

    await tapKey(tester, 'tab_customers');
    await tapText(tester, 'Sunita Rao (illustrative)');
    await waitFor(tester, find.textContaining('Returned'));
    expect(find.textContaining('Bill photo is blurry'), findsWidgets);
    await tapKey(tester, 'nav_back');

    // Not taken up: its own status, no install shown.
    await tapText(tester, 'Harpal Singh (illustrative)');
    await waitFor(tester, find.text('The roof is shaded most of the day.'));
    expect(find.text('Install progress'), findsNothing);
    await tapKey(tester, 'nav_back');
    await logOut(tester);
  });

  testWidgets('a customer follows the install and claims a payment', (
    tester,
  ) async {
    await start(tester);
    await logIn(tester, 'rajinder@example.com');
    await waitFor(tester, find.text('of 7 stages'));
    expect(find.text('Structure is next'), findsOneWidget);

    await tapKey(tester, 'tab_track');
    await waitFor(tester, find.text('1. Site survey'));
    expect(find.text('2. Structure'), findsOneWidget);

    // The installation payment, paid by bank transfer: now with the company.
    await tapKey(tester, 'tab_payments');
    await waitFor(tester, find.text('₹2,85,000'));
    await tapKey(tester, 'pay_bank');
    await waitFor(tester, find.text('Payment sent'));
    expect(find.text('Confirming'), findsOneWidget);
    await logOut(tester);
  });
}
