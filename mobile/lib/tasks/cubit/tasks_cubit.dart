import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/tasks/data/task_repository.dart';

class TasksState extends Equatable {
  const new({this.lists = const {}, this.failure, this.loading = true});

  /// Each view's tasks, once loaded.
  final Map<TaskView, List<TaskSummary>> lists;
  final AuthFailureCode? failure;
  final bool loading;

  @override
  List<Object?> get props => [lists, failure, loading];
}

/// The worker's task lists: today, upcoming and done.
class TasksCubit extends Cubit<TasksState> {
  new(this._tasks, {required this.orgId}) : super(const TasksState());

  final TaskRepository _tasks;
  final String orgId;

  /// Loads all three lists, so each tab's count is known.
  Future<void> load() async {
    try {
      final lists = await Future.wait([
        for (final view in TaskView.values) _tasks.list(orgId, view),
      ]);
      if (isClosed) return;
      emit(
        TasksState(
          lists: {
            for (final (i, view) in TaskView.values.indexed) view: lists[i],
          },
          loading: false,
        ),
      );
    } on AuthFailure catch (failure) {
      if (isClosed) return;
      emit(
        TasksState(lists: state.lists, failure: failure.code, loading: false),
      );
    }
  }

  /// The next task that still needs photos, for the camera tab.
  TaskSummary? get nextForCamera {
    for (final task in state.lists[TaskView.today] ?? const <TaskSummary>[]) {
      final open =
          task.status == TaskStatus.assigned ||
          task.status == TaskStatus.returned;
      if (open && !task.hasProblem) return task;
    }
    return null;
  }
}
