import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';

/*
  A picture of a file someone uploaded or is about to
  ----------------------------------------------------------------------
  - any file is taken and the admin judges it (owner, 2026-11-22), so
    this can be a PDF, a damaged photo or something renamed: what can't
    be drawn shows as a file, never as a broken image (QA-07)
*/
class FilePreview extends StatelessWidget {
  const new({
    required this.image,
    this.width,
    this.height,
    this.semanticLabel,
    super.key,
  });

  final ImageProvider image;
  final double? width;
  final double? height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Image(
    image: image,
    width: width,
    height: height,
    fit: BoxFit.cover,
    semanticLabel: semanticLabel,
    errorBuilder: (_, _, _) => Semantics(
      label: semanticLabel,
      child: SizedBox(
        key: const Key('preview_unreadable'),
        width: width,
        height: height,
        child: const ColoredBox(
          color: SolaColors.tan,
          child: Center(
            child: SolaIcon(SolaIcons.file, color: SolaColors.tanText),
          ),
        ),
      ),
    ),
  );
}
