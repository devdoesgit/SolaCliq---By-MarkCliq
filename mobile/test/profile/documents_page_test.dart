import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/profile/data/profile_repository.dart';
import 'package:solacliq/profile/view/documents_page.dart';
import 'package:solacliq/workspace/data/workspace.dart';

import '../helpers/helpers.dart';

void main() {
  late MockProfileRepository profiles;

  setUp(() => profiles = MockProfileRepository());

  Future<void> pump(WidgetTester tester, OrgRole role) async {
    await tester.pumpApp(
      DocumentsPage(workspace: MemberWorkspace(testMembership(role: role))),
      repositories: [
        RepositoryProvider<ProfileRepository>.value(value: profiles),
      ],
    );
    await tester.pumpAndSettle();
  }

  group(DocumentsPage, () {
    testWidgets("a worker's bank is there even when documents fail", (
      tester,
    ) async {
      when(() => profiles.documents(any())).thenAnswer(
        (_) async => throw const AuthFailure(AuthFailureCode.network),
      );
      await pump(tester, OrgRole.worker);
      expect(find.byKey(const Key('load_retry')), findsOneWidget);
      expect(find.byKey(const Key('documents_bank')), findsOneWidget);
    });

    testWidgets('a customer has no salary bank', (tester) async {
      when(() => profiles.documents(any())).thenAnswer(
        (_) async => throw const AuthFailure(AuthFailureCode.network),
      );
      await pump(tester, OrgRole.customer);
      expect(find.byKey(const Key('documents_bank')), findsNothing);
    });
  });
}
