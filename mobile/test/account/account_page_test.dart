import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solacliq/account/view/account_page.dart';
import 'package:solacliq/auth/auth.dart';

import '../helpers/helpers.dart';

void main() {
  late MockAuthRepository auth;

  void signedIn(Account account) {
    when(() => auth.status).thenReturn(AuthAuthenticated(account));
    when(() => auth.statusChanges).thenAnswer((_) => const Stream.empty());
  }

  setUp(() => auth = MockAuthRepository());

  testWidgets('a new customer sees the empty message', (tester) async {
    signedIn(
      const Account(
        id: '1',
        name: 'Asha',
        email: 'asha@example.com',
        isPlatformAdmin: false,
        memberships: [],
      ),
    );
    await tester.pumpApp(const AccountPage(), authRepository: auth);
    expect(find.text('HELLO, ASHA'), findsOneWidget);
    expect(find.textContaining('Your account is ready'), findsOneWidget);
  });

  testWidgets('lists memberships with role and org status', (tester) async {
    signedIn(
      const Account(
        id: '1',
        name: 'Ravi',
        email: 'ravi@example.com',
        isPlatformAdmin: false,
        memberships: [
          AccountMembership(
            orgId: 'o1',
            orgName: 'Example Solar',
            orgStatus: OrgStatus.active,
            role: OrgRole.worker,
          ),
        ],
      ),
    );
    await tester.pumpApp(const AccountPage(), authRepository: auth);
    expect(find.text('Example Solar'), findsOneWidget);
    expect(find.text('INSTALLER'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
  });

  testWidgets('log out calls the repository once', (tester) async {
    signedIn(
      const Account(
        id: '1',
        name: 'Asha',
        email: 'asha@example.com',
        isPlatformAdmin: false,
        memberships: [],
      ),
    );
    when(() => auth.logOut()).thenAnswer((_) async {});
    await tester.pumpApp(const AccountPage(), authRepository: auth);
    await tester.tap(find.byKey(const Key('account_log_out')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('account_log_out')));
    verify(() => auth.logOut()).called(1);
  });
}
