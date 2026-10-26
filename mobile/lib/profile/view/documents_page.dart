import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/app/widgets/back_to.dart';
import 'package:solacliq/app/widgets/load_view.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/customers/view/customer_text.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/profile/data/profile_repository.dart';
import 'package:solacliq/workspace/data/workspace.dart';

/// The documents a company holds for the person: a worker's ID and the
/// bank for their salary, or a customer's KYC.
class DocumentsPage extends StatefulWidget {
  const new({required this.workspace, super.key});

  final MemberWorkspace workspace;

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  late Future<MyDocuments> _docs = _fetch();

  Future<MyDocuments> _fetch() =>
      context.read<ProfileRepository>().documents(widget.workspace.orgId);

  bool get _worker => widget.workspace.role == OrgRole.worker;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final org = widget.workspace.orgName;
    return SolaScreen(
      background: _worker ? SolaBackground.sand : SolaBackground.sky,
      navBar: SolaNavBar(
        leading: const BackTo(fallback: AppRoutes.home),
        title: _worker ? l10n.idDocuments : l10n.documentsTitle,
      ),
      body: LoadView(
        future: _docs,
        failedTitle: l10n.documentsLoadFailed,
        onRetry: () => setState(() => _docs = _fetch()),
        builder: (context, docs) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SolaSpace.space14,
          children: [
            SolaGroup(
              children: [
                if (docs.items.isEmpty) SolaListRow(title: l10n.noDocuments),
                for (final d in docs.items)
                  SolaListRow(
                    key: ValueKey('document_${d.kind.name}'),
                    title: d.kind.label(l10n),
                    subtitle: d.detail,
                    leading: const SolaAvatar(
                      icon: SolaIcons.idCard,
                      color: SolaColors.tan,
                    ),
                    trailing: switch (d.status) {
                      DocumentStatus.verified => SolaPill(
                        l10n.verified,
                        tone: SolaTone.success,
                        icon: SolaIcons.check,
                      ),
                      DocumentStatus.inReview => SolaPill(
                        l10n.statusInReview,
                        icon: SolaIcons.hourglass,
                      ),
                      DocumentStatus.needsFix => SolaPill(
                        l10n.fixKyc,
                        tone: SolaTone.danger,
                      ),
                    },
                  ),
                if (_worker)
                  NavRow(
                    key: const Key('documents_bank'),
                    icon: SolaIcons.wallet,
                    title: l10n.bankForSalary,
                    onTap: () => unawaited(context.push(AppRoutes.bank)),
                  ),
              ],
            ),
            SolaText(
              switch (docs.uploadedBy) {
                _ when _worker => l10n.documentsWorkerNote,
                final name? => l10n.documentsCustomerNote(name, org),
                null => l10n.documentsCustomerNoteNoAgent(org),
              },
              style: SolaTextStyle.small,
              color: SolaColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}
