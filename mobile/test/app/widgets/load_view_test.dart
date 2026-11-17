import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:solacliq/app/widgets/load_view.dart';
import 'package:solacliq/auth/auth.dart';

import '../../helpers/helpers.dart';

void main() {
  Widget view(Future<String> future) => LoadView<String>(
    future: future,
    failedTitle: 'Could not load',
    onRetry: () {},
    builder: (context, data) => Text(data),
    notReadyCode: AuthFailureCode.installNotStarted,
    notReady: const Text('Being set up'),
  );

  // Shows the view, then fails its load, as a request would.
  Future<void> failWith(WidgetTester tester, AuthFailureCode code) async {
    final load = Completer<String>();
    await tester.pumpApp(view(load.future));
    load.completeError(AuthFailure(code));
    await tester.pumpAndSettle();
  }

  group(LoadView, () {
    testWidgets('"not there yet" shows its own view, no error or retry', (
      tester,
    ) async {
      await failWith(tester, AuthFailureCode.installNotStarted);
      expect(find.text('Being set up'), findsOneWidget);
      expect(find.text('Could not load'), findsNothing);
      expect(find.byKey(const Key('load_retry')), findsNothing);
    });

    testWidgets('any other failure still offers a retry', (tester) async {
      await failWith(tester, AuthFailureCode.network);
      expect(find.text('Could not load'), findsOneWidget);
      expect(find.byKey(const Key('load_retry')), findsOneWidget);
    });
  });
}
