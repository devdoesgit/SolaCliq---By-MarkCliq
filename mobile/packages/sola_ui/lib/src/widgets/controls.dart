import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/src/icons/sola_icon.dart';
import 'package:sola_ui/src/theme/sola_text.dart';
import 'package:sola_ui/src/theme/sola_tone.dart';
import 'package:sola_ui/src/tokens/tokens.g.dart';
import 'package:sola_ui/src/widgets/semantics_id.dart';
import 'package:sola_ui/src/widgets/tappable.dart';

/// What a [SolaButton] is for.
enum SolaButtonVariant {
  /// The screen's main action: sun yellow with a warm glow.
  sun,

  /// A main action that needs weight: dark brown (Review, after uploads).
  dark,

  /// A secondary action on cream: white with a soft shadow (Log out).
  white,

  /// On a dark photo card: cream.
  cream,

  /// A quiet action as muted text only (Decline).
  text,

  /// A secondary action as ink text, with an icon if any (I run a solar
  /// EPC company).
  link,

  /// A text action that raises a problem: in red (Report a problem).
  warn;

  /// Text only, no fill.
  bool get isText => this == text || this == link || this == warn;
}

/// A SolaCliq button: a pill, 54px tall (40 when [compact]), pressed state
/// shown at once.
///
/// Every button needs a [Key] so tests and mobile-mcp can find it.
class SolaButton extends StatelessWidget {
  /// Creates a button. A null [onPressed] shows the disabled style.
  const new({
    required Key super.key,
    required this.label,
    required this.onPressed,
    this.variant = SolaButtonVariant.sun,
    this.compact = false,
    this.small = false,
    this.expand = true,
    this.icon,
    this.semanticsLabel,
  });

  /// The visible label, sentence case.
  final String label;

  /// Called when tapped. Null disables it.
  final VoidCallback? onPressed;

  /// Sun, dark, white, cream or text.
  final SolaButtonVariant variant;

  /// 40px tall with 15px text, for buttons inside cards.
  final bool compact;

  /// 32px tall, for an action inside a row ("Add").
  final bool small;

  /// Fills the available width.
  final bool expand;

  /// An icon before the label.
  final SolaIcons? icon;

  /// Spoken label when [label] alone isn't clear.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return SolaTappable(
      semanticsLabel: semanticsLabel ?? label,
      identifier: semanticsIdentifier(key),
      onTap: onPressed,
      builder: (context, state) {
        final (fill, text, shadow) = _colors(state);
        final icon = this.icon;
        final style = small
            ? SolaTextStyle.chip
            : compact
            ? SolaTextStyle.bodyStrong
            : SolaTextStyle.button;
        return ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: SolaSize.tapMin,
            minWidth: expand ? double.infinity : SolaSize.tapMin,
          ),
          child: Center(
            heightFactor: 1,
            widthFactor: expand ? null : 1,
            child: AnimatedContainer(
              duration: SolaMotion.durationInstant,
              height: small
                  ? 32
                  : compact || variant.isText
                  ? 40
                  : SolaSize.button,
              width: expand ? double.infinity : null,
              padding: EdgeInsets.symmetric(
                horizontal: small
                    ? SolaSpace.space12
                    : compact
                    ? SolaSpace.space18
                    : SolaSpace.space22,
              ),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(SolaRadius.radiusPill),
                boxShadow: shadow,
                border: state.focused
                    ? Border.all(color: SolaColors.focus, width: 2)
                    : null,
              ),
              child: Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: SolaSpace.space8,
                children: [
                  if (icon != null)
                    SolaIcon(icon, size: small ? 16 : 20, color: text),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: variant.isText
                          ? SolaTextStyle.body.withWeight(
                              SolaTextStyle.body.textStyle(color: text),
                              FontWeight.w500,
                            )
                          : style.textStyle(color: text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  (Color, Color, List<BoxShadow>) _colors(SolaTapState state) {
    const none = <BoxShadow>[];
    if (!state.enabled) {
      return variant.isText
          ? (const Color(0x00000000), SolaColors.faint, none)
          : (SolaColors.track, SolaColors.muted, none);
    }
    final down = state.pressed;
    return switch (variant) {
      SolaButtonVariant.sun => (
        down ? const Color(0xFFE8B637) : SolaColors.sun,
        SolaColors.ink,
        down ? none : SolaShadows.sun,
      ),
      SolaButtonVariant.dark => (
        down ? SolaColors.ink : SolaColors.brown,
        SolaColors.cream,
        down ? none : SolaShadows.lift,
      ),
      SolaButtonVariant.white => (
        down ? SolaColors.tan : SolaColors.surface,
        SolaColors.ink,
        SolaShadows.soft,
      ),
      SolaButtonVariant.cream => (
        down ? SolaColors.tan : SolaColors.cream,
        SolaColors.ink,
        none,
      ),
      SolaButtonVariant.text => (
        down ? SolaColors.tan : const Color(0x00000000),
        SolaColors.muted,
        none,
      ),
      SolaButtonVariant.link => (
        down ? SolaColors.tan : const Color(0x00000000),
        SolaColors.ink,
        none,
      ),
      SolaButtonVariant.warn => (
        down ? SolaColors.dangerTint : const Color(0x00000000),
        SolaColors.danger,
        none,
      ),
    };
  }
}

/// The 40px round white button of the navigation bar: back, close, the
/// bell.
class SolaCircleButton extends StatelessWidget {
  /// Creates the button.
  const new({
    required Key super.key,
    required this.icon,
    required this.semanticsLabel,
    required this.onPressed,
    this.badge = false,
    this.color = SolaColors.surface,
  });

  /// The icon.
  final SolaIcons icon;

  /// Fill: white by default; tan or sun for actions in a card.
  final Color color;

  /// What a screen reader says: "Back".
  final String semanticsLabel;

  /// Called when tapped.
  final VoidCallback? onPressed;

  /// Shows an unread dot.
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return SolaTappable(
      identifier: semanticsIdentifier(key),
      semanticsLabel: semanticsLabel,
      onTap: onPressed,
      builder: (context, state) => SizedBox.square(
        dimension: SolaSize.tapMin,
        child: Center(
          child: AnimatedContainer(
            duration: SolaMotion.durationInstant,
            width: SolaSize.navButton,
            height: SolaSize.navButton,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: state.pressed
                  ? Color.lerp(color, SolaColors.ink, 0.12)
                  : color,
              boxShadow: color == SolaColors.surface ? SolaShadows.soft : null,
              border: state.focused
                  ? Border.all(color: SolaColors.focus, width: 2)
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SolaIcon(icon, size: 20),
                if (badge)
                  Positioned(
                    top: 9,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: SolaColors.danger,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: SolaColors.surface,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The navigation bar: a round button at the left, a title (and step line)
/// in the middle, a link or button at the right.
class SolaNavBar extends StatelessWidget {
  /// Creates the bar.
  const new({
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    super.key,
  });

  /// Usually a back or close [SolaCircleButton].
  final Widget? leading;

  /// The screen's name.
  final String? title;

  /// Under the title: "Step 1 of 3".
  final String? subtitle;

  /// A [SolaTextLink] ("Cancel") or a close button.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    final subtitle = this.subtitle;
    return Padding(
      padding: const EdgeInsets.only(top: SolaSpace.space4),
      // At least 52; taller when the text is scaled up.
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Transform.translate(
                  // The button's tap area overhangs its 40px circle.
                  offset: const Offset(-4, 0),
                  child: leading,
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 1,
                children: [
                  if (title != null)
                    SolaText(
                      title,
                      style: SolaTextStyle.navTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (subtitle != null)
                    SolaText(
                      subtitle,
                      style: SolaTextStyle.fieldLabel,
                      fontWeight: FontWeight.w400,
                      color: SolaColors.muted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            SizedBox(
              width: 72,
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: trailing,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A text-only action: "Cancel", "Edit", "Forgot password?", "See all".
class SolaTextLink extends StatelessWidget {
  /// Creates the link.
  const new(
    this.label, {
    required Key super.key,
    required this.onPressed,
    this.style = SolaTextStyle.link,
    this.color = SolaColors.tanText,
  });

  /// The words.
  final String label;

  /// Called when tapped.
  final VoidCallback? onPressed;

  /// Text style.
  final SolaTextStyle style;

  /// Text colour.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SolaTappable(
      identifier: semanticsIdentifier(key),
      semanticsLabel: label,
      onTap: onPressed,
      builder: (context, state) => ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: SolaSize.tapMin,
          minWidth: SolaSize.tapMin,
        ),
        child: Center(
          widthFactor: 1,
          child: Opacity(
            opacity: state.pressed ? 0.5 : 1,
            child: SolaText(
              label,
              style: style,
              color: color,
              fontWeight: style == SolaTextStyle.link ? null : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// A line with one link in it: "New to SolaCliq? Create account". The
/// link is in ink and bold; a screen reader announces it.
class SolaLinkText extends StatefulWidget {
  /// Creates the line: [before], the [link], then [after].
  const new({
    required this.link,
    required this.onTap,
    this.before = '',
    this.after = '',
    this.style = SolaTextStyle.body,
    this.color = SolaColors.muted,
    this.linkColor = SolaColors.ink,
    this.textAlign = TextAlign.center,
    super.key,
  });

  /// Text before the link.
  final String before;

  /// The link's words.
  final String link;

  /// Text after the link.
  final String after;

  /// Called when the link is tapped.
  final VoidCallback onTap;

  /// Text style of the line.
  final SolaTextStyle style;

  /// Colour of the plain text.
  final Color color;

  /// Colour of the link.
  final Color linkColor;

  /// How the line is aligned.
  final TextAlign textAlign;

  @override
  State<SolaLinkText> createState() => _SolaLinkTextState();
}

class _SolaLinkTextState extends State<SolaLinkText> {
  late final _recognizer = TapGestureRecognizer()..onTap = _tap;

  void _tap() => widget.onTap();

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.style.textStyle(color: widget.color);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          if (widget.before.isNotEmpty) TextSpan(text: widget.before),
          TextSpan(
            text: widget.link,
            recognizer: _recognizer,
            style: widget.style
                .withWeight(base, FontWeight.w600)
                .copyWith(color: widget.linkColor),
          ),
          if (widget.after.isNotEmpty) TextSpan(text: widget.after),
        ],
      ),
      textAlign: widget.textAlign,
    );
  }
}

/// The iOS switch: dark brown when on, with a white knob.
class SolaSwitch extends StatelessWidget {
  /// Creates the switch.
  const new({required this.value, required this.onChanged, super.key});

  /// On or off.
  final bool value;

  /// Called with the new value.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: SolaMotion.durationFast,
        curve: SolaMotion.easeStandard,
        width: 51,
        height: 31,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? SolaColors.brown : SolaColors.track,
          borderRadius: BorderRadius.circular(SolaRadius.radiusPill),
        ),
        child: AnimatedAlign(
          duration: SolaMotion.durationFast,
          curve: SolaMotion.easeStandard,
          alignment: value
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: Container(
            width: 27,
            height: 27,
            decoration: const BoxDecoration(
              color: SolaColors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x2E000000),
                  offset: Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One option of [SolaChips] or [SolaSegmented].
@immutable
class SolaChoice<T> {
  /// Creates an option.
  const new(this.value, this.label);

  /// The value this option stands for.
  final T value;

  /// What the option says.
  final String label;
}

/// A wrap of pill chips, one chosen: brown when chosen, white otherwise.
class SolaChips<T> extends StatelessWidget {
  /// Creates the chips. Each chip's key is `<key>_<index>`.
  const new({
    required ValueKey<String> super.key,
    required this.label,
    required this.choices,
    required this.selected,
    required this.onChanged,
  });

  /// What the chips choose; read out with each chip.
  final String label;

  /// The options.
  final List<SolaChoice<T>> choices;

  /// The value chosen now.
  final T? selected;

  /// Called with the chosen value.
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final key = this.key! as ValueKey<String>;
    // Each chip's target already adds 12px above and below it.
    return Wrap(
      spacing: SolaSpace.space8,
      children: [
        for (final (i, choice) in choices.indexed)
          _Chip(
            id: '${key.value}_$i',
            label: '$label: ${choice.label}',
            text: choice.label,
            selected: choice.value == selected,
            onTap: () => onChanged(choice.value),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const new({
    required this.id,
    required this.label,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String id;
  final String label;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SolaTappable(
      key: ValueKey(id),
      identifier: id,
      semanticsLabel: label,
      selected: selected,
      onTap: onTap,
      builder: (context, state) => ConstrainedBox(
        // A 48px target around the 36px chip.
        constraints: const BoxConstraints(minHeight: SolaSize.tapMin),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: AnimatedContainer(
            duration: SolaMotion.durationFast,
            height: SolaSize.chip,
            padding: const EdgeInsets.symmetric(horizontal: SolaSpace.space14),
            decoration: BoxDecoration(
              color: selected
                  ? SolaColors.brown
                  : state.pressed
                  ? SolaColors.tan
                  : SolaColors.surface,
              borderRadius: BorderRadius.circular(SolaRadius.radiusPill),
              boxShadow: selected ? null : SolaShadows.soft,
              border: state.focused
                  ? Border.all(color: SolaColors.focus, width: 2)
                  : null,
            ),
            child: Center(
              widthFactor: 1,
              child: SolaText(
                text,
                style: SolaTextStyle.chip,
                color: selected ? SolaColors.cream : SolaColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The iOS segmented control: a tan track with a white thumb under the
/// chosen segment.
class SolaSegmented<T> extends StatelessWidget {
  /// Creates the control. Each segment's key is `<key>_<index>`.
  const new({
    required ValueKey<String> super.key,
    required this.label,
    required this.choices,
    required this.selected,
    required this.onChanged,
  });

  /// What the control chooses; read out with each segment.
  final String label;

  /// The segments.
  final List<SolaChoice<T>> choices;

  /// The value chosen now.
  final T selected;

  /// Called with the chosen value.
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final key = this.key! as ValueKey<String>;
    // The 36px track sits inside 48px segments, so each is a full target.
    return Stack(
      children: [
        Positioned.fill(
          top: (SolaSize.tapMin - 36) / 2,
          bottom: (SolaSize.tapMin - 36) / 2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: SolaColors.segmentTrack,
              borderRadius: BorderRadius.circular(SolaRadius.radius11),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SolaSpace.space2),
          child: Row(
            children: [
              for (final (i, choice) in choices.indexed)
                Expanded(
                  child: SolaTappable(
                    key: ValueKey('${key.value}_$i'),
                    identifier: '${key.value}_$i',
                    semanticsLabel: '$label: ${choice.label}',
                    selected: choice.value == selected,
                    onTap: () => onChanged(choice.value),
                    builder: (context, state) {
                      final on = choice.value == selected;
                      return SizedBox(
                        height: SolaSize.tapMin,
                        child: Center(
                          child: AnimatedContainer(
                            duration: SolaMotion.durationFast,
                            height: 32,
                            decoration: BoxDecoration(
                              color: on ? SolaColors.surface : null,
                              borderRadius: BorderRadius.circular(
                                SolaRadius.radius9,
                              ),
                              boxShadow: on ? SolaShadows.thumb : null,
                              border: state.focused
                                  ? Border.all(
                                      color: SolaColors.focus,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Center(
                              child: SolaText(
                                choice.label,
                                style: SolaTextStyle.chip,
                                fontWeight: on ? FontWeight.w600 : null,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A status pill: a word on its tone's tint, with an optional icon.
class SolaPill extends StatelessWidget {
  /// Creates the pill.
  const new(this.label, {this.tone = SolaTone.neutral, this.icon, super.key});

  /// The word: "Approved", "Proof due".
  final String label;

  /// Its meaning.
  final SolaTone tone;

  /// An icon before the word.
  final SolaIcons? icon;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    return Container(
      height: SolaSize.pill,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(SolaRadius.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: SolaSpace.space4,
        children: [
          if (icon != null) SolaIcon(icon, size: 12, color: tone.foreground),
          Flexible(
            child: SolaText(
              label,
              style: SolaTextStyle.pill,
              color: tone.foreground,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
