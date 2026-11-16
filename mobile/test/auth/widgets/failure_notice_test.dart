import 'package:flutter_test/flutter_test.dart';
import 'package:solacliq/auth/cubit/submit_cubit.dart';
import 'package:solacliq/auth/data/auth_failure.dart';
import 'package:solacliq/auth/widgets/failure_notice.dart';

import '../../helpers/helpers.dart';

void main() {
  const limited = SubmitState(
    status: SubmitStatus.failure,
    failure: AuthFailureCode.tooManyAttempts,
  );

  testWidgets('shows the usual text for a failure', (tester) async {
    await tester.pumpApp(const FailureNotice(state: limited));
    expect(
      find.text('Too many tries. Wait a few minutes and try again.'),
      findsOneWidget,
    );
  });

  testWidgets("shows a screen's own text when it gives one", (tester) async {
    await tester.pumpApp(
      FailureNotice(
        state: limited,
        messageFor: (failure) =>
            failure == AuthFailureCode.tooManyAttempts ? 'Daily limit' : null,
      ),
    );
    expect(find.text('Daily limit'), findsOneWidget);
  });

  testWidgets('falls back when the screen gives none', (tester) async {
    await tester.pumpApp(
      FailureNotice(state: limited, messageFor: (_) => null),
    );
    expect(
      find.text('Too many tries. Wait a few minutes and try again.'),
      findsOneWidget,
    );
  });
}
