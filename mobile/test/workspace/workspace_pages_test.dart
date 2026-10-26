import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solacliq/app/dev/mock_persona.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/workspace/cubit/workspace_cubit.dart';
import 'package:solacliq/workspace/data/workspace.dart';
import 'package:solacliq/workspace/view/admin_only_page.dart';
import 'package:solacliq/workspace/view/workspace_sheet.dart';

import '../helpers/helpers.dart';

void main() {
  late MockWorkspaceCubit workspace;
  late MockAuthRepository auth;

  final worker = testMembership();
  final agent = testMembership(
    orgId: 'o2',
    orgName: 'Sample Rooftops',
    role: OrgRole.agent,
  );

  setUpAll(() => registerFallbackValue(MemberWorkspace(testMembership())));

  setUp(() {
    workspace = MockWorkspaceCubit();
    auth = MockAuthRepository();
    when(() => workspace.choose(any())).thenAnswer((_) async {});
    when(() => auth.logOut()).thenAnswer((_) async {});
    when(() => auth.refreshAccount(force: any(named: 'force')))
        .thenAnswer((_) async {});
  });

  group(AdminOnlyPage, () {
    testWidgets('points to the website and copies its address', (tester) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      when(() => workspace.state).thenReturn(
        WorkspaceAdminOnly(
          testAccount(memberships: [testMembership(role: OrgRole.orgAdmin)]),
        ),
      );
      await tester.pumpApp(
        const AdminOnlyPage(),
        workspaceCubit: workspace,
        authRepository: auth,
      );
      expect(find.textContaining('Example Solar'), findsOneWidget);
      final url = testConfig.websiteUrl;
      expect(find.text(url), findsOneWidget);
      await tester.tapKey('admin_copy_address');
      await tester.pump();
      expect(copied, [url]);
      expect(find.text('Address copied'), findsOneWidget);
    });

    testWidgets('logs out', (tester) async {
      when(() => workspace.state).thenReturn(WorkspaceAdminOnly(testAccount()));
      await tester.pumpApp(
        const AdminOnlyPage(),
        workspaceCubit: workspace,
        authRepository: auth,
      );
      await tester.tapKey('log_out');
      verify(() => auth.logOut()).called(1);
    });
  });

  group('workspace sheet', () {
    Future<void> openSheet(WidgetTester tester, WorkspaceReady state) async {
      when(() => workspace.state).thenReturn(state);
      await tester.pumpApp(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('open'),
              onPressed: () => showWorkspaceSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
        workspaceCubit: workspace,
        authRepository: auth,
      );
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
    }

    final options = [
      MemberWorkspace(worker),
      MemberWorkspace(agent),
      const PersonalWorkspace(),
    ];
    final ready = WorkspaceReady(
      testAccount(memberships: [worker, agent]),
      options.first,
      options,
    );

    testWidgets('lists every workspace and switches on tap', (tester) async {
      await openSheet(tester, ready);
      expect(find.text('Workspaces'), findsOneWidget);
      expect(find.text('Sample Rooftops'), findsOneWidget);
      expect(find.byKey(const Key('workspace_personal')), findsOneWidget);
      await tester.tapKey('workspace_o2:agent');
      await tester.pumpAndSettle();
      verify(() => workspace.choose(MemberWorkspace(agent))).called(1);
      expect(find.text('Workspaces'), findsNothing);
    });

    testWidgets('logs out', (tester) async {
      await openSheet(tester, ready);
      await tester.tapKey('workspace_log_out');
      await tester.pumpAndSettle();
      verify(() => auth.logOut()).called(1);
    });

    testWidgets('dev: picking a mock person re-reads the account', (
      tester,
    ) async {
      final persona = MockPersonaInterceptor();
      addTearDown(persona.dispose);
      when(() => workspace.state).thenReturn(ready);
      await tester.pumpApp(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('open'),
              onPressed: () => showWorkspaceSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
        workspaceCubit: workspace,
        authRepository: auth,
        persona: persona,
      );
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
      await tester.tapKey('dev_persona');
      await tester.pumpAndSettle();
      await tester.tapKey('dev_persona_agent');
      await tester.pumpAndSettle();
      expect(persona.persona.value, MockPersona.agent);
      verify(() => auth.refreshAccount(force: true)).called(1);
    });
  });
}
