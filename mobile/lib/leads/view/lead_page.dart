import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/app/widgets/back_to.dart';
import 'package:solacliq/app/widgets/load_view.dart';
import 'package:solacliq/auth/data/auth_failure.dart';
import 'package:solacliq/auth/view/auth_text.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/leads/data/lead_repository.dart';
import 'package:solacliq/leads/view/lead_text.dart';
import 'package:solacliq/tasks/view/task_text.dart';
import 'package:solacliq/workspace/data/workspace.dart';
import 'package:url_launcher/url_launcher.dart';

/// One lead the admin handed to this Sales Agent (F20): call them, say
/// where it stands, keep a note. Reassigning is the admin's.
class LeadPage extends StatefulWidget {
  const new({required this.workspace, required this.leadId, super.key});

  final MemberWorkspace workspace;
  final String leadId;

  @override
  State<LeadPage> createState() => _LeadPageState();
}

class _LeadPageState extends State<LeadPage> {
  late Future<Lead> _lead = _fetch();
  final _note = TextEditingController();
  bool _saving = false;
  AuthFailure? _failed;
  bool _saved = false;

  Future<Lead> _fetch() async {
    final lead = await context.read<LeadRepository>().get(
      widget.workspace.orgId,
      widget.leadId,
    );
    _note.text = lead.note ?? '';
    return lead;
  }

  void _reload() => setState(() {
    _lead = _fetch();
  });

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save({LeadStatus? status, String? note}) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failed = null;
      _saved = false;
    });
    try {
      final lead = await context.read<LeadRepository>().update(
        widget.workspace.orgId,
        widget.leadId,
        status: status,
        note: note,
      );
      if (!mounted) return;
      setState(() {
        _lead = Future.value(lead);
        _saved = true;
      });
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _failed = failure);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder(
      future: _lead,
      builder: (context, snapshot) {
        final lead = snapshot.data;
        return SolaScreen(
          background: SolaBackground.stone,
          navBar: SolaNavBar(
            leading: const BackTo(fallback: AppRoutes.home),
            title: l10n.leadTitle,
          ),
          body: LoadView(
            future: _lead,
            failedTitle: l10n.leadLoadFailed,
            onRetry: _reload,
            builder: (context, l) => _Details(
              lead: l,
              note: _note,
              saving: _saving,
              saved: _saved,
              failed: _failed,
              onStatus: (s) => unawaited(_save(status: s)),
              onNote: () => unawaited(_save(note: _note.text.trim())),
            ),
          ),
          bottom: lead == null
              ? null
              : SolaBottomBar(
                  children: [
                    SolaButton(
                      key: const Key('lead_call'),
                      label: l10n.callPerson(lead.name),
                      icon: SolaIcons.phone,
                      onPressed: () => unawaited(
                        launchUrl(Uri.parse('tel:+91${lead.phone}')),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _Details extends StatelessWidget {
  const new({
    required this.lead,
    required this.note,
    required this.saving,
    required this.saved,
    required this.failed,
    required this.onStatus,
    required this.onNote,
  });

  final Lead lead;
  final TextEditingController note;
  final bool saving;
  final bool saved;
  final AuthFailure? failed;
  final ValueChanged<LeadStatus> onStatus;
  final VoidCallback onNote;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final l = lead;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SolaSpace.space14,
      children: [
        MergeSemantics(
          child: Column(
            spacing: SolaSpace.space8,
            children: [
              SolaAvatar(initials: initialsOf(l.name), size: 64),
              SolaText(l.name, style: SolaTextStyle.titleSm),
              SolaText(
                '${l.source} · ${formatWhen(l.receivedAt)}',
                color: SolaColors.muted,
              ),
              l.status.pill(l10n),
            ],
          ),
        ),
        if (failed case final f?)
          SolaNotice(title: l10n.leadSaveFailed, body: f.code.message(l10n)),
        SolaSegmented<LeadStatus>(
          key: const ValueKey('lead_status'),
          label: l10n.leadStanding,
          selected: l.status,
          onChanged: saving ? (_) {} : onStatus,
          choices: [
            for (final s in LeadStatus.values) SolaChoice(s, s.label(l10n)),
          ],
        ),
        if (l.status == LeadStatus.won)
          SolaText(
            l10n.leadWonHint,
            style: SolaTextStyle.small,
            color: SolaColors.muted,
          ),
        SolaGroup(
          children: [
            SolaKeyValueRow(l10n.fieldPhone, l.phone),
            if (l.email case final v?) SolaKeyValueRow(l10n.leadEmail, v),
            if (l.city case final v?) SolaKeyValueRow(l10n.leadCity, v),
            if (l.monthlyBill case final v?)
              SolaKeyValueRow(l10n.leadMonthlyBill, v),
            if (l.roofType case final v?) SolaKeyValueRow(l10n.leadRoof, v),
            SolaKeyValueRow(l10n.leadSource, l.source),
            for (final MapEntry(:key, :value) in l.answers.entries)
              SolaKeyValueRow(key, value),
          ],
        ),
        if (l.message case final m?)
          SolaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: SolaSpace.space6,
              children: [
                SolaText(
                  l10n.leadMessage,
                  style: SolaTextStyle.small,
                  color: SolaColors.muted,
                ),
                SolaText(m),
              ],
            ),
          ),
        SolaGroup(
          children: [
            SolaFieldRow(
              key: const ValueKey('lead_note'),
              label: l10n.leadNote,
              controller: note,
              placeholder: l10n.leadNoteHint,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onNote(),
            ),
          ],
        ),
        SolaButton(
          key: const Key('lead_save_note'),
          label: saved ? l10n.leadSaved : l10n.leadSaveNote,
          variant: SolaButtonVariant.white,
          icon: saved ? SolaIcons.check : null,
          onPressed: saving ? null : onNote,
        ),
      ],
    );
  }
}
