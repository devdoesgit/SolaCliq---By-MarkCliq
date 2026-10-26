import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/uploads/data/upload_repository.dart';

/// Asks for a photo of a document, from the camera or the gallery, sized
/// down for upload. Null if the person backs out.
///
/// Not for installation proof: that comes from the live camera only.
Future<UploadFile?> pickDocumentPhoto(
  BuildContext context,
  String title,
) async {
  final l10n = context.l10n;
  final source = await showSolaSheet<ImageSource>(
    context: context,
    title: title,
    doneLabel: l10n.cancel,
    builder: (sheet) => SolaGroup(
      children: [
        SolaListRow(
          key: const Key('pick_camera'),
          title: l10n.takePhoto,
          leading: const SolaAvatar(
            icon: SolaIcons.camera,
            color: SolaColors.tan,
          ),
          onTap: () => Navigator.of(sheet).pop(ImageSource.camera),
        ),
        SolaListRow(
          key: const Key('pick_gallery'),
          title: l10n.chooseFile,
          leading: const SolaAvatar(
            icon: SolaIcons.file,
            color: SolaColors.tan,
          ),
          onTap: () => Navigator.of(sheet).pop(ImageSource.gallery),
        ),
      ],
    ),
  );
  if (source == null) return null;
  final photo = await ImagePicker().pickImage(
    source: source,
    maxWidth: 2000,
    maxHeight: 2000,
    imageQuality: 80,
  );
  if (photo == null) return null;
  return UploadFile(name: photo.name, bytes: await photo.readAsBytes());
}
