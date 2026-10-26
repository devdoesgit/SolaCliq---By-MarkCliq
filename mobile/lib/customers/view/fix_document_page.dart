import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/app/widgets/back_to.dart';
import 'package:solacliq/app/widgets/load_view.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/auth/view/auth_text.dart';
import 'package:solacliq/customers/data/customer_repository.dart';
import 'package:solacliq/customers/view/customer_text.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/tasks/view/task_text.dart';
import 'package:solacliq/uploads/data/upload_repository.dart';
import 'package:solacliq/uploads/view/pick_photo.dart';
import 'package:solacliq/workspace/data/workspace.dart';

/// Sends a clearer copy of the customer document the admin returned:
/// read the note, take the photo, send it.
class FixDocumentPage extends StatefulWidget {
  const new({required this.workspace, required this.customerId, super.key});

  final MemberWorkspace workspace;
  final String customerId;

  @override
  State<FixDocumentPage> createState() => _FixDocumentPageState();
}

class _FixDocumentPageState extends State<FixDocumentPage> {
  late Future<CustomerDetail> _customer = _fetch();
  UploadFile? _photo;
  bool _sending = false;
  bool _sent = false;
  String? _error;

  Future<CustomerDetail> _fetch() => context.read<CustomerRepository>().get(
    widget.workspace.orgId,
    widget.customerId,
  );

  Future<void> _take(String title) async {
    final file = await pickDocumentPhoto(context, title);
    if (file != null && mounted) setState(() => _photo = file);
  }

  Future<void> _send(ReturnedDocument returned) async {
    final photo = _photo;
    if (photo == null) return;
    final l10n = context.l10n;
    final uploads = context.read<UploadRepository>();
    final customers = context.read<CustomerRepository>();
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final uploadId = await uploads.upload(photo, UploadPurpose.kyc);
      await customers.replaceDocument(
        orgId: widget.workspace.orgId,
        customerId: widget.customerId,
        kind: returned.kind,
        uploadId: uploadId,
      );
      if (mounted) setState(() => _sent = true);
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
      future: _customer,
      builder: (context, snapshot) {
        final returned = snapshot.data?.returned;
        return SolaScreen(
          background: SolaBackground.stone,
          navBar: SolaNavBar(
            leading: BackTo(fallback: AppRoutes.customer(widget.customerId)),
            title: l10n.fixDocsTitle,
          ),
          body: LoadView(
            future: _customer,
            failedTitle: l10n.customerLoadFailed,
            onRetry: () => setState(() => _customer = _fetch()),
            builder: (context, c) => _body(l10n, c),
          ),
          bottom: returned == null
              ? null
              : SolaBottomBar(
                  children: [
                    if (_sent)
                      SolaButton(
                        key: const Key('fix_back'),
                        label: l10n.backToCustomers,
                        variant: SolaButtonVariant.dark,
                        onPressed: () => context.pop(),
                      )
                    else ...[
                      if (_photo == null)
                        SolaText(
                          l10n.addNewPhotoFirst,
                          style: SolaTextStyle.meta,
                          color: SolaColors.muted,
                          textAlign: TextAlign.center,
                        ),
                      SolaButton(
                        key: const Key('fix_send'),
                        label: l10n.sendToAdmin,
                        onPressed: _photo == null || _sending
                            ? null
                            : () => unawaited(_send(returned)),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }

  Widget _body(AppLocalizations l10n, CustomerDetail c) {
    final returned = c.returned;
    final error = _error;
    if (returned == null) {
      return Padding(
        padding: const EdgeInsets.only(top: SolaSpace.space26),
        child: SolaNotice(
          title: l10n.sentAgain,
          body: l10n.sentAgainBody,
          tone: SolaTone.success,
        ),
      );
    }
    final doc = returned.kind.label(l10n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SolaSpace.space14,
      children: [
        SolaTitleBlock(
          title: l10n.fixDocsHeading,
          subtitle: l10n.fixDocsBody(
            firstName(c.summary.name),
            doc.toLowerCase(),
          ),
        ),
        SolaBanner(
          title: l10n.adminNote,
          body: returned.note.text,
          tone: SolaTone.danger,
          icon: SolaIcons.alert,
          personInitials: initialsOf(returned.note.by),
          personLabel: returned.note.by,
        ),
        SolaGroup(
          children: [
            SolaListRow(
              title: doc,
              subtitle: _photo == null ? returned.title : l10n.newPhotoAdded,
              leading: const SolaAvatar(
                icon: SolaIcons.file,
                color: SolaColors.tan,
              ),
              trailing: _sent
                  ? null
                  : SolaButton(
                      key: const Key('fix_take'),
                      label: _photo == null ? l10n.takePhoto : l10n.retakePhoto,
                      variant: SolaButtonVariant.white,
                      compact: true,
                      expand: false,
                      onPressed: () => unawaited(_take(doc)),
                    ),
            ),
          ],
        ),
        if (_sent)
          SolaBanner(
            title: l10n.sentAgain,
            body: l10n.sentAgainBody,
            tone: SolaTone.success,
            icon: SolaIcons.check,
          ),
        if (error != null)
          SolaNotice(
            key: const Key('failure_notice'),
            title: error,
            announce: true,
          ),
      ],
    );
  }
}
