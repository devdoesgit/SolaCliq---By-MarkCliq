import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/tasks/cubit/task_cubit.dart';
import 'package:solacliq/tasks/data/task_repository.dart';
import 'package:solacliq/uploads/data/upload_repository.dart';

import '../helpers/helpers.dart';
import 'task_fixtures.dart';

void main() {
  late MockTaskRepository tasks;
  late MockUploadRepository uploads;
  final file = UploadFile(name: 'p.jpg', bytes: Uint8List(3));
  final fix = CaptureFix(
    lat: 30.7,
    lng: 76.7,
    accuracyM: 8,
    takenAt: DateTime.utc(2026, 10, 23, 6),
  );

  setUpAll(() {
    registerFallbackValue(file);
    registerFallbackValue(UploadPurpose.proof);
    registerFallbackValue(fix);
    registerFallbackValue(TaskProblemReason.other);
  });

  setUp(() {
    tasks = MockTaskRepository();
    uploads = MockUploadRepository();
    when(() => tasks.get(any(), any())).thenAnswer((_) async => assignedTask());
  });

  TaskCubit build() => TaskCubit(tasks, uploads, orgId: 'o1', taskId: 't1');

  group(TaskCubit, () {
    blocTest<TaskCubit, TaskState>(
      'loads the task',
      build: build,
      act: (c) => c.load(),
      verify: (c) {
        expect(c.state.loading, isFalse);
        expect(c.state.task!.photosDone, 1);
      },
    );

    blocTest<TaskCubit, TaskState>(
      'a photo is uploaded as proof, attached with its fix, and shown even '
      'if the server has not caught up',
      setUp: () {
        when(() => uploads.upload(any(), any()))
            .thenAnswer((_) async => 'up-1');
        // A server that keeps no state, like the mock.
        when(
          () => tasks.addPhoto(
            orgId: any(named: 'orgId'),
            taskId: any(named: 'taskId'),
            slotId: any(named: 'slotId'),
            uploadId: any(named: 'uploadId'),
            fix: any(named: 'fix'),
          ),
        ).thenAnswer((_) async => assignedTask());
      },
      build: build,
      act: (c) async {
        await c.load();
        await c.addPhoto(
          slotId: 'clamp',
          file: file,
          fix: fix,
          localUrl: 'file:/tmp/p.jpg',
        );
      },
      verify: (c) {
        verify(() => uploads.upload(file, UploadPurpose.proof)).called(1);
        verify(
          () => tasks.addPhoto(
            orgId: 'o1',
            taskId: 't1',
            slotId: 'clamp',
            uploadId: 'up-1',
            fix: fix,
          ),
        ).called(1);
        final task = c.state.task!;
        expect(task.photosDone, 2);
        expect(task.photos.last.photo!.url, 'file:/tmp/p.jpg');
      },
    );

    blocTest<TaskCubit, TaskState>(
      'a tick shows at once and is undone if the server refuses it',
      setUp: () => when(
        () => tasks.setChecklistItem(
          orgId: any(named: 'orgId'),
          taskId: any(named: 'taskId'),
          itemId: any(named: 'itemId'),
          done: any(named: 'done'),
        ),
      ).thenThrow(const AuthFailure(AuthFailureCode.network)),
      build: build,
      act: (c) async {
        await c.load();
        await c.setChecklistItem('b', done: true);
      },
      verify: (c) {
        expect(c.state.task!.checklistDone, 1);
        expect(c.state.failure, AuthFailureCode.network);
      },
    );

    blocTest<TaskCubit, TaskState>(
      'a retried submit reuses its key; once the task leaves the worker, '
      'the server is the whole story',
      setUp: () {
        var attempts = 0;
        when(
          () => tasks.submit(
            orgId: any(named: 'orgId'),
            taskId: any(named: 'taskId'),
            idempotencyKey: any(named: 'idempotencyKey'),
            note: any(named: 'note'),
          ),
        ).thenAnswer((_) async {
          if (attempts++ == 0) {
            throw const AuthFailure(AuthFailureCode.network);
          }
          return assignedTask(status: TaskStatus.submitted);
        });
      },
      build: build,
      act: (c) async {
        await c.load();
        await c.submit(note: 'done');
        await c.submit(note: 'done');
      },
      verify: (c) {
        final keys = verify(
          () => tasks.submit(
            orgId: 'o1',
            taskId: 't1',
            idempotencyKey: captureAny(named: 'idempotencyKey'),
            note: 'done',
          ),
        ).captured;
        expect(keys, hasLength(2));
        expect(keys.first, keys.last);
        expect(c.state.task!.status, TaskStatus.submitted);
      },
    );

    blocTest<TaskCubit, TaskState>(
      'a problem goes with its reason and note',
      setUp: () =>
          when(
            () => tasks.reportProblem(
              orgId: any(named: 'orgId'),
              taskId: any(named: 'taskId'),
              idempotencyKey: any(named: 'idempotencyKey'),
              reason: any(named: 'reason'),
              note: any(named: 'note'),
              uploadId: any(named: 'uploadId'),
            ),
          ).thenAnswer(
            (_) async => assignedTask(
              problem: TaskProblem(
                reason: TaskProblemReason.materialMissing,
                note: 'Short by 6',
                at: DateTime.utc(2026, 10, 23),
              ),
            ),
          ),
      build: build,
      act: (c) => c.reportProblem(
        reason: TaskProblemReason.materialMissing,
        note: 'Short by 6',
      ),
      verify: (c) => expect(c.state.task!.problem, isNotNull),
    );
  });

  group('Task', () {
    test('ready once every photo and step is in', () {
      expect(assignedTask().ready, isFalse);
      final full = assignedTask(
        photos: [
          ProofSlot(
            id: 'x',
            label: 'X',
            photo: ProofPhoto(url: 'u', takenAt: DateTime.utc(2026)),
          ),
        ],
        checklist: const [ChecklistItem(id: 'a', text: 'A', done: true)],
      );
      expect(full.ready, isTrue);
      expect(assignedTask(status: TaskStatus.submitted).editable, isFalse);
    });

    test('a photo to retake counts as missing', () {
      final task = assignedTask(
        photos: [
          ProofSlot(
            id: 'x',
            label: 'X',
            retake: true,
            photo: ProofPhoto(url: 'u', takenAt: DateTime.utc(2026)),
          ),
        ],
      );
      expect(task.photosDone, 0);
      expect(task.nextSlot!.id, 'x');
    });
  });
}
