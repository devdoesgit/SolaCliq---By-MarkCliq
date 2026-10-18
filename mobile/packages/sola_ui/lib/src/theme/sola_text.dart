import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/src/tokens/tokens.g.dart';

// Bundled with this package (OFL). Space Grotesk is a variable font, so the
// weight is also set on its `wght` axis.
const _package = 'sola_ui';
const _sansFamily = 'SpaceGrotesk';
const _monoFamily = 'SpaceMono';

/// The sans family name as `ThemeData.fontFamily` needs it from another
/// package.
const solaSansFontFamily = 'packages/$_package/$_sansFamily';

/// A style from the SolaCliq type scale.
///
/// Headings and `label` are set in uppercase by [SolaText]; [textStyle] can't
/// carry case, so use [SolaText] rather than a raw [Text] with these styles.
enum SolaTextStyle {
  /// Admin page titles and the customer's install screen title.
  display(SolaTextTokens.display, header: true),

  /// Mobile screen titles.
  h1(SolaTextTokens.h1, header: true),

  /// Groups within a screen.
  h2(SolaTextTokens.h2, header: true),

  /// The first line of a list row or job.
  title(SolaTextTokens.title),

  /// Running text, field values, buttons.
  body(SolaTextTokens.body),

  /// Second lines and help text. Nothing on mobile is smaller, except label.
  bodySm(SolaTextTokens.bodySm),

  /// Field labels, eyebrows, timestamps, IDs. Mono, uppercase.
  label(SolaTextTokens.label),

  /// Button labels. Mono, uppercase, widely tracked.
  button(SolaTextTokens.button),

  /// Amounts, kW, counts, coordinates. Mono, tabular figures.
  num(SolaTextTokens.num),

  /// The one headline figure on a screen.
  numLg(SolaTextTokens.numLg);

  new(this.token, {this.header = false});

  /// The token this style is built from.
  final SolaTextToken token;

  /// Whether text in this style is a heading for screen readers.
  final bool header;

  /// [base] with its weight changed to [weight], on the variable axis too.
  TextStyle withWeight(TextStyle base, FontWeight? weight) {
    if (weight == null) return base;
    return base.copyWith(
      fontWeight: weight,
      fontVariations: token.mono
          ? null
          : [FontVariation.weight(weight.value.toDouble())],
    );
  }

  /// The style as a [TextStyle] in [color] (ink by default).
  TextStyle textStyle({Color color = SolaColors.ink}) =>
      _styles[index].copyWith(color: color);

  static final List<TextStyle> _styles = [
    for (final style in values) _fromToken(style.token),
  ];

  static TextStyle _fromToken(SolaTextToken t) => TextStyle(
    fontFamily: t.mono ? _monoFamily : _sansFamily,
    package: _package,
    fontVariations: t.mono
        ? null
        : [FontVariation.weight(t.fontWeight.toDouble())],
    fontSize: t.fontSize,
    height: t.lineHeight / t.fontSize,
    leadingDistribution: TextLeadingDistribution.even,
    fontWeight: FontWeight.values.firstWhere((w) => w.value == t.fontWeight),
    letterSpacing: t.letterSpacingEm * t.fontSize,
    fontFeatures: t.mono ? const [FontFeature.tabularFigures()] : null,
    color: SolaColors.ink,
  );
}

/// Text in a SolaCliq type style, with the style's case and heading
/// semantics applied.
class SolaText extends StatelessWidget {
  /// Creates text in [style].
  const new(
    this.data, {
    this.style = SolaTextStyle.body,
    this.color = SolaColors.ink,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    super.key,
  });

  /// The text, in its natural case. Uppercase styles convert it.
  final String data;

  /// The type style.
  final SolaTextStyle style;

  /// Text colour; a colour token.
  final Color color;

  /// Overrides the style's weight, for emphasis within the scale. Use
  /// [SolaTextStyle.withWeight] when building a [TextStyle] by hand.
  final FontWeight? fontWeight;

  /// How the text is aligned.
  final TextAlign? textAlign;

  /// Maximum lines before [overflow] applies.
  final int? maxLines;

  /// How overflowing text is shown.
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      style.token.uppercase ? data.toUpperCase() : data,
      style: style.withWeight(style.textStyle(color: color), fontWeight),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
    return style.header ? Semantics(header: true, child: text) : text;
  }
}
