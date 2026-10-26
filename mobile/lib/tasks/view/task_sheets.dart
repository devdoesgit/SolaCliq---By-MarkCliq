import 'dart:async';

import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/dev/quick_forms.dart';
import 'package:solacliq/auth/view/auth_text.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/tasks/cubit/task_cubit.dart';
import 'package:solacliq/tasks/data/task_repository.dart';
import 'package:solacliq/tasks/view/task_text.dart';
import 'package:solacliq/uploads/data/upload_repository.dart';

/// "Report a problem": a reason, what happened, an optional photo from the
/// camera. The admin decides what happens next.
Future<void> showProblemSheet(BuildContext context, TaskCubit cubit) {
  final l10n = context.l10n;
  return showSolaSheet<void>(
    context: context,
    title: l10n.reportProblem,
    doneLabel: l10n.cancel,
    builder: (_) => _ProblemForm(cubit: cubit),
  );
}

class _ProblemForm extends StatefulWidget {
  const new({required this.cubit});

  final TaskCubit cubit;

  @override
  State<_ProblemForm> createState() => _ProblemFormState();
}

class _ProblemFormState extends State<_ProblemForm> {
  final _note = TextEditingController();
  TaskProblemReason? _reason;
  UploadFile? _photo;
  String? _reasonError;
  String? _noteError;
  bool _sending = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// A photo of the problem, from the camera only.
  Future<void> _takePhoto() async {
    final shot = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 80,
    );
    if (shot == null || !mounted) return;
    final file = UploadFile(name: shot.name, bytes: await shot.readAsBytes());
    setState(() => _photo = file);
  }

  Future<void> _send() async {
    final l10n = context.l10n;
    if (context.quickForms) {
      _reason ??= TaskProblemReason.materialMissing;
      context.fillBlank(_note, 'Sample problem (illustrative)');
    }
    setState(() {
      _reasonError = _reason == null ? l10n.errorChoose : null;
      _noteError = _note.text.trim().isEmpty ? l10n.errorWhatHappened : null;
    });
    if (_reasonError != null || _noteError != null) return;
    setState(() => _sending = true);
    final navigator = Navigator.of(context);
    final ok = await widget.cubit.reportProblem(
      reason: _reason!,
      note: _note.text.trim(),
      photo: _photo,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final admin = firstName(
      widget.cubit.state.task?.assignedBy?.name ?? l10n.yourAdmin,
    );
    final photo = _photo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SolaSpace.space14,
      children: [
        SolaText(l10n.problemIntro(admin), color: SolaColors.muted),
        SolaChips<TaskProblemReason>(
          key: const ValueKey('problem_reason'),
          label: l10n.problemReason,
          selected: _reason,
          onChanged: (v) => setState(() {
            _reason = v;
            _reasonError = null;
          }),
          choices: [
            for (final r in TaskProblemReason.values)
              SolaChoice(r, r.label(l10n)),
          ],
        ),
        if (_reasonError case final error?)
          SolaText(error, style: SolaTextStyle.meta, color: SolaColors.danger),
        SolaGroup(
          children: [
            SolaFieldRow(
              key: const ValueKey('problem_note'),
              label: l10n.whatHappened,
              controller: _note,
              error: _noteError,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        SolaTappable(
          key: const Key('problem_photo'),
          identifier: 'problem_photo',
          semanticsLabel: photo == null
              ? l10n.addPhotoOptional
              : l10n.photoTaken,
          onTap: () => unawaited(_takePhoto()),
          builder: (context, state) => Row(
            spacing: SolaSpace.space12,
            children: [
              Container(
                width: 56,
                height: 56,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: SolaColors.cream,
                  borderRadius: BorderRadius.circular(SolaRadius.radius16),
                  border: Border.all(color: SolaColors.track, width: 1.5),
                ),
                child: photo == null
                    ? const Center(
                        child: SolaIcon(
                          SolaIcons.camera,
                          color: SolaColors.muted,
                        ),
                      )
                    : Image.memory(photo.bytes, fit: BoxFit.cover),
              ),
              Expanded(
                child: SolaText(
                  photo == null ? l10n.addPhotoOptional : l10n.photoTaken,
                  style: SolaTextStyle.small,
                  color: SolaColors.muted,
                ),
              ),
            ],
          ),
        ),
        if (widget.cubit.state.failure case final failure? when !_sending)
          SolaNotice(title: failure.message(l10n), announce: true),
        SolaButton(
          key: const Key('problem_send'),
          label: l10n.sendToAdmin,
          icon: SolaIcons.alert,
          onPressed: _sending ? null : () => unawaited(_send()),
        ),
      ],
    );
  }
}

/// "Reply to Rajeeb": a message to the admin about a returned task.
Future<void> showReplySheet(
  BuildContext context,
  TaskCubit cubit,
  String admin,
) {
  final l10n = context.l10n;
  return showSolaSheet<void>(
    context: context,
    title: l10n.replyTo(admin),
    doneLabel: l10n.cancel,
    builder: (_) => _ReplyForm(cubit: cubit),
  );
}

class _ReplyForm extends StatefulWidget {
  const new({required this.cubit});

  final TaskCubit cubit;

  @override
  State<_ReplyForm> createState() => _ReplyFormState();
}

class _ReplyFormState extends State<_ReplyForm> {
  final _text = TextEditingController();
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    context.fillBlank(_text, 'Sample reply (illustrative)');
    final text = _text.text.trim();
    if (text.isEmpty) {
      setState(() => _error = context.l10n.errorWriteMessage);
      return;
    }
    setState(() => _sending = true);
    final navigator = Navigator.of(context);
    final ok = await widget.cubit.reply(text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SolaSpace.space14,
      children: [
        SolaGroup(
          children: [
            SolaFieldRow(
              key: const ValueKey('reply_text'),
              label: l10n.message,
              controller: _text,
              error: _error,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        SolaButton(
          key: const Key('reply_send'),
          label: l10n.send,
          icon: SolaIcons.chat,
          onPressed: _sending ? null : () => unawaited(_send()),
        ),
      ],
    );
  }
}
