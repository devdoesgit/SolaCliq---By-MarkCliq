import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/dev/quick_forms.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/app/widgets/back_to.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/auth/cubit/submit_cubit.dart';
import 'package:solacliq/auth/widgets/failure_notice.dart';
import 'package:solacliq/expenses/data/amount_entry.dart';
import 'package:solacliq/expenses/data/expense_repository.dart';
import 'package:solacliq/expenses/view/expense_sent_page.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/tasks/data/task_repository.dart';
import 'package:solacliq/uploads/data/upload_repository.dart';
import 'package:solacliq/uploads/view/pick_photo.dart';
import 'package:solacliq/workspace/data/workspace.dart';
import 'package:uuid/uuid.dart';

/// Logs a cost for the admin to approve: the amount on a keypad, the
/// category, a receipt photo, a note and the day.
class ExpensePage extends StatelessWidget {
  const new({required this.workspace, super.key});

  final MemberWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SubmitCubit(),
      child: ExpenseView(workspace: workspace),
    );
  }
}

class ExpenseView extends StatefulWidget {
  const new({required this.workspace, super.key});

  final MemberWorkspace workspace;

  @override
  State<ExpenseView> createState() => _ExpenseViewState();
}

class _ExpenseViewState extends State<ExpenseView> {
  final _note = TextEditingController();

  /// One per expense, so a retry after a dropped connection can't log it
  /// twice.
  final String _idempotencyKey = const Uuid().v4();
  AmountEntry _amount = const AmountEntry();
  ExpenseCategory? _category;

  /// The worker's open tasks today, and the one this cost is for.
  List<TaskSummary> _tasks = const [];
  TaskSummary? _task;

  @override
  void initState() {
    super.initState();
    if (widget.workspace.role == OrgRole.worker) unawaited(_loadTasks());
  }

  Future<void> _loadTasks() async {
    try {
      final today = await context.read<TaskRepository>().list(
        widget.workspace.orgId,
        TaskView.today,
      );
      if (!mounted) return;
      final open = [
        for (final t in today)
          if (t.status != TaskStatus.approved &&
              t.status != TaskStatus.cancelled)
            t,
      ];
      setState(() {
        _tasks = open;
        _task = open.isEmpty ? null : open.first;
      });
    } on AuthFailure {
      // The link to a task is optional; log the expense without it.
    }
  }

  Future<void> _pickTask() async {
    final l10n = context.l10n;
    final picked = await showSolaSheet<(TaskSummary?,)>(
      context: context,
      title: l10n.expenseForTask,
      doneLabel: l10n.cancel,
      builder: (sheet) => SolaGroup(
        children: [
          for (final t in _tasks)
            SolaListRow(
              key: ValueKey('expense_task_${t.id}'),
              title: t.customerName,
              subtitle: t.title,
              leading: SolaThumb(photo: SolaPhotos.fromReference(t.image)),
              trailing: t.id == _task?.id
                  ? const SolaIcon(SolaIcons.check)
                  : null,
              onTap: () => Navigator.of(sheet).pop((t,)),
            ),
          SolaListRow(
            key: const Key('expense_task_none'),
            title: l10n.noTask,
            trailing: _task == null ? const SolaIcon(SolaIcons.check) : null,
            onTap: () => Navigator.of(sheet).pop((null,)),
          ),
        ],
      ),
    );
    if (picked != null) setState(() => _task = picked.$1);
  }

  UploadFile? _receipt;
  DateTime _day = DateUtils.dateOnly(DateTime.now());
  final _errors = <String, String?>{};

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _key(String key) => setState(() {
    _amount = _amount.add(key);
    _errors['amount'] = null;
  });

  void _delete() => setState(() => _amount = _amount.delete());

  Future<void> _pickReceipt() async {
    final file = await pickDocumentPhoto(context, context.l10n.addReceipt);
    if (file == null || !mounted) return;
    if (file.bytes.length > UploadRepository.maxBytes) {
      setState(() => _errors['receipt'] = context.l10n.fileTooBig);
      return;
    }
    setState(() {
      _receipt = file;
      _errors['receipt'] = null;
    });
  }

  Future<void> _pickDay() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final day = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: today.subtract(const Duration(days: 60)),
      lastDate: today,
    );
    if (day != null) setState(() => _day = day);
  }

  Future<void> _submit() async {
    if (context.quickForms) {
      if (_amount.paise == 0) _amount = const AmountEntry('1240');
      _category ??= ExpenseCategory.fuel;
      context.fillBlank(_note, 'Sample expense (illustrative)');
    }
    final l10n = context.l10n;
    setState(() {
      _errors
        ..['amount'] = _amount.paise == 0 ? l10n.errorAmount : null
        ..['category'] = _category == null ? l10n.errorChoose : null
        ..['note'] = _note.text.trim().isEmpty ? l10n.errorNote : null;
    });
    if (_errors.values.any((e) => e != null)) return;
    final uploads = context.read<UploadRepository>();
    final expenses = context.read<ExpenseRepository>();
    final router = GoRouter.of(context);
    final receipt = _receipt;
    await context.read<SubmitCubit>().submit(() async {
      final receiptId = receipt == null
          ? null
          : await uploads.upload(receipt, UploadPurpose.receipt);
      final expense = await expenses.create(
        orgId: widget.workspace.orgId,
        idempotencyKey: _idempotencyKey,
        amountPaise: _amount.paise,
        category: _category!,
        note: _note.text.trim(),
        spentOn: _day,
        receiptUploadId: receiptId,
        taskId: _task?.id,
      );
      unawaited(
        router.pushReplacement(
          AppRoutes.expenseSent,
          extra: ExpenseSentArgs(workspace: widget.workspace, expense: expense),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<SubmitCubit>().state;
    final today = DateUtils.isSameDay(_day, DateTime.now());
    final amountError = _errors['amount'];
    return SolaScreen(
      background: SolaBackground.sand,
      navBar: SolaNavBar(
        leading: const BackTo(fallback: AppRoutes.home, close: true),
        title: l10n.logExpense,
        subtitle: widget.workspace.orgName,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: SolaSpace.space10),
          if (state.status == SubmitStatus.failure) ...[
            FailureNotice(state: state),
            const SizedBox(height: SolaSpace.space12),
          ],
          SolaText(
            l10n.amount,
            style: SolaTextStyle.eyebrow,
            color: amountError != null ? SolaColors.danger : SolaColors.muted,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SolaSpace.space4),
          Semantics(
            label: l10n.amount,
            value: _amount.display,
            liveRegion: true,
            excludeSemantics: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: SolaText(
                      _amount.display,
                      style: SolaTextStyle.amount,
                      color: _amount.text.isEmpty
                          ? SolaColors.faint
                          : SolaColors.ink,
                    ),
                  ),
                ),
                Container(
                  width: 3,
                  height: 50,
                  margin: const EdgeInsetsDirectional.only(
                    start: SolaSpace.space4,
                  ),
                  decoration: BoxDecoration(
                    color: SolaColors.sun,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          if (amountError != null) Center(child: _Error(amountError)),
          if (_tasks.isNotEmpty) ...[
            const SizedBox(height: SolaSpace.space4),
            Center(
              child: SolaTappable(
                key: const Key('expense_task'),
                identifier: 'expense_task',
                semanticsLabel: l10n.expenseForTaskValue(
                  _task?.customerName ?? l10n.noTask,
                ),
                onTap: () => unawaited(_pickTask()),
                builder: (context, state) => SizedBox(
                  height: SolaSize.tapMin,
                  child: Center(
                    child: SolaPill(
                      _task == null
                          ? l10n.noTask
                          : '${_task!.customerName} · ${_task!.title}',
                      icon: SolaIcons.bolt,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: SolaSpace.space14),
          SolaChips<ExpenseCategory>(
            key: const ValueKey('expense_category'),
            label: l10n.category,
            selected: _category,
            onChanged: (v) => setState(() {
              _category = v;
              _errors['category'] = null;
            }),
            choices: [
              SolaChoice(ExpenseCategory.fuel, l10n.categoryFuel),
              SolaChoice(ExpenseCategory.material, l10n.categoryMaterial),
              SolaChoice(ExpenseCategory.labour, l10n.categoryLabour),
              SolaChoice(ExpenseCategory.other, l10n.categoryOther),
            ],
          ),
          if (_errors['category'] case final error?) _Error(error),
          const SizedBox(height: SolaSpace.space10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: SolaSpace.space10,
            children: [
              _ReceiptTile(
                receipt: _receipt,
                onTap: () => unawaited(_pickReceipt()),
              ),
              Expanded(
                child: SolaGroup(
                  children: [
                    SolaFieldRow(
                      key: const ValueKey('expense_note'),
                      label: l10n.noteForAdmin,
                      placeholder: l10n.notePlaceholder,
                      controller: _note,
                      error: _errors['note'],
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => _errors['note'] = null,
                    ),
                    SolaValueRow(
                      key: const Key('expense_date'),
                      label: l10n.date,
                      value: today
                          ? l10n.today2(formatDayMonth(_day))
                          : formatDayMonth(_day),
                      onTap: () => unawaited(_pickDay()),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_errors['receipt'] case final error?) _Error(error),
        ],
      ),
      bottom: SolaBottomBar(
        children: [
          SolaKeypad(
            onKey: _key,
            onDelete: _delete,
            deleteLabel: l10n.deleteDigit,
          ),
          SolaButton(
            key: const Key('expense_submit'),
            label: l10n.sendToAdmin,
            icon: SolaIcons.receipt,
            onPressed: state.isSubmitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: SolaSpace.space6),
    child: Semantics(
      liveRegion: true,
      child: SolaText(
        text,
        style: SolaTextStyle.meta,
        color: SolaColors.danger,
      ),
    ),
  );
}

/// The receipt photo, or a camera to add one.
class _ReceiptTile extends StatelessWidget {
  const new({required this.receipt, required this.onTap});

  final UploadFile? receipt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final receipt = this.receipt;
    return SolaTappable(
      key: const Key('expense_receipt'),
      identifier: 'expense_receipt',
      semanticsLabel: receipt == null ? l10n.addReceipt : l10n.receiptAdded,
      onTap: onTap,
      builder: (context, state) => Container(
        width: 84,
        height: 84,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: state.pressed ? SolaColors.creamDeep : SolaColors.tan,
          borderRadius: BorderRadius.circular(SolaRadius.radius18),
        ),
        child: receipt == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: SolaSpace.space4,
                children: [
                  const SolaIcon(SolaIcons.camera, color: SolaColors.tanText),
                  SolaText(
                    l10n.addReceipt,
                    style: SolaTextStyle.caption,
                    color: SolaColors.tanText,
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(receipt.bytes, fit: BoxFit.cover),
                  const PositionedDirectional(
                    end: 6,
                    bottom: 6,
                    child: SolaPill('1', tone: SolaTone.live),
                  ),
                ],
              ),
      ),
    );
  }
}
