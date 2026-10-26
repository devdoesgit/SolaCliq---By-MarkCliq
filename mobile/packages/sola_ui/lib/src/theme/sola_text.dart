import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/src/tokens/tokens.g.dart';

// Bundled with this package (OFL). Inter is a variable font, so the weight
// is also set on its `wght` axis. It stands in for SF Pro, which the designs
// name first.
const _package = 'sola_ui';
const _sansFamily = 'Inter';

/// The sans family name as `ThemeData.fontFamily` needs it from another
/// package.
const solaSansFontFamily = 'packages/$_package/$_sansFamily';

/// A style from the SolaCliq type scale.
///
/// Uppercase styles are set in uppercase by [SolaText]; [textStyle] can't
/// carry case, so use [SolaText] rather than a raw [Text] with these styles.
enum SolaTextStyle {
  /// The welcome headline.
  display(SolaTextTokens.display, header: true),

  /// Intro slide titles.
  intro(SolaTextTokens.intro, header: true),

  /// Log in title.
  largeTitle(SolaTextTokens.largeTitle, header: true),

  /// Screen titles.
  title(SolaTextTokens.title, header: true),

  /// Invite title.
  titleSm(SolaTextTokens.titleSm, header: true),

  /// Sheet titles.
  sheetTitle(SolaTextTokens.sheetTitle, header: true),

  /// Photo card title.
  cardTitle(SolaTextTokens.cardTitle),

  /// Section titles: Up next.
  section(SolaTextTokens.section, header: true),

  /// The word after a big number: tasks.
  headlineLabel(SolaTextTokens.headlineLabel),

  /// The home's headline number.
  numberXl(SolaTextTokens.numberXl),

  /// Smaller headline numbers.
  numberLg(SolaTextTokens.numberLg),

  /// An amount being typed.
  amount(SolaTextTokens.amount),

  /// Energy today.
  energy(SolaTextTokens.energy),

  /// The quote estimate.
  estimate(SolaTextTokens.estimate),

  /// Tile values.
  stat(SolaTextTokens.stat),

  /// Keypad digits and code boxes.
  keypad(SolaTextTokens.keypad),

  /// Navigation bar titles, names in headers.
  navTitle(SolaTextTokens.navTitle),

  /// Buttons.
  button(SolaTextTokens.button),

  /// Navigation links: Cancel, Done.
  link(SolaTextTokens.link),

  /// Intro text.
  bodyLg(SolaTextTokens.bodyLg),

  /// First line of a row.
  rowTitle(SolaTextTokens.rowTitle),

  /// Typed values and read-only values.
  input(SolaTextTokens.input),

  /// Subtitles under titles, link lines.
  body(SolaTextTokens.body),

  /// Emphasised lines.
  bodyStrong(SolaTextTokens.bodyStrong),

  /// Values in review rows.
  rowValue(SolaTextTokens.rowValue),

  /// Labels in review rows, paragraphs in cards.
  small(SolaTextTokens.small),

  /// Chips and segments.
  chip(SolaTextTokens.chip),

  /// Second lines of rows, notes.
  meta(SolaTextTokens.meta),

  /// Labels above inputs.
  fieldLabel(SolaTextTokens.fieldLabel),

  /// Captions under bars.
  caption(SolaTextTokens.caption),

  /// Status pills.
  pill(SolaTextTokens.pill),

  /// Eyebrows and section labels.
  eyebrow(SolaTextTokens.eyebrow),

  /// Week strip day names.
  day(SolaTextTokens.day),

  /// Footer marks.
  eyebrowSm(SolaTextTokens.eyebrowSm);

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
      fontVariations: [FontVariation.weight(weight.value.toDouble())],
    );
  }

  /// The style as a [TextStyle] in [color] (ink by default).
  TextStyle textStyle({Color color = SolaColors.ink}) =>
      _styles[index].copyWith(color: color);

  static final List<TextStyle> _styles = [
    for (final style in values) _fromToken(style.token),
  ];

  static TextStyle _fromToken(SolaTextToken t) => TextStyle(
    fontFamily: _sansFamily,
    package: _package,
    fontVariations: [FontVariation.weight(t.fontWeight.toDouble())],
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
