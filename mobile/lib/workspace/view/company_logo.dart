import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/workspace/data/workspace.dart';

/// A company's logo in a round badge where the company appears (the
/// workspace list), or its initials when it has none or the logo can't
/// load.
class CompanyBadge extends StatelessWidget {
  const new({required this.workspace, this.size = SolaSize.thumb, super.key});

  final MemberWorkspace workspace;

  /// Diameter.
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = SolaAvatar(
      initials: workspace.orgInitials,
      size: size,
      color: SolaColors.brown,
      foreground: SolaColors.cream,
    );
    final url = workspace.orgLogoUrl;
    if (url == null) return initials;
    // A logo is drawn on white whatever its own colours, inside a ring so
    // a white logo still has an edge.
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.12),
        decoration: BoxDecoration(
          color: SolaColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: SolaColors.line),
        ),
        child: Image(
          image: LogoImage(url),
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => initials,
        ),
      ),
    );
  }
}

/// The company's logo as it is, [height] tall (and up to [maxWidth]
/// wide), for the home header. Nothing when it has none or it can't load:
/// the company's name is shown beside it either way.
class CompanyLogo extends StatelessWidget {
  const new({
    required this.url,
    this.height = 40,
    this.maxWidth = 160,
    super.key,
  });

  final String url;
  final double height;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxHeight: height, maxWidth: maxWidth),
      child: Image(
        image: LogoImage(url),
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    ),
  );
}

/// A logo from its signed link, cached by the link's path. The server
/// signs a new link on every `/me`, but the path only changes with the
/// logo, so the app keeps the image it already has instead of fetching
/// and flashing it again on each refresh.
@immutable
class LogoImage extends ImageProvider<LogoImage> {
  new(this.url) : _path = Uri.parse(url).replace(query: '').toString();

  final String url;
  final String _path;

  @override
  Future<LogoImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(LogoImage key, ImageDecoderCallback decode) {
    final network = NetworkImage(key.url);
    return network.loadImage(network, decode);
  }

  @override
  bool operator ==(Object other) => other is LogoImage && other._path == _path;

  @override
  int get hashCode => _path.hashCode;
}
