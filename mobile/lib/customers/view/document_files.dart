import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/customers/data/kyc_files.dart';
import 'package:solacliq/customers/data/registration_repository.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/uploads/view/upload_problem_text.dart';

/*
  One document's rows in a group (F5)
  ----------------------------------------------------------------------
  - Aadhaar: Front and Back slots, then Add more once one is in. Neither
    is required: an e-Aadhaar PDF has both
  - the rest: the document's row adds the first file, Add more the next
  - each file: its progress, Retry when it failed, Remove always
*/
List<Widget> documentRows({
  required AppLocalizations l10n,
  required KycKind kind,
  required String title,
  required String detail,
  required List<KycFile> files,
  required void Function(DocumentSide? side) onAdd,
  required void Function(int id) onRetry,
  required void Function(int id) onRemove,
  SolaGlyph? glyph,
}) {
  final name = kind.name;
  final sides = kind == KycKind.aadhaar;
  final full = files.length >= maxFilesPerDocument;
  final up = uploadedOf(files).length;
  final extras = files.where((f) => f.side == null).toList();

  SolaButton add(String id, String said, DocumentSide? side) => SolaButton(
    key: ValueKey('${id}_add'),
    label: l10n.add,
    semanticsLabel: '${l10n.add}: $said',
    icon: SolaIcons.camera,
    variant: SolaButtonVariant.dark,
    small: true,
    expand: false,
    onPressed: () => onAdd(side),
  );

  Widget fileRow(KycFile file, String label) => _FileRow(
    key: ValueKey('file_${name}_${file.id}'),
    file: file,
    label: label,
    said: '$title, $label',
    onRetry: () => onRetry(file.id),
    onRemove: () => onRemove(file.id),
  );

  return [
    SolaListRow(
      key: ValueKey('doc_$name'),
      title: title,
      subtitle: detail,
      leading: SolaThumb(
        glyph: glyph,
        icon: glyph == null ? SolaIcons.home : null,
      ),
      // The whole row adds the first file, not only its button.
      onTap: files.isEmpty
          ? () => onAdd(sides ? DocumentSide.front : null)
          : null,
      trailing: up > 0
          ? SolaPill(
              up == 1 ? l10n.uploaded : l10n.filesUploaded(up),
              tone: SolaTone.success,
              icon: SolaIcons.check,
            )
          : files.isEmpty && !sides
          ? add('doc_$name', title, null)
          : null,
    ),
    if (sides)
      for (final (side, label) in [
        (DocumentSide.front, l10n.sideFront),
        (DocumentSide.back, l10n.sideBack),
      ])
        if (files.where((f) => f.side == side).firstOrNull case final file?)
          fileRow(file, label)
        else if (!full)
          SolaListRow(
            key: ValueKey('doc_${name}_${side.name}'),
            title: label,
            semanticsLabel: '$title, $label',
            onTap: () => onAdd(side),
            trailing: add('doc_${name}_${side.name}', '$title, $label', side),
          ),
    for (final (i, file) in extras.indexed)
      fileRow(file, l10n.fileNumbered('${i + 1}')),
    if (files.isNotEmpty && !full)
      SolaListRow(
        key: ValueKey('doc_${name}_more'),
        title: l10n.addAnotherFile,
        semanticsLabel: '${l10n.addAnotherFile}: $title',
        onTap: () => onAdd(null),
        leading: const SolaAvatar(
          icon: SolaIcons.camera,
          color: SolaColors.tan,
        ),
      ),
  ];
}

class _FileRow extends StatelessWidget {
  const new({
    required super.key,
    required this.file,
    required this.label,
    required this.said,
    required this.onRetry,
    required this.onRemove,
  });

  final KycFile file;
  final String label;
  final String said;
  final VoidCallback onRetry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final id = (key! as ValueKey<String>).value;
    final state = file.state;
    final failed = state is DocFailed;
    return SolaListRow(
      title: label,
      subtitle: switch (state) {
        DocUploading(:final percent) => l10n.uploadingPercent('$percent'),
        DocUploaded() => l10n.uploaded,
        DocFailed(:final problem?) => problem.message(l10n),
        DocFailed() => l10n.uploadFailed,
      },
      subtitleLines: failed ? 3 : 1,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: SolaSpace.space8,
        children: [
          // Too big stays too big: only Remove.
          if (state case DocFailed(problem: null))
            SolaButton(
              key: ValueKey('${id}_retry'),
              label: l10n.retry,
              semanticsLabel: '${l10n.retry}: $said',
              variant: SolaButtonVariant.dark,
              small: true,
              expand: false,
              onPressed: onRetry,
            ),
          SolaCircleButton(
            key: ValueKey('${id}_remove'),
            icon: SolaIcons.close,
            semanticsLabel: '${l10n.removeFile}: $said',
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
