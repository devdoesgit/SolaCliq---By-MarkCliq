import 'dart:convert';
import 'dart:io';

import 'package:api_client/api_client.dart' show TasksApi;
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solacliq/tasks/data/task_repository.dart';

import '../helpers/helpers.dart';

/// The contract's named task examples, so the app reads exactly what the
/// mock (and the server) will send. They are written as one-line JSON.
Map<String, Object?> _example(String name) {
  final lines = File('../api/openapi.yaml').readAsLinesSync();
  final at = lines.indexOf('    Task_$name:');
  final value = lines
      .skip(at)
      .firstWhere((l) => l.trimLeft().startsWith('value: '))
      .trimLeft()
      .substring('value: '.length);
  return jsonDecode(value) as Map<String, Object?>;
}

void main() {
  late List<RequestOptions> requests;

  TaskRepository repo(Object? Function(RequestOptions) body) {
    requests = [];
    final dio = Dio(BaseOptions(baseUrl: 'http://api'))
      ..httpClientAdapter = FakeAdapter((o) async {
        requests.add(o);
        return jsonBody(200, body(o));
      });
    return TaskRepository(TasksApi(dio));
  }

  group(TaskRepository, () {
    test('reads an assigned task with photos, checklist and note', () async {
      final task = await repo((_) => _example('assigned')).get('o1', 't1');
      expect(task.status, TaskStatus.assigned);
      expect(task.stageIndex, 3);
      expect(task.photos, hasLength(4));
      expect(task.photosDone, 2);
      expect(task.checklistDone, 2);
      expect(task.adminNote!.by.role, 'Admin');
      expect(task.customer.phone, '9814022671');
    });

    test('reads returns, problems, cancels and approvals', () async {
      final returned = await repo((_) => _example('returned')).get('o', 't');
      expect(returned.photos.where((p) => p.retake), hasLength(1));
      expect(returned.returned, isNotNull);

      final reported = await repo((_) => _example('reported')).get('o', 't');
      expect(reported.problem!.reason, TaskProblemReason.materialMissing);

      final cancelled = await repo((_) => _example('cancelled')).get('o', 't');
      expect(cancelled.status, TaskStatus.cancelled);

      final approved = await repo((_) => _example('approved')).get('o', 't');
      expect(approved.approved!.nextTask!.title, 'Wiring and inverter');
    });

    test('a photo carries where and when it was taken', () async {
      final r = repo((_) => _example('assigned'));
      await r.addPhoto(
        orgId: 'o1',
        taskId: 't1',
        slotId: 'clamp',
        uploadId: 'up-1',
        fix: CaptureFix(
          lat: 30.7,
          lng: 76.7,
          accuracyM: 8,
          takenAt: DateTime.utc(2026, 10, 23, 6),
          mocked: true,
        ),
      );
      final data = requests.single.data;
      final body =
          (data is String ? jsonDecode(data) : data) as Map<String, Object?>;
      expect(requests.single.path, '/orgs/o1/tasks/t1/photos');
      expect(body['slot_id'], 'clamp');
      expect(body['accuracy_m'], 8);
      expect(body['mocked_location'], isTrue);
      expect(body['taken_at'], '2026-10-23T06:00:00.000Z');
    });

    test('submit and problems send their idempotency keys', () async {
      final r = repo((_) => _example('submitted'));
      await r.submit(orgId: 'o', taskId: 't', idempotencyKey: 'k1');
      expect(requests.single.headers['Idempotency-Key'], 'k1');
    });

    test('lists by view', () async {
      final r = repo(
        (_) => {
          'items': [
            {
              'id': 't1',
              'reference': 'TSK-1',
              'title': 'Wiring',
              'status': 'returned',
              'due_at': '2026-10-23T04:00:00Z',
              'customer_name': 'Priya',
              'distance_km': 7.8,
            },
          ],
          'page': {'next_cursor': null},
        },
      );
      final items = await r.list('o1', TaskView.upcoming);
      expect(requests.single.queryParameters['view'], 'upcoming');
      expect(items.single.status, TaskStatus.returned);
      expect(items.single.distanceKm, 7.8);
    });
  });
}
