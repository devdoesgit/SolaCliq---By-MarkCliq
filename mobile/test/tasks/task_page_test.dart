import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solacliq/tasks/cubit/task_cubit.dart';
import 'package:solacliq/tasks/cubit/tasks_cubit.dart';
import 'package:solacliq/tasks/data/task_repository.dart';
import 'package:solacliq/tasks/view/task_page.dart';
import 'package:solacliq/tasks/view/tasks_tab.dart';

import '../helpers/helpers.dart';
import 'task_fixtures.dart';

final _photo = ProofPhoto(url: 'asset:thumb-install', takenAt: DateTime(2026));

/// Every photo and step done.
Task readyTask({
  TaskStatus status = TaskStatus.assigned,
  TaskApproval? approved,
}) => assignedTask(
  status: status,
  approved: approved,
  photos: [ProofSlot(id: 'rails', label: 'Rails', photo: _photo)],
  checklist: const [ChecklistItem(id: 'a', text: 'Mount rails', done: true)],
);

void main() {
  late MockTaskRepository tasks;

  setUp(() {
    tasks = MockTaskRepository();
    when(() => tasks.history(any(), any())).thenAnswer((_) async => []);
  });

  Future<void> pumpTask(WidgetTester tester, Task task) async {
    when(() => tasks.get(any(), any())).thenAnswer((_) async => task);
    await tester.pumpApp(
      BlocProvider(
        create: (_) {
          final cubit = TaskCubit(
            tasks,
            MockUploadRepository(),
            orgId: 'o1',
            taskId: 't1',
          );
          unawaited(cubit.load());
          return cubit;
        },
        child: const TaskPage(),
      ),
      repositories: [RepositoryProvider<TaskRepository>.value(value: tasks)],
    );
    await tester.pumpAndSettle();
  }

  group(TaskPage, () {
    testWidgets('a task to do asks for the missing photos', (tester) async {
      await pumpTask(tester, assignedTask());
      expect(find.text('Panel installation'), findsWidgets);
      expect(find.byKey(const Key('task_submit')), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('task_add_photos')));
      await tester.tap(find.byKey(const Key('task_add_photos')));
      await tester.pumpAndSettle();
      expect(find.textContaining('route:/tasks/t1/camera'), findsOneWidget);
    });

    testWidgets('ticking a step tells the server', (tester) async {
      when(
        () => tasks.setChecklistItem(
          orgId: any(named: 'orgId'),
          taskId: any(named: 'taskId'),
          itemId: any(named: 'itemId'),
          done: any(named: 'done'),
        ),
      ).thenAnswer((_) async => assignedTask());
      await pumpTask(tester, assignedTask());
      await tester.ensureVisible(find.byKey(const ValueKey('check_b')));
      await tester.tap(find.byKey(const ValueKey('check_b')));
      await tester.pumpAndSettle();
      verify(
        () => tasks.setChecklistItem(
          orgId: 'o1',
          taskId: 't1',
          itemId: 'b',
          done: true,
        ),
      ).called(1);
    });

    testWidgets('a ready task submits and then waits for the admin', (
      tester,
    ) async {
      when(
        () => tasks.submit(
          orgId: any(named: 'orgId'),
          taskId: any(named: 'taskId'),
          idempotencyKey: any(named: 'idempotencyKey'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async => readyTask(status: TaskStatus.submitted));
      await pumpTask(tester, readyTask());
      await tester.tap(find.byKey(const Key('task_submit')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('task_submit')), findsNothing);
      expect(find.byKey(const Key('task_add_photos')), findsNothing);
    });

    testWidgets('a returned task asks for the retake', (tester) async {
      await pumpTask(
        tester,
        assignedTask(
          status: TaskStatus.returned,
          photos: [
            ProofSlot(id: 'clamp', label: 'Clamp', retake: true, photo: _photo),
          ],
          returned: TaskNote(
            text: 'Clamp is blurry',
            by: admin,
            at: DateTime(2026),
          ),
        ),
      );
      expect(find.text('Clamp is blurry'), findsOneWidget);
      await tester.tap(find.byKey(const Key('task_retake')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('route:/tasks/t1/camera?slot=clamp'),
        findsOneWidget,
      );
    });

    testWidgets('a cancelled task has nothing to do', (tester) async {
      await pumpTask(
        tester,
        assignedTask(
          status: TaskStatus.cancelled,
          cancelled: TaskNote(
            text: 'Postponed to December',
            by: admin,
            at: DateTime(2026),
          ),
        ),
      );
      expect(find.text('Postponed to December'), findsOneWidget);
      expect(find.byKey(const Key('task_submit')), findsNothing);
      expect(find.byKey(const Key('task_report_problem')), findsNothing);
    });

    testWidgets('an approved task offers the next one', (tester) async {
      await pumpTask(
        tester,
        readyTask(
          status: TaskStatus.approved,
          approved: TaskApproval(
            by: admin,
            at: DateTime(2026),
            nextTask: TaskSummary(
              id: 't2',
              reference: 'TSK-2',
              title: 'Wiring and inverter',
              status: TaskStatus.assigned,
              dueAt: DateTime(2026, 10, 24),
              customerName: 'Ramesh Sahoo',
            ),
          ),
        ),
      );
      expect(find.text('Wiring and inverter'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('next_task_t2')));
      await tester.tap(find.byKey(const ValueKey('next_task_t2')));
      await tester.pumpAndSettle();
      expect(find.text('route:/tasks/t2'), findsOneWidget);
    });
  });

  group(TasksTab, () {
    TaskSummary summary(String id, TaskStatus status, {bool problem = false}) =>
        TaskSummary(
          id: id,
          reference: 'TSK-$id',
          title: 'Task $id',
          status: status,
          dueAt: DateTime(2026, 10, 23, 10),
          customerName: 'Customer $id',
          hasProblem: problem,
        );

    setUp(() {
      registerFallbackValue(TaskView.today);
      when(() => tasks.list(any(), TaskView.today)).thenAnswer(
        (_) async => [
          summary('t1', TaskStatus.assigned, problem: true),
          summary('t2', TaskStatus.returned),
        ],
      );
      when(() => tasks.list(any(), TaskView.upcoming))
          .thenAnswer((_) async => [summary('t3', TaskStatus.assigned)]);
      when(() => tasks.list(any(), TaskView.done))
          .thenAnswer((_) async => [summary('t4', TaskStatus.approved)]);
    });

    test('the camera goes to the next open task without a problem', () async {
      final cubit = TasksCubit(tasks, orgId: 'o1');
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.nextForCamera!.id, 't2');
    });

    testWidgets('lists today and opens a task', (tester) async {
      final cubit = TasksCubit(tasks, orgId: 'o1');
      addTearDown(cubit.close);
      unawaited(cubit.load());
      await tester.pumpApp(
        BlocProvider.value(value: cubit, child: const TasksTab()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Customer t1'), findsOneWidget);
      expect(find.text('Customer t3'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('task_row_t2')));
      await tester.pumpAndSettle();
      expect(find.text('route:/tasks/t2'), findsOneWidget);
    });
  });
}
