import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/expenses/view/expenses_tab.dart';
import 'package:solacliq/home/view/org_home.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/profile/view/profile_tab.dart';
import 'package:solacliq/tasks/cubit/tasks_cubit.dart';
import 'package:solacliq/tasks/data/task_repository.dart';
import 'package:solacliq/tasks/view/tasks_tab.dart';
import 'package:solacliq/workspace/data/workspace.dart';

/// The worker's tabs, left to right.
enum WorkerTab { home, tasks, expenses, profile }

/*
  A worker's app: home, tasks, expenses and profile, under one tab bar.
  Each tab keeps its place while another is shown. Proof photos are taken
  from a task, never from the tab bar: the worker picks the task (and so
  the customer) first, so a photo can't land on the wrong job
*/
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
        selectedIndex: _tab.index,
        onSelected: (i) => _go(WorkerTab.values[i]),
      ),
    );
  }
}
