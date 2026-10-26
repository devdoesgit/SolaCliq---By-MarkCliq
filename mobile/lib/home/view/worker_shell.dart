import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/expenses/view/expenses_tab.dart';
import 'package:solacliq/home/view/org_home.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/profile/view/profile_tab.dart';
import 'package:solacliq/tasks/cubit/tasks_cubit.dart';
import 'package:solacliq/tasks/data/task_repository.dart';
import 'package:solacliq/tasks/view/tasks_tab.dart';
import 'package:solacliq/workspace/data/workspace.dart';

/// The worker's tabs, left to right; the camera in the middle is an action.
enum WorkerTab { home, tasks, expenses, profile }

/// A worker's app: home, tasks, the proof camera, expenses and profile,
/// under one tab bar. Each tab keeps its place while another is shown.
class WorkerShell extends StatelessWidget {
  const new({
    required this.account,
    required this.workspace,
    required this.canSwitch,
    super.key,
  });

  final Account account;
  final MemberWorkspace workspace;
  final bool canSwitch;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = TasksCubit(
          context.read<TaskRepository>(),
          orgId: workspace.orgId,
        );
        unawaited(cubit.load());
        return cubit;
      },
      child: WorkerShellView(
        account: account,
        workspace: workspace,
        canSwitch: canSwitch,
      ),
    );
  }
}

class WorkerShellView extends StatefulWidget {
  const new({
    required this.account,
    required this.workspace,
    required this.canSwitch,
    super.key,
  });

  final Account account;
  final MemberWorkspace workspace;
  final bool canSwitch;

  @override
  State<WorkerShellView> createState() => _WorkerShellViewState();
}

class _WorkerShellViewState extends State<WorkerShellView> {
  WorkerTab _tab = WorkerTab.home;
  TaskView _tasksView = TaskView.today;
  final _expenses = GlobalKey<ExpensesTabState>();

  void _go(WorkerTab tab, {TaskView? view}) {
    setState(() {
      _tab = tab;
      if (view != null) _tasksView = view;
    });
    // Fresh lists each time a tab is opened.
    switch (tab) {
      case WorkerTab.tasks:
        unawaited(context.read<TasksCubit>().load());
      case WorkerTab.expenses:
        unawaited(_expenses.currentState?.reload());
      case WorkerTab.home || WorkerTab.profile:
        break;
    }
  }

  /// What the home's tiles, rows and avatar ask for.
  void _open(String action) => switch (action) {
    'to_submit' || 'see_all' => _go(WorkerTab.tasks),
    'expenses' => _go(WorkerTab.expenses),
    'profile' => _go(WorkerTab.profile),
    _ => null,
  };

  /// The camera for the next task with photos to take, else the tasks.
  Future<void> _camera() async {
    final tasks = context.read<TasksCubit>();
    if (tasks.state.loading) await tasks.load();
    final next = tasks.nextForCamera;
    if (!mounted) return;
    if (next == null) {
      _go(WorkerTab.tasks);
      return;
    }
    await context.push(AppRoutes.taskCamera(next.id, fromTab: true));
    if (mounted) unawaited(tasks.load());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      SolaTabItem(
        key: const ValueKey('tab_home'),
        label: l10n.tabHome,
        icon: SolaIcons.home,
      ),
      SolaTabItem(
        key: const ValueKey('tab_tasks'),
        label: l10n.tabTasks,
        icon: SolaIcons.list,
      ),
      SolaTabItem(
        key: const ValueKey('tab_upload_proof'),
        label: l10n.tabUploadProof,
        icon: SolaIcons.camera,
        raised: true,
      ),
      SolaTabItem(
        key: const ValueKey('tab_expenses'),
        label: l10n.tabExpenses,
        icon: SolaIcons.receipt,
      ),
      SolaTabItem(
        key: const ValueKey('tab_profile'),
        label: l10n.tabProfile,
        icon: SolaIcons.user,
      ),
    ];
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _tab.index,
        children: [
          OrgHome(
            account: widget.account,
            workspace: widget.workspace,
            canSwitch: widget.canSwitch,
            onOpen: _open,
          ),
          TasksTab(initialView: _tasksView),
          ExpensesTab(key: _expenses, orgId: widget.workspace.orgId),
          ProfileTab(
            account: widget.account,
            workspace: widget.workspace,
            onTaskHistory: () => _go(WorkerTab.tasks, view: TaskView.done),
          ),
        ],
      ),
      bottomNavigationBar: SolaTabBar(
        items: items,
        // The raised camera sits at index 2 and is never "selected".
        selectedIndex: _tab.index < 2 ? _tab.index : _tab.index + 1,
        onSelected: (i) => switch (i) {
          2 => unawaited(_camera()),
          < 2 => _go(WorkerTab.values[i]),
          _ => _go(WorkerTab.values[i - 1]),
        },
      ),
    );
  }
}
