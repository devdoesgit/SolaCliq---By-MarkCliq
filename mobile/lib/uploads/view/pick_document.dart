import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/uploads/data/upload_repository.dart';

enum _Source { camera, gallery, pdf }

/// Asks for a document: a photo from the camera or the gallery (sized
/// down for upload), or a PDF. Null if the person backs out.
///
/// Not for installation proof: that comes from the live camera only.
Future<UploadFile?> pickDocument(BuildContext context, String title) async {
  final l10n = context.l10n;
  final source = await showSolaSheet<_Source>(
    context: context,
    title: title,
    doneLabel: l10n.cancel,
    builder: (sheet) {
      SolaListRow option(String key, String label, SolaIcons icon, _Source s) =>
          SolaListRow(
            key: Key(key),
            title: label,
            leading: SolaAvatar(icon: icon, color: SolaColors.tan),
            onTap: () => Navigator.of(sheet).pop(s),
          );
      return SolaGroup(
        children: [
          option(
            'pick_camera',
            l10n.takePhoto,
            SolaIcons.camera,
            _Source.camera,
          ),
          option(
            'pick_gallery',
            l10n.chooseFile,
            SolaIcons.file,
            _Source.gallery,
          ),
          option('pick_pdf', l10n.choosePdf, SolaIcons.file, _Source.pdf),
        ],
      );
    },
  );
  switch (source) {
    case null:
      return null;
    case _Source.pdf:
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (file == null) return null;
      return UploadFile(name: file.name, bytes: await file.readAsBytes());
    case _Source.camera || _Source.gallery:
      final photo = await ImagePicker().pickImage(
        source: source == _Source.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 80,
      );
      if (photo == null) return null;
      return UploadFile(name: photo.name, bytes: await photo.readAsBytes());
  }
}
