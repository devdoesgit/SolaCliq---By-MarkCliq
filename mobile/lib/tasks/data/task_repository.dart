import 'package:api_client/api_client.dart' as api;
import 'package:solacliq/app/data/api_call.dart';
import 'package:solacliq/tasks/data/task_models.dart';

export 'task_models.dart';

/// A worker's tasks in one company: lists, detail, photos, checklist,
/// submitting, problems, replies and history.
class TaskRepository {
  new(this._api);

  final api.TasksApi _api;

  Future<List<TaskSummary>> list(String orgId, TaskView view) async {
    final response = await apiCall(
      () => _api.listMyTasks(orgId: orgId, view: view.name),
    );
    return [for (final t in response.data!.items) _summary(t)];
  }

  Future<Task> get(String orgId, String taskId) async {
    final response = await apiCall(
      () => _api.getTask(orgId: orgId, taskId: taskId),
    );
    return _task(response.data!);
  }

  /// Attaches the uploaded photo to [slotId], with where and when it was
  /// taken.
  Future<Task> addPhoto({
    required String orgId,
    required String taskId,
    required String slotId,
    required String uploadId,
    required CaptureFix fix,
  }) async {
    final response = await apiCall(
      () => _api.addTaskPhoto(
        orgId: orgId,
        taskId: taskId,
        proofPhotoCreate: api.ProofPhotoCreate(
          slotId: slotId,
          uploadId: uploadId,
          takenAt: fix.takenAt.toUtc(),
          lat: fix.lat,
          lng: fix.lng,
          accuracyM: fix.accuracyM,
          mockedLocation: fix.mocked,
        ),
      ),
    );
    return _task(response.data!);
  }

  Future<Task> setChecklistItem({
    required String orgId,
    required String taskId,
    required String itemId,
    required bool done,
  }) async {
    final response = await apiCall(
      () => _api.setTaskChecklistItem(
        orgId: orgId,
        taskId: taskId,
        itemId: itemId,
        setTaskChecklistItemRequest: api.SetTaskChecklistItemRequest(
          done: done,
        ),
      ),
    );
    return _task(response.data!);
  }

  /// Pass the same [idempotencyKey] when retrying.
  Future<Task> submit({
    required String orgId,
    required String taskId,
    required String idempotencyKey,
    String? note,
  }) async {
    final response = await apiCall(
      () => _api.submitTask(
        orgId: orgId,
        taskId: taskId,
        idempotencyKey: idempotencyKey,
        submitTaskRequest: api.SubmitTaskRequest(note: note),
      ),
    );
    return _task(response.data!);
  }

  /// Pass the same [idempotencyKey] when retrying.
  Future<Task> reportProblem({
    required String orgId,
    required String taskId,
    required String idempotencyKey,
    required TaskProblemReason reason,
    required String note,
    String? uploadId,
  }) async {
    final response = await apiCall(
      () => _api.reportTaskProblem(
        orgId: orgId,
        taskId: taskId,
        idempotencyKey: idempotencyKey,
        taskProblemCreate: api.TaskProblemCreate(
          reason: api.TaskProblemReason.values.byName(reason.name),
          note: note,
          uploadId: uploadId,
        ),
      ),
    );
    return _task(response.data!);
  }

  Future<void> reply({
    required String orgId,
    required String taskId,
    required String text,
  }) => apiCall(
    () => _api.sendTaskMessage(
      orgId: orgId,
      taskId: taskId,
      sendTaskMessageRequest: api.SendTaskMessageRequest(text: text),
    ),
  );

  Future<List<TaskEvent>> history(String orgId, String taskId) async {
    final response = await apiCall(
      () => _api.getTaskHistory(orgId: orgId, taskId: taskId),
    );
    return [
      for (final e in response.data!.events)
        TaskEvent(
          kind: TaskEventKind.values.byName(e.kind.name),
          actor: _person(e.actor),
          at: e.at,
          detail: e.detail,
        ),
    ];
  }

  Future<WorkerStats> stats(String orgId) async {
    final response = await apiCall(() => _api.getMyStats(orgId: orgId));
    final s = response.data!;
    return WorkerStats(
      tasksThisMonth: s.tasksThisMonth,
      returnedThisMonth: s.returnedThisMonth,
      avgMinutesOnSite: s.avgMinutesOnSite,
    );
  }

  static TaskStatus _status(api.TaskStatus s) =>
      TaskStatus.values.byName(s.name);

  static TaskPerson _person(api.Person p) =>
      TaskPerson(name: p.name, role: p.role, you: p.you ?? false);

  static TaskNote? _note(api.TaskNote? n) =>
      n == null ? null : TaskNote(text: n.text, by: _person(n.by), at: n.at);

  static TaskSummary _summary(api.TaskSummary t) => TaskSummary(
    id: t.id,
    reference: t.reference,
    title: t.title,
    status: _status(t.status),
    dueAt: t.dueAt,
    customerName: t.customerName,
    image: t.image,
    distanceKm: t.distanceKm?.toDouble(),
    statusAt: t.statusAt,
    hasProblem: t.hasProblem ?? false,
  );

  static Task _task(api.Task t) {
    final problem = t.problem;
    final approved = t.approved;
    final next = approved?.nextTask;
    return Task(
      id: t.id,
      reference: t.reference,
      title: t.title,
      status: _status(t.status),
      dueAt: t.dueAt,
      stageIndex: t.stage.index,
      stageCount: t.stage.count,
      customer: TaskCustomer(
        name: t.customer.name,
        address: t.customer.address,
        systemKw: t.customer.systemKw?.toDouble(),
        phone: t.customer.phone,
        lat: t.customer.lat?.toDouble(),
        lng: t.customer.lng?.toDouble(),
      ),
      photos: [
        for (final s in t.photos)
          ProofSlot(
            id: s.id,
            label: s.label,
            hint: s.hint,
            retake: s.retake ?? false,
            photo: s.photo == null
                ? null
                : ProofPhoto(
                    url: s.photo!.url,
                    takenAt: s.photo!.takenAt,
                    accuracyM: s.photo!.accuracyM?.toDouble(),
                  ),
          ),
      ],
      checklist: [
        for (final c in t.checklist)
          ChecklistItem(id: c.id, text: c.text, done: c.done),
      ],
      assignedBy: t.assignedBy == null ? null : _person(t.assignedBy!),
      adminNote: _note(t.adminNote),
      submittedAt: t.submittedAt,
      workerNote: t.workerNote,
      returned: _note(t.returned),
      problem: problem == null
          ? null
          : TaskProblem(
              reason: TaskProblemReason.values.byName(problem.reason.name),
              note: problem.note,
              at: problem.at,
            ),
      cancelled: _note(t.cancelled),
      approved: approved == null
          ? null
          : TaskApproval(
              by: _person(approved.by),
              at: approved.at,
              nextTask: next == null ? null : _summary(next),
            ),
    );
  }
}
