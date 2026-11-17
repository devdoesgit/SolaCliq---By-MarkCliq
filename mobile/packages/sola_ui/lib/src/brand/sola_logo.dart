import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sola_ui/src/brand/logo.g.dart';
import 'package:sola_ui/src/theme/sola_text.dart';
import 'package:sola_ui/src/tokens/tokens.g.dart';

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

/// SolaCliq's horizontal lockup, the mark beside the wordmark (or the
/// wordmark alone), with an optional [byline] ("by MarkCliq") set on the
/// wordmark's baseline. For the places that introduce the product: the
/// welcome screen, the admin's "use the website" screen.
class SolaLockup extends StatelessWidget {
  /// The lockup [height] tall (the mark's height), with an optional
  /// [byline] after it.
  const new({
    required this.height,
    this.mark = true,
    this.byline,
    this.semanticsLabel,
    super.key,
  });

  /// The mark's height, or the wordmark's when there's no [mark].
  final double height;

  /// Whether the mark leads; false draws the wordmark alone.
  final bool mark;

  /// Muted text after the wordmark, on its baseline.
  final String? byline;

  /// Read out by screen readers for the whole line; null hides it from
  /// them (decorative).
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final byline = this.byline;
    final label = semanticsLabel;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: height * 0.28,
      children: [
        SvgPicture.string(
          mark ? solaLockupSvg : solaWordmarkSvg,
          height: height,
          width: height * (mark ? solaLockupAspect : solaWordmarkAspect),
          excludeFromSemantics: true,
        ),
        if (byline != null)
          SizedBox(
            height: height,
            child: Baseline(
              baseline:
                  height * (mark ? solaLockupBaseline : solaWordmarkBaseline),
              baselineType: TextBaseline.alphabetic,
              child: SolaBrandText(byline, color: SolaColors.muted),
            ),
          ),
      ],
    );
    return label == null
        ? ExcludeSemantics(child: row)
        : Semantics(label: label, excludeSemantics: true, child: row);
  }
}

/// Text that names MarkCliq the way its wordmark does: "Mark" upright,
/// "Cliq" italic, as SolaCliq's own wordmark sets its "Cliq". For brand
/// lines ("by MarkCliq", "Secured by MarkCliq"), not running sentences.
class SolaBrandText extends StatelessWidget {
  /// [text] in [style], with each "MarkCliq" in it set as the brand.
  const new(
    this.text, {
    this.style = SolaTextStyle.small,
    this.color = SolaColors.ink,
    super.key,
  });

  /// The words; every "MarkCliq" in them gets its italic "Cliq".
  final String text;

  /// Text style.
  final SolaTextStyle style;

  /// Text colour.
  final Color color;

  static const _brand = 'MarkCliq';

  @override
  Widget build(BuildContext context) {
    final parts = text.split(_brand);
    const italic = TextStyle(fontStyle: FontStyle.italic);
    return Text.rich(
      TextSpan(
        style: style.textStyle(color: color),
        children: [
          for (var i = 0; i < parts.length; i++) ...[
            if (i > 0) ...[
              const TextSpan(text: 'Mark'),
              const TextSpan(text: 'Cliq', style: italic),
            ],
            if (parts[i].isNotEmpty) TextSpan(text: parts[i]),
          ],
        ],
      ),
    );
  }
}
