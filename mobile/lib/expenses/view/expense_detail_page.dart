import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/app/widgets/back_to.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/auth/view/auth_text.dart';
import 'package:solacliq/expenses/data/expense_repository.dart';
import 'package:solacliq/expenses/view/expense_sent_page.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/tasks/view/task_text.dart';
import 'package:solacliq/uploads/data/upload_repository.dart';
import 'package:solacliq/uploads/view/pick_photo.dart';
import 'package:solacliq/workspace/data/workspace.dart';

/// One expense: its amount and status, what the admin said, the details
/// and the receipt. One sent back can get a new receipt.
class ExpenseDetailPage extends StatefulWidget {
  const new({required this.workspace, required this.expenseId, super.key});

  final MemberWorkspace workspace;
  final String expenseId;

  @override
  State<ExpenseDetailPage> createState() => _ExpenseDetailPageState();
}

class _ExpenseDetailPageState extends State<ExpenseDetailPage> {
  late Future<Expense> _expense = _fetch();
  bool _sending = false;
  String? _error;

  Future<Expense> _fetch() => context.read<ExpenseRepository>().get(
    widget.workspace.orgId,
    widget.expenseId,
  );

  Future<void> _newReceipt() async {
    final l10n = context.l10n;
    final file = await pickDocumentPhoto(context, l10n.uploadNewReceipt);
    if (file == null || !mounted) return;
    final uploads = context.read<UploadRepository>();
    final expenses = context.read<ExpenseRepository>();
    final router = GoRouter.of(context);
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final uploadId = await uploads.upload(file, UploadPurpose.receipt);
      final expense = await expenses.replaceReceipt(
        orgId: widget.workspace.orgId,
        expenseId: widget.expenseId,
        uploadId: uploadId,
      );
      unawaited(
        router.pushReplacement(
          AppRoutes.expenseSent,
          extra: ExpenseSentArgs(workspace: widget.workspace, expense: expense),
        ),
      );
    } on UploadTooLarge {
      if (mounted) setState(() => _error = l10n.fileTooBig);
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.code.message(l10n));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder(
      future: _expense,
      builder: (context, snapshot) {
        final expense = snapshot.data;
        return SolaScreen(
          background: SolaBackground.sand,
          navBar: SolaNavBar(
            leading: const BackTo(fallback: AppRoutes.home),
            title: l10n.expenseTitle,
          ),
          body: switch (snapshot) {
            AsyncSnapshot(:final Object error) => Padding(
              padding: const EdgeInsets.only(top: SolaSpace.space26),
              child: SolaNotice(
                title: l10n.expenseLoadFailed,
                body: error is AuthFailure ? error.code.message(l10n) : null,
                action: SolaButton(
                  key: const Key('expense_retry'),
                  label: l10n.retry,
                  variant: SolaButtonVariant.white,
                  compact: true,
                  expand: false,
                  onPressed: () => setState(() {
                    _expense = _fetch();
                  }),
                ),
              ),
            ),
            AsyncSnapshot(data: final e?) => _Details(
              expense: e,
              error: _error,
            ),
            _ => const Padding(
              padding: EdgeInsets.only(top: 120),
              child: Center(
                child: CircularProgressIndicator(color: SolaColors.ink),
              ),
            ),
          },
          bottom: expense?.status == ExpenseStatus.needsFix
              ? SolaBottomBar(
                  children: [
                    SolaButton(
                      key: const Key('expense_new_receipt'),
                      label: l10n.uploadNewReceipt,
                      icon: SolaIcons.camera,
                      onPressed: _sending
                          ? null
                          : () => unawaited(_newReceipt()),
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }
}

class _Details extends StatelessWidget {
  const new({required this.expense, required this.error});

  final Expense expense;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final e = expense;
    final receipt = imageFor(e.receiptUrl);
    final error = this.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SolaSpace.space14,
      children: [
        const SizedBox(height: SolaSpace.space4),
        MergeSemantics(
          child: Column(
            spacing: SolaSpace.space6,
            children: [
              SolaText(
                l10n.amount,
                style: SolaTextStyle.eyebrow,
                color: SolaColors.muted,
              ),
              SolaText(
                formatRupees(e.amountPaise),
                style: SolaTextStyle.amount,
              ),
              e.status.pill(l10n),
            ],
          ),
        ),
        if (error != null)
          SolaNotice(
            key: const Key('failure_notice'),
            title: error,
            announce: true,
          ),
        if (e.status == ExpenseStatus.needsFix)
          SolaBanner(
            title: l10n.sentBackByAdmin,
            body: e.adminNote,
            tone: SolaTone.danger,
            icon: SolaIcons.alert,
            personInitials: e.adminName == null
                ? null
                : initialsOf(e.adminName!),
            personLabel: e.adminName == null
                ? null
                : '${e.adminName} · ${l10n.roleAdmin}',
          ),
        SolaGroup(
          children: [
            SolaKeyValueRow(l10n.category, e.category.label(l10n)),
            SolaKeyValueRow(l10n.date, formatWeekdayDate(e.spentOn)),
            if (e.taskTitle != null)
              SolaKeyValueRow(
                l10n.taskLabel,
                '${e.taskCustomer} · ${e.taskTitle}',
              ),
            if (e.note.isNotEmpty) SolaKeyValueRow(l10n.note, e.note),
            SolaKeyValueRow(l10n.claim, e.reference),
          ],
        ),
        if (receipt != null)
          SolaCard(
            padding: const EdgeInsets.all(SolaSpace.space12),
            child: Row(
              spacing: SolaSpace.space14,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(SolaRadius.radius12),
                  child: Image(
                    image: receipt,
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                    semanticLabel: l10n.currentReceipt,
                  ),
                ),
                Expanded(
                  child: SolaText(
                    l10n.currentReceipt,
                    style: SolaTextStyle.rowTitle,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
