import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solacliq/app/router.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/tasks/cubit/task_cubit.dart';
import 'package:solacliq/tasks/data/task_repository.dart';
import 'package:solacliq/uploads/data/upload_repository.dart';
import 'package:solacliq/workspace/data/workspace.dart';

import '../helpers/helpers.dart';

/// Shows which cubit the task's route was given.
class _Shows extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) =>
      Text('cubit ${identityHashCode(context.watch<TaskCubit>())}');
}

/*
  QA-01: the same task route built once with the task screen's cubit
  (`extra`) and once without must not crash ("Rebuilt
  _InheritedProviderScope using a different constructor")
*/
void main() {
  testWidgets('a task route switches between a shared and its own cubit', (
    tester,
  ) async {
    final tasks = MockTaskRepository();
    when(() => tasks.get(any(), any()))
        .thenThrow(const AuthFailure(AuthFailureCode.network));
    final uploads = MockUploadRepository();
    final shared = TaskCubit(tasks, uploads, orgId: 'o1', taskId: 't1');
    addTearDown(shared.close);
    final workspace = MemberWorkspace(testMembership());

    final router = GoRouter(
      initialLocation: '/tasks/t1',
      initialExtra: shared,
      routes: [
        GoRoute(
          path: '/tasks/:id',
          builder: (context, state) =>
              taskScope(context, state, workspace, const _Shows()),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<TaskRepository>.value(value: tasks),
          RepositoryProvider<UploadRepository>.value(value: uploads),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('cubit ${identityHashCode(shared)}'), findsOneWidget);

    // The same route again, without `extra`: its own cubit, no crash.
    router.go('/tasks/t1');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('cubit ${identityHashCode(shared)}'), findsNothing);
    expect(find.textContaining('cubit '), findsOneWidget);

    // And back to the shared one.
    router.go('/tasks/t1', extra: shared);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('cubit ${identityHashCode(shared)}'), findsOneWidget);
  });
}
