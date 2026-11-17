import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sola_ui/src/brand/logo.g.dart';

/// SolaCliq's mark: the sun rising behind MarkCliq's awning
/// (`design/logo/kit`, generated into `logo.g.dart`).
class SolaLogo extends StatelessWidget {
  /// The mark at [width].
  const new({required this.width, this.semanticsLabel, super.key});

  /// The width of the ink; the height follows the mark's proportions.
  final double width;

  /// Read out by screen readers; null hides the mark from them (decorative).
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) => SvgPicture.string(
    solaLogoSvg,
    width: width,
    height: width / solaLogoAspect,
    semanticsLabel: semanticsLabel,
    excludeFromSemantics: semanticsLabel == null,
  );
}

/// The launch screen's square: the mark over the "SolaCliq" wordmark,
/// exactly as Android draws its splash (`ic_splash`, 288 dp), so the app's
/// own splash continues it without a jump.
class SolaSplashMark extends StatelessWidget {
  /// The square, [size] wide.
  const new({this.semanticsLabel, super.key});

  /// Android's splash icon size, in dp.
  static const double size = solaSplashSize;

  /// Read out by screen readers; null hides it from them (decorative).
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) => SvgPicture.string(
    solaSplashSvg,
    width: size,
    height: size,
    semanticsLabel: semanticsLabel,
    excludeFromSemantics: semanticsLabel == null,
  );
}

/// The "SolaCliq" wordmark as drawn under the mark ("Sola" upright, "Cliq"
/// oblique, the i's dot a sun), for places that name the product.
class SolaWordmark extends StatelessWidget {
  /// The wordmark [height] tall (its ink, the sun dot to the q's tail).
  const new({required this.height, this.semanticsLabel, super.key});

  /// The ink's height; the width follows the wordmark's proportions.
  final double height;

  /// Read out by screen readers; null hides it from them (decorative).
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) => SvgPicture.string(
    solaWordmarkSvg,
    height: height,
    width: height * solaWordmarkAspect,
    semanticsLabel: semanticsLabel,
    excludeFromSemantics: semanticsLabel == null,
  );
}
