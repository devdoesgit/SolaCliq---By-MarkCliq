import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solacliq/account/widgets/delete_account.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/tasks/view/location_note.dart';

import '../helpers/helpers.dart';

void main() {
  testWidgets('deleting asks for the password, and says when it is wrong', (
    tester,
  ) async {
    final auth = MockAuthRepository();
    when(() => auth.deleteAccount(password: any(named: 'password')))
        .thenThrow(const AuthFailure(AuthFailureCode.passwordIncorrect));
    await tester.pumpApp(
      const Scaffold(body: DeleteAccountLink()),
      authRepository: auth,
    );
    await tester.tapKey('delete_account');
    await tester.pumpAndSettle();
    await tester.tapKey('delete_account_confirm');
    await tester.pumpAndSettle();
    expect(find.text('Enter your password.'), findsOneWidget);
    verifyNever(() => auth.deleteAccount(password: any(named: 'password')));

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('delete_account_password')),
        matching: find.byType(TextField),
      ),
      'not-it',
    );
    await tester.tapKey('delete_account_confirm');
    await tester.pumpAndSettle();
    expect(find.text("That password isn't right."), findsOneWidget);
  });

  testWidgets('location is explained, and only Continue agrees', (
    tester,
  ) async {
    bool? agreed;
    await tester.pumpApp(
      Builder(
        builder: (context) => TextButton(
          key: const Key('open'),
          onPressed: () async => agreed = await showLocationNote(context),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tapKey('open');
    await tester.pumpAndSettle();
    expect(
      find.textContaining('only while this camera is open'),
      findsOneWidget,
    );
    await tester.tapKey('location_note_continue');
    await tester.pumpAndSettle();
    expect(agreed, isTrue);
  });
}
