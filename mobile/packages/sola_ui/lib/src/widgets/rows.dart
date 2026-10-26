import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/src/icons/sola_icon.dart';
import 'package:sola_ui/src/theme/sola_text.dart';
import 'package:sola_ui/src/tokens/tokens.g.dart';
import 'package:sola_ui/src/widgets/controls.dart';
import 'package:sola_ui/src/widgets/semantics_id.dart';
import 'package:sola_ui/src/widgets/tappable.dart';

/// A text input row inside a `SolaGroup`: a small muted label over the
/// typed value, with an optional [trailing] action ("Show"). An [error]
/// shows under it in red.
class SolaFieldRow extends StatefulWidget {
  /// Creates the row. Needs a [Key]; the input itself gets `<key>_input`.
  const new({
    required ValueKey<String> super.key,
    required this.label,
    this.controller,
    this.placeholder,
    this.error,
    this.trailing,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.prefixText,
  });

  /// Above the value.
  final String label;

  /// Holds the typed text.
  final TextEditingController? controller;

  /// Shown in the empty input.
  final String? placeholder;

  /// Shown under the input, in red.
  final String? error;

  /// At the right: a "Show" link.
  final Widget? trailing;

  /// Hides the typed text (passwords).
  final bool obscureText;

  /// The keyboard to show.
  final TextInputType? keyboardType;

  /// The keyboard action button.
  final TextInputAction? textInputAction;

  /// How typed words are capitalised.
  final TextCapitalization textCapitalization;

  /// What the system may autofill.
  final Iterable<String>? autofillHints;

  /// Filters applied as the person types.
  final List<TextInputFormatter>? inputFormatters;

  /// Called on every change.
  final ValueChanged<String>? onChanged;

  /// Called when the keyboard action is pressed.
  final ValueChanged<String>? onSubmitted;

  /// Fixed text before the input: "+91 ".
  final String? prefixText;

  @override
  State<SolaFieldRow> createState() => _SolaFieldRowState();
}

class _SolaFieldRowState extends State<SolaFieldRow> {
  /// Above the input text: the label's 10px inset, its 16px line, 2px gap.
  static const double _labelSpace = SolaSpace.space10 + 16 + SolaSpace.space2;

  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _focus
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final key = widget.key! as ValueKey<String>;
    final error = widget.error;
    final trailing = widget.trailing;
    final prefix = widget.prefixText;
    final text = SolaTextStyle.input.textStyle();
    return Semantics(
      identifier: semanticsIdentifier(key),
      container: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _focus.requestFocus,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: Row(
            spacing: SolaSpace.space10,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The input spans the whole row, its label drawn over
                    // its top padding, so the full row is its tap target.
                    Stack(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Always shown, unlike InputDecoration's prefix.
                            if (prefix != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: SolaSpace.space10,
                                ),
                                child: ExcludeSemantics(
                                  child: Text(prefix, style: text),
                                ),
                              ),
                            Expanded(
                              child: TextField(
                                key: ValueKey('${key.value}_input'),
                                controller: widget.controller,
                                focusNode: _focus,
                                obscureText: widget.obscureText,
                                keyboardType: widget.keyboardType,
                                textInputAction: widget.textInputAction,
                                textCapitalization: widget.textCapitalization,
                                autofillHints: widget.autofillHints,
                                inputFormatters: widget.inputFormatters,
                                onChanged: widget.onChanged,
                                onSubmitted: widget.onSubmitted,
                                style: text,
                                cursorColor: SolaColors.sunDeep,
                                decoration:
                                    InputDecoration.collapsed(
                                      hintText: widget.placeholder,
                                      hintStyle: SolaTextStyle.input.textStyle(
                                        color: SolaColors.faint,
                                      ),
                                    ).copyWith(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.only(
                                        top: _labelSpace,
                                        bottom: SolaSpace.space10,
                                      ),
                                    ),
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          top: SolaSpace.space10,
                          left: 0,
                          right: 0,
                          child: IgnorePointer(
                            child: ExcludeSemantics(
                              child: SolaText(
                                widget.label,
                                style: SolaTextStyle.fieldLabel,
                                color: error != null
                                    ? SolaColors.danger
                                    : _focus.hasFocus
                                    ? SolaColors.tanText
                                    : SolaColors.muted,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: SolaSpace.space10,
                        ),
                        child: SolaText(
                          error,
                          style: SolaTextStyle.caption,
                          color: SolaColors.danger,
                        ),
                      ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// A row that shows a value and opens a choice: label, value, chevron.
class SolaValueRow extends StatelessWidget {
  /// Creates the row.
  const new({
    required Key super.key,
    required this.label,
    required this.value,
    this.onTap,
    this.error,
  });

  /// Above the value.
  final String label;

  /// The value, or a placeholder.
  final String value;

  /// Opens the choice; null makes the row read-only.
  final VoidCallback? onTap;

  /// Shown under the value, in red.
  final String? error;

  @override
  Widget build(BuildContext context) {
    final error = this.error;
    final onTap = this.onTap;
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: SolaSpace.space10),
      child: Row(
        spacing: SolaSpace.space10,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: SolaSpace.space2,
              children: [
                SolaText(
                  label,
                  style: SolaTextStyle.fieldLabel,
                  color: error != null ? SolaColors.danger : SolaColors.muted,
                ),
                SolaText(value, style: SolaTextStyle.input),
                if (error != null)
                  SolaText(
                    error,
                    style: SolaTextStyle.caption,
                    color: SolaColors.danger,
                  ),
              ],
            ),
          ),
          if (onTap != null)
            const SolaIcon(
              SolaIcons.chevronRight,
              size: 18,
              color: SolaColors.faint,
            ),
        ],
      ),
    );
    if (onTap == null) return content;
    return SolaTappable(
      identifier: semanticsIdentifier(key),
      semanticsLabel: '$label: $value',
      onTap: onTap,
      builder: (context, state) =>
          Opacity(opacity: state.pressed ? 0.6 : 1, child: content),
    );
  }
}

/// A list row: a picture at the left, a title and a line, and something at
/// the right (a pill, a chevron). Tappable when [onTap] is given.
class SolaListRow extends StatelessWidget {
  /// Creates the row.
  const new({
    required this.title,
    this.subtitle,
    this.subtitleLines = 1,
    this.leading,
    this.trailing,
    this.onTap,
    this.semanticsLabel,
    super.key,
  });

  /// The first line.
  final String title;

  /// The second line.
  final String? subtitle;

  /// How many lines the subtitle may take before it is cut.
  final int subtitleLines;

  /// A thumbnail, avatar or step number.
  final Widget? leading;

  /// A pill, a chevron, a tick.
  final Widget? trailing;

  /// Opens the item.
  final VoidCallback? onTap;

  /// What a screen reader says for a tappable row.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    final leading = this.leading;
    final trailing = this.trailing;
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: SolaSpace.space12),
      child: Row(
        spacing: SolaSpace.space14,
        children: [
          ?leading,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: SolaSpace.space2,
              children: [
                SolaText(
                  title,
                  style: SolaTextStyle.rowTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  SolaText(
                    subtitle,
                    style: SolaTextStyle.meta,
                    color: SolaColors.muted,
                    maxLines: subtitleLines,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
    final onTap = this.onTap;
    if (onTap == null) return MergeSemantics(child: content);
    return SolaTappable(
      identifier: semanticsIdentifier(key),
      semanticsLabel:
          semanticsLabel ?? (subtitle == null ? title : '$title, $subtitle'),
      onTap: onTap,
      builder: (context, state) =>
          Opacity(opacity: state.pressed ? 0.6 : 1, child: content),
    );
  }
}

/// A review row: a muted label at the left, the value at the right.
class SolaKeyValueRow extends StatelessWidget {
  /// Creates the row.
  const new(this.label, this.value, {super.key});

  /// What the value is.
  final String label;

  /// The value.
  final String value;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: SolaSpace.space10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: SolaSpace.space12,
          children: [
            SolaText(
              label,
              style: SolaTextStyle.small,
              color: SolaColors.muted,
            ),
            Expanded(
              child: SolaText(
                value,
                style: SolaTextStyle.rowValue,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A row with a switch: text at the left (and a line under it), the
/// switch at the right.
class SolaToggleRow extends StatelessWidget {
  /// Creates the row.
  const new({
    required Key super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.titleStyle = SolaTextStyle.small,
  });

  /// The setting.
  final String title;

  /// More about it.
  final String? subtitle;

  /// On or off.
  final bool value;

  /// Called with the new value.
  final ValueChanged<bool> onChanged;

  /// The title's style: small for consent lines, input for settings.
  final SolaTextStyle titleStyle;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    return Semantics(
      identifier: semanticsIdentifier(key),
      toggled: value,
      label: subtitle == null ? title : '$title. $subtitle',
      excludeSemantics: true,
      onTap: () => onChanged(!value),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: SolaSpace.space12),
          child: Row(
            spacing: SolaSpace.space12,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: SolaSpace.space2,
                  children: [
                    SolaText(title, style: titleStyle),
                    if (subtitle != null)
                      SolaText(
                        subtitle,
                        style: SolaTextStyle.meta,
                        color: SolaColors.muted,
                      ),
                  ],
                ),
              ),
              SolaSwitch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

/// The photos the designs use, bundled.
enum SolaPhotos {
  /// An installer fitting panels: the welcome screen.
  heroInstall('hero-install.jpg'),

  /// A home with rooftop solar: quote cards.
  quoteHome('quote-home.jpg'),

  /// Panels being fitted.
  thumbInstall('thumb-install.jpg'),

  /// An inverter on a wall.
  thumbInverter('thumb-inverter.jpg'),

  /// A net meter.
  thumbMeter('thumb-meter.jpg'),

  /// A site survey.
  thumbSurvey('thumb-survey.jpg');

  new(this.file);

  /// The file under `assets/images/`.
  final String file;

  /// Looks up `asset:thumb-install` style references from the server's
  /// sample data; null for anything else.
  static SolaPhotos? fromReference(String? reference) {
    if (reference == null || !reference.startsWith('asset:')) return null;
    final name = '${reference.substring(6)}.jpg';
    for (final photo in values) {
      if (photo.file == name) return photo;
    }
    return null;
  }

  /// The photo as an image provider.
  ImageProvider get provider =>
      AssetImage('assets/images/$file', package: 'sola_ui');
}

/// Small drawn documents and symbols, for rows without a photo.
enum SolaGlyph {
  /// A card: Aadhaar, PAN.
  card(
    '<rect width="44" height="44" fill="#F1E7DB"/><rect x="7" y="12" '
    'width="30" height="20" rx="3" fill="#FFFFFF" stroke="#CDBBA8"/><circle '
    'cx="15" cy="21" r="3.5" fill="#C49A6C"/><path d="M22 19h10M22 24h7" '
    'stroke="#8C7F74" stroke-width="1.4" stroke-linecap="round"/>',
  ),

  /// A bill.
  bill(
    '<rect width="44" height="44" fill="#F1E7DB"/><rect x="12" y="7" '
    'width="20" height="30" rx="2" fill="#FFFFFF" stroke="#CDBBA8"/><path '
    'd="M16 14h12M16 19h12M16 24h8" stroke="#8C7F74" stroke-width="1.4" '
    'stroke-linecap="round"/><rect x="16" y="29" width="7" height="3" '
    'fill="#C49A6C"/>',
  ),

  /// A bank passbook.
  passbook(
    '<rect width="44" height="44" fill="#F1E7DB"/><rect x="8" y="11" '
    'width="28" height="22" rx="2" fill="#FFFFFF" stroke="#CDBBA8"/><path '
    'd="M8 17h28" stroke="#CDBBA8"/><path d="M12 23h14M12 28h9" '
    'stroke="#8C7F74" stroke-width="1.4" stroke-linecap="round"/>',
  ),

  /// Money: a rupee on brown.
  rupee(
    '<rect width="44" height="44" fill="#2E211B"/><path d="M15 13h14M15 '
    '18h14M19 13c6 0 8 2.5 8 5s-2 5-8 5h-3l10 9" fill="none" '
    'stroke="#E8C9A0" stroke-width="2" stroke-linecap="round" '
    'stroke-linejoin="round"/>',
  );

  new(this.svg);

  /// The 44x44 SVG content.
  final String svg;
}

/// A rounded square picture at the left of a row: a photo, a drawn
/// document, or initials or an icon on a tint.
class SolaThumb extends StatelessWidget {
  /// Creates the thumbnail.
  const new({
    this.photo,
    this.glyph,
    this.icon,
    this.size = SolaSize.thumb,
    this.round = false,
    super.key,
  });

  /// A bundled photo.
  final SolaPhotos? photo;

  /// Or a drawn document.
  final SolaGlyph? glyph;

  /// Or an icon on tan.
  final SolaIcons? icon;

  /// Width and height.
  final double size;

  /// A circle instead of a rounded square.
  final bool round;

  @override
  Widget build(BuildContext context) {
    final photo = this.photo;
    final glyph = this.glyph;
    final radius = round
        ? BorderRadius.circular(size)
        : BorderRadius.circular(
            size >= 80 ? SolaRadius.radius18 : SolaRadius.radius12,
          );
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox.square(
          dimension: size,
          child: photo != null
              ? Image(image: photo.provider, fit: BoxFit.cover)
              : glyph != null
              ? SvgPicture.string(
                  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 44 '
                  '44">${glyph.svg}</svg>',
                  fit: BoxFit.cover,
                )
              : ColoredBox(
                  color: SolaColors.tan,
                  child: icon == null
                      ? null
                      : Center(
                          child: SolaIcon(icon!, color: SolaColors.tanText),
                        ),
                ),
        ),
      ),
    );
  }
}

/// A round avatar: initials, an icon or a photo on a tint. [ring] draws
/// the 2px outline used when avatars overlap.
class SolaAvatar extends StatelessWidget {
  /// Creates the avatar.
  const new({
    this.initials,
    this.icon,
    this.photo,
    this.glyph,
    this.size = SolaSize.thumb,
    this.color = SolaColors.avatar,
    this.foreground = SolaColors.ink,
    this.ring,
    super.key,
  });

  /// One or two letters.
  final String? initials;

  /// Or an icon.
  final SolaIcons? icon;

  /// Or a photo.
  final SolaPhotos? photo;

  /// Or a drawn document.
  final SolaGlyph? glyph;

  /// Diameter.
  final double size;

  /// Fill.
  final Color color;

  /// Initials or icon colour.
  final Color foreground;

  /// Outline colour, for overlapping stacks.
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    final initials = this.initials;
    final icon = this.icon;
    final ring = this.ring;
    Widget inner;
    if (photo != null || glyph != null) {
      inner = SolaThumb(photo: photo, glyph: glyph, size: size, round: true);
    } else {
      inner = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Center(
          child: initials != null
              ? size >= 32
                    ? SolaText(
                        initials,
                        style: size >= 40
                            ? SolaTextStyle.bodyStrong
                            : SolaTextStyle.pill,
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      )
                    // Small overlapping avatars: 10px, untracked, as drawn.
                    : Text(
                        initials,
                        style: SolaTextStyle.eyebrowSm
                            .textStyle(color: foreground)
                            .copyWith(letterSpacing: 0),
                      )
              : icon != null
              ? SolaIcon(icon, size: size * 0.45, color: foreground)
              : null,
        ),
      );
    }
    if (ring == null) return ExcludeSemantics(child: inner);
    // The ring sits outside the avatar, so it takes no layout space.
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: ring, spreadRadius: 2)],
        ),
        child: inner,
      ),
    );
  }
}

/// Avatars overlapping by a few pixels, each ringed in [ring].
class SolaAvatarStack extends StatelessWidget {
  /// Creates the stack.
  const new({
    required this.avatars,
    required this.ring,
    this.overlap = 5,
    super.key,
  });

  /// The avatars, left to right.
  final List<SolaAvatar> avatars;

  /// The background they sit on.
  final Color ring;

  /// How much each overlaps the one before.
  final double overlap;

  @override
  Widget build(BuildContext context) {
    if (avatars.isEmpty) return const SizedBox.shrink();
    final size = avatars.first.size;
    final step = size - overlap;
    return SizedBox(
      width: size + step * (avatars.length - 1),
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final (i, a) in avatars.indexed)
            Positioned(
              left: step * i,
              child: SolaAvatar(
                initials: a.initials,
                icon: a.icon,
                photo: a.photo,
                glyph: a.glyph,
                size: a.size,
                color: a.color,
                foreground: a.foreground,
                ring: ring,
              ),
            ),
        ],
      ),
    );
  }
}
