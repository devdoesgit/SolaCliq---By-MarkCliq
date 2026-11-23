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
import 'package:solacliq/customers/data/kyc_files.dart';
import 'package:solacliq/customers/data/registration_repository.dart';
import 'package:solacliq/customers/view/customer_text.dart';
import 'package:solacliq/customers/view/document_files.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/tasks/view/task_text.dart';
import 'package:solacliq/uploads/data/upload_repository.dart';
import 'package:solacliq/uploads/view/pick_document.dart';
import 'package:solacliq/workspace/data/workspace.dart';

/// Sends a clearer copy of the customer document the admin returned:
/// read the note, add the new files (up to five), send them.
class FixDocumentPage extends StatefulWidget {
  const new({required this.workspace, required this.customerId, super.key});

  final MemberWorkspace workspace;
  final String customerId;

  @override
  State<FixDocumentPage> createState() => _FixDocumentPageState();
}

class _FixDocumentPageState extends State<FixDocumentPage> {
  late Future<CustomerDetail> _customer = _fetch();
  late final KycUploader _uploader;
  List<KycFile> _files = const [];
  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _uploader = KycUploader(
      context.read<UploadRepository>(),
      orgId: widget.workspace.orgId,
      changed: (files) => setState(() {
        _files = [for (final list in files.values) ...list];
      }),
    );
  }

  @override
  void dispose() {
    _uploader.close();
    super.dispose();
  }

  bool get _ready =>
      uploadedOf(_files).isNotEmpty &&
      !_files.any((f) => f.state is DocUploading);

  Future<CustomerDetail> _fetch() => context.read<CustomerRepository>().get(
    widget.workspace.orgId,
    widget.customerId,
  );

  Future<void> _take(KycKind kind, String title, DocumentSide? side) async {
    final file = await pickDocument(context, title);
    if (file != null && mounted) await _uploader.add(kind, file, side: side);
  }

  Future<void> _send(ReturnedDocument returned) async {
    if (!_ready) return;
    final l10n = context.l10n;
    final customers = context.read<CustomerRepository>();
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await customers.replaceDocument(
        orgId: widget.workspace.orgId,
        customerId: widget.customerId,
        kind: returned.kind,
        files: uploadedOf(_files),
      );
      if (mounted) {
        setState(() {
          _sent = true;
        });
      }
    } on AuthFailure catch (failure) {
      if (mounted) {
        setState(() {
          _error = failure.code.message(l10n);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
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
            onRetry: () => setState(() {
              _customer = _fetch();
            }),
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
                      if (!_ready)
                        SolaText(
                          _files.any((f) => f.state is DocUploading)
                              ? l10n.waitForUploads
                              : l10n.addNewPhotoFirst,
                          style: SolaTextStyle.meta,
                          color: SolaColors.muted,
                          textAlign: TextAlign.center,
                        ),
                      SolaButton(
                        key: const Key('fix_send'),
                        label: l10n.sendToAdmin,
                        onPressed: !_ready || _sending
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
          children: _sent
              ? [
                  SolaListRow(
                    title: doc,
                    subtitle: l10n.newPhotoAdded,
                    leading: const SolaAvatar(
                      icon: SolaIcons.file,
                      color: SolaColors.tan,
                    ),
                  ),
                ]
              : documentRows(
                  l10n: l10n,
                  kind: returned.kind,
                  title: doc,
                  detail: returned.title,
                  files: _files,
                  onAdd: (side) => unawaited(_take(returned.kind, doc, side)),
                  onRetry: (id) =>
                      unawaited(_uploader.retry(returned.kind, id)),
                  onRemove: (id) => _uploader.remove(returned.kind, id),
                ),
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
