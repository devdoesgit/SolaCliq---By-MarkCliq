import 'dart:async';

import 'package:flutter/services.dart';
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
import 'package:solacliq/uploads/view/file_preview.dart';
import 'package:solacliq/uploads/view/pick_document.dart';
import 'package:solacliq/uploads/view/upload_problem_text.dart';
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
    if (picked == null || !mounted) return;
    setState(() => _task = picked.$1);
    _edited('task_id');
  }

  UploadFile? _receipt;
  DateTime _day = DateUtils.dateOnly(DateTime.now());
  final _errors = <String, String?>{};

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  // The errors that came from the server: sending again asks it afresh.
  final _refused = <String>{};

  void _key(String key) {
    setState(() => _amount = _amount.add(key));
    _edited('amount');
  }

  void _delete() {
    setState(() => _amount = _amount.delete());
    _edited('amount');
  }

  // An edit: its field's error and the banner may no longer hold.
  void _edited(String field) {
    context.read<SubmitCubit>().reset();
    if (_errors[field] != null) setState(() => _errors[field] = null);
  }

  /*
    The server's reasons, under the fields they're about. Its field names
    are the API's: a receipt that didn't arrive is `receipt_upload_id`
  */
  void _showServerErrors(SubmitState state) {
    if (state.status != SubmitStatus.failure || state.fields.isEmpty) return;
    setState(() {
      for (final MapEntry(:key, :value) in state.fields.entries) {
        final field = key == 'receipt_upload_id' ? 'receipt' : key;
        _errors[field] = value;
        _refused.add(field);
      }
    });
  }

  Future<void> _pickReceipt() async {
    final file = await pickDocument(context, context.l10n.addReceipt);
    if (file == null || !mounted) return;
    if (file.problemFor(UploadPurpose.receipt) case final problem?) {
      // The phone's refusal now, not the server's: sending doesn't clear it.
      _refused.remove('receipt');
      setState(() => _errors['receipt'] = problem.message(context.l10n));
      return;
    }
    setState(() => _receipt = file);
    _edited('receipt');
  }

  Future<void> _pickDay() async {
    final today = DateUtils.dateOnly(DateTime.now());
    FocusManager.instance.primaryFocus?.unfocus();
    final day = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: today.subtract(const Duration(days: 60)),
      lastDate: today,
    );
    if (day == null || !mounted) return;
    setState(() => _day = day);
    _edited('spent_on');
  }

  Future<void> _submit() async {
    if (context.quickForms) {
      if (_amount.paise == 0) _amount = const AmountEntry('1240');
      _category ??= ExpenseCategory.fuel;
      context.fillBlank(_note, 'Sample expense (illustrative)');
    }
    final l10n = context.l10n;
    setState(() {
      _refused
        ..forEach(_errors.remove)
        ..clear();
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
          : await uploads.upload(
              widget.workspace.orgId,
              receipt,
              UploadPurpose.receipt,
            );
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

  bool get _hasDraft =>
      _amount.paise > 0 || _note.text.trim().isNotEmpty || _receipt != null;

  /*
    Leaving with something typed asks first: a stray Back press would
    otherwise lose the amount, the note and the receipt photo
  */
  Future<void> _leave() async {
    if (_hasDraft && !await _confirmDiscard()) return;
    if (!mounted) return;
    context.canPop() ? context.pop() : context.go(AppRoutes.home);
  }

  Future<bool> _confirmDiscard() async {
    final l10n = context.l10n;
    final discard = await showSolaSheet<bool>(
      context: context,
      title: l10n.discardExpenseTitle,
      doneLabel: l10n.keepEditing,
      builder: (sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: SolaSpace.space14,
        children: [
          SolaText(l10n.discardExpenseBody, color: SolaColors.muted),
          SolaButton(
            key: const Key('discard_expense'),
            label: l10n.discardCustomer,
            variant: SolaButtonVariant.dark,
            onPressed: () => Navigator.of(sheet).pop(true),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<SubmitCubit>().state;
    final today = DateUtils.isSameDay(_day, DateTime.now());
    final amountError = _errors['amount'];
    return PopScope(
      // Back comes here, so a draft is never lost without asking.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: SolaScreen(
        background: SolaBackground.sand,
        navBar: SolaNavBar(
          leading: BackTo(
            fallback: AppRoutes.home,
            close: true,
            onPressed: () => unawaited(_leave()),
          ),
          title: l10n.logExpense,
          subtitle: widget.workspace.orgName,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: SolaSpace.space10),
            BlocListener<SubmitCubit, SubmitState>(
              listener: (_, state) => _showServerErrors(state),
              child: const SizedBox.shrink(),
            ),
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
            if (_errors['task_id'] case final error?)
              Center(child: _Error(error)),
            const SizedBox(height: SolaSpace.space14),
            SolaChips<ExpenseCategory>(
              key: const ValueKey('expense_category'),
              label: l10n.category,
              selected: _category,
              onChanged: (v) {
                setState(() => _category = v);
                _edited('category');
              },
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
                        // The server's limit (`expenses.rs`, MAX_NOTE).
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(
                            ExpenseRepository.maxNote,
                          ),
                        ],
                        onChanged: (_) => _edited('note'),
                      ),
                      SolaValueRow(
                        key: const Key('expense_date'),
                        label: l10n.date,
                        value: today
                            ? l10n.today2(formatDayMonth(_day))
                            : formatDayMonth(_day),
                        error: _errors['spent_on'],
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
            // The note's keyboard takes its place.
            if (MediaQuery.viewInsetsOf(context).bottom == 0)
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
                  FilePreview(image: MemoryImage(receipt.bytes)),
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
