import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/tasks/data/task_repository.dart';
import 'package:solacliq/uploads/data/upload_repository.dart';
import 'package:uuid/uuid.dart';

class TaskState extends Equatable {
  const new({this.task, this.loading = true, this.busy = false, this.failure});

  final Task? task;

  /// The first load is running.
  final bool loading;

  /// An action (photo, submit, problem, reply) is running.
  final bool busy;

  /// Why the last load or action failed.
  final AuthFailureCode? failure;

  TaskState copyWith({
    Task? task,
    bool? loading,
    bool? busy,
    AuthFailureCode? Function()? failure,
  }) => TaskState(
    task: task ?? this.task,
    loading: loading ?? this.loading,
    busy: busy ?? this.busy,
    failure: failure == null ? this.failure : failure(),
  );

  @override
  List<Object?> get props => [task, loading, busy, failure];
}

/// One task as the worker works on it: shared by the task screen and the
/// proof camera, so photos taken show at once.
///
/// Photos taken and ticks made here are kept on top of what the server
/// returns until the task leaves the worker's hands (submitted, approved,
/// cancelled). A real server already reflects them; the development mock,
/// which keeps no state, does not.
class TaskCubit extends Cubit<TaskState> {
  new(this._tasks, this._uploads, {required this.orgId, required this.taskId})
    : super(const TaskState());

  final TaskRepository _tasks;
  final UploadRepository _uploads;
  final String orgId;
  final String taskId;

  /// The task as the server last sent it; what's shown adds local progress.
  Task? _server;
  final _photos = <String, ProofPhoto>{};
  final _checks = <String, bool>{};

  /// One per action, so a retry can't do it twice.
  String _submitKey = const Uuid().v4();
  String _problemKey = const Uuid().v4();

  Future<void> load() async {
    if (state.task == null) emit(state.copyWith(loading: true));
    await _run(() => _tasks.get(orgId, taskId), quiet: true);
  }

  Future<void> setChecklistItem(String itemId, {required bool done}) async {
    _checks[itemId] = done;
    _show(_server);
    await _run(
      () => _tasks.setChecklistItem(
        orgId: orgId,
        taskId: taskId,
        itemId: itemId,
        done: done,
      ),
      onError: () => _checks.remove(itemId),
    );
  }

  /// Uploads a photo just taken for [slotId] and attaches it with [fix].
  /// [localUrl] (`file:<path>`) shows it until the server's link arrives.
  /// Returns whether it worked.
  Future<bool> addPhoto({
    required String slotId,
    required UploadFile file,
    required CaptureFix fix,
    required String localUrl,
  }) => _run(() async {
    final uploadId = await _uploads.upload(file, UploadPurpose.proof);
    final task = await _tasks.addPhoto(
      orgId: orgId,
      taskId: taskId,
      slotId: slotId,
      uploadId: uploadId,
      fix: fix,
    );
    _photos[slotId] = ProofPhoto(
      url: localUrl,
      takenAt: fix.takenAt,
      accuracyM: fix.accuracyM,
    );
    return task;
  });

  Future<bool> submit({String? note}) async {
    final ok = await _run(
      () => _tasks.submit(
        orgId: orgId,
        taskId: taskId,
        idempotencyKey: _submitKey,
        note: note,
      ),
    );
    if (ok) _submitKey = const Uuid().v4();
    return ok;
  }

  Future<bool> reportProblem({
    required TaskProblemReason reason,
    required String note,
    UploadFile? photo,
  }) async {
    final ok = await _run(() async {
      final uploadId = photo == null
          ? null
          : await _uploads.upload(photo, UploadPurpose.proof);
      return await _tasks.reportProblem(
        orgId: orgId,
        taskId: taskId,
        idempotencyKey: _problemKey,
        reason: reason,
        note: note,
        uploadId: uploadId,
      );
    });
    if (ok) _problemKey = const Uuid().v4();
    return ok;
  }

  Future<bool> reply(String text) => _run(() async {
    await _tasks.reply(orgId: orgId, taskId: taskId, text: text);
    return _server!;
  });

  /// Runs [action], shows the task it returns, and records a failure.
  Future<bool> _run(
    Future<Task> Function() action, {
    bool quiet = false,
    void Function()? onError,
  }) async {
    if (!quiet) emit(state.copyWith(busy: true, failure: () => null));
    try {
      final task = await action();
      if (isClosed) return false;
      emit(state.copyWith(loading: false, busy: false, failure: () => null));
      _show(task);
      return true;
    } on UploadTooLarge {
      onError?.call();
      _fail(AuthFailureCode.validation);
      return false;
    } on AuthFailure catch (failure) {
      onError?.call();
      _fail(failure.code);
      return false;
    }
  }

  void _fail(AuthFailureCode code) {
    if (isClosed) return;
    emit(state.copyWith(loading: false, busy: false, failure: () => code));
    _show(_server);
  }

  void _show(Task? task) {
    if (task == null || isClosed) return;
    _server = task;
    if (!task.editable) {
      // Out of the worker's hands: the server's word is the whole story.
      _photos.clear();
      _checks.clear();
      emit(state.copyWith(task: task));
      return;
    }
    emit(
      state.copyWith(
        task: task.copyWith(
          photos: [
            for (final slot in task.photos)
              if (_photos[slot.id] case final local? when !slot.done)
                slot.withPhoto(local)
              else
                slot,
          ],
          checklist: [
            for (final item in task.checklist)
              if (_checks[item.id] case final done?)
                ChecklistItem(id: item.id, text: item.text, done: done)
              else
                item,
          ],
        ),
      ),
    );
  }
}
