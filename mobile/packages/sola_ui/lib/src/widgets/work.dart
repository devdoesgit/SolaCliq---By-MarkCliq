import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/src/icons/sola_icon.dart';
import 'package:sola_ui/src/theme/sola_text.dart';
import 'package:sola_ui/src/theme/sola_tone.dart';
import 'package:sola_ui/src/tokens/tokens.g.dart';
import 'package:sola_ui/src/widgets/rows.dart';
import 'package:sola_ui/src/widgets/semantics_id.dart';
import 'package:sola_ui/src/widgets/tappable.dart';

/// A small avatar and a name: who said something.
class SolaPersonChip extends StatelessWidget {
  /// Creates the chip.
  const new({
    required this.initials,
    required this.label,
    this.color = SolaColors.ink,
    super.key,
  });

  /// One or two letters.
  final String initials;

  /// "Rajeeb Kumar · Admin".
  final String label;

  /// Label colour.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: SolaSpace.space8,
      children: [
        SolaAvatar(
          initials: initials,
          size: 24,
          color: SolaColors.brown,
          foreground: SolaColors.cream,
        ),
        Flexible(
          child: SolaText(
            label,
            style: SolaTextStyle.meta,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// The status at the top of a task: an icon, a title in the tone's colour,
/// a line, and who it came from.
class SolaBanner extends StatelessWidget {
  /// Creates the banner.
  const new({
    required this.title,
    required this.icon,
    this.body,
    this.tone = SolaTone.neutral,
    this.personInitials,
    this.personLabel,
    super.key,
  });

  /// "Waiting for approval".
  final String title;

  /// The icon in the circle.
  final SolaIcons icon;

  /// What it means for the person.
  final String? body;

  /// Its meaning; tints the card and colours the title.
  final SolaTone tone;

  /// Who it came from, under the line: their initials…
  final String? personInitials;

  /// …and "Rajeeb Kumar · Admin", in the tone's colour.
  final String? personLabel;

  @override
  Widget build(BuildContext context) {
    final body = this.body;
    final initials = personInitials;
    final label = personLabel;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(SolaSpace.space16),
        decoration: BoxDecoration(
          color: tone.background,
          borderRadius: BorderRadius.circular(SolaRadius.radius22),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: SolaSpace.space12,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: SolaColors.cream,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SolaIcon(icon, size: 16, color: tone.foreground),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: SolaSpace.space2,
                children: [
                  SolaText(
                    title,
                    style: SolaTextStyle.bodyStrong,
                    color: tone.foreground,
                  ),
                  if (body != null) SolaText(body, style: SolaTextStyle.small),
                  if (initials != null && label != null)
                    Padding(
                      padding: const EdgeInsets.only(top: SolaSpace.space6),
                      child: SolaPersonChip(
                        initials: initials,
                        label: label,
                        color: tone.foreground,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A checklist line: a square box, ticked and struck through when done.
class SolaCheckRow extends StatelessWidget {
  /// Creates the row. A null [onChanged] shows it read-only.
  const new({
    required Key super.key,
    required this.text,
    required this.done,
    this.onChanged,
  });

  /// The step.
  final String text;

  /// Whether it is done.
  final bool done;

  /// Called with the new value.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return MergeSemantics(
      child: Semantics(
        checked: done,
        identifier: semanticsIdentifier(key),
        child: SolaTappable(
          semanticsLabel: text,
          isButton: false,
          onTap: onChanged == null ? null : () => onChanged(!done),
          builder: (context, state) => ConstrainedBox(
            constraints: const BoxConstraints(minHeight: SolaSize.tapMin),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: SolaSpace.space10),
              child: Row(
                spacing: SolaSpace.space12,
                children: [
                  AnimatedContainer(
                    duration: SolaMotion.durationFast,
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: done ? SolaColors.brown : SolaColors.surface,
                      borderRadius: BorderRadius.circular(
                        SolaRadius.radius3 * 2,
                      ),
                      border: done
                          ? null
                          : Border.all(color: SolaColors.dashed, width: 1.5),
                    ),
                    child: done
                        ? const Center(
                            child: SolaIcon(
                              SolaIcons.check,
                              size: 14,
                              color: SolaColors.cream,
                            ),
                          )
                        : null,
                  ),
                  Expanded(
                    child: Text(
                      text,
                      style: SolaTextStyle.bodyLg
                          .textStyle(
                            color: done ? SolaColors.muted : SolaColors.ink,
                          )
                          .copyWith(
                            decoration: done
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What a [SolaPhotoTile] shows.
enum SolaPhotoState {
  /// No photo yet: a camera.
  empty,

  /// Taken and accepted: a green tick.
  done,

  /// The admin asked for it again.
  retake,
}

/// One proof photo slot: the photo (or a camera to take it) and its name.
class SolaPhotoTile extends StatelessWidget {
  /// Creates the tile.
  const new({
    required Key super.key,
    required this.label,
    required this.state,
    required this.semanticsLabel,
    this.image,
    this.retakeLabel = 'Retake',
    this.onTap,
    this.size = 74,
  });

  /// "Clamp".
  final String label;

  /// Empty, done or to retake.
  final SolaPhotoState state;

  /// What a screen reader says: "Clamp, photo added".
  final String semanticsLabel;

  /// The photo.
  final ImageProvider? image;

  /// The word on a photo to retake.
  final String retakeLabel;

  /// Opens the camera for this slot; null when locked.
  final VoidCallback? onTap;

  /// Width and height of the picture.
  final double size;

  @override
  Widget build(BuildContext context) {
    final image = this.image;
    return SolaTappable(
      identifier: semanticsIdentifier(key),
      semanticsLabel: semanticsLabel,
      onTap: onTap,
      builder: (context, pressed) => SizedBox(
        width: size,
        child: Column(
          spacing: SolaSpace.space6,
          children: [
            Container(
              width: size,
              height: size,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: SolaColors.cream,
                borderRadius: BorderRadius.circular(SolaRadius.radius16),
                boxShadow: image == null ? null : SolaShadows.soft,
                border: switch (state) {
                  SolaPhotoState.empty => Border.all(
                    color: SolaColors.track,
                    width: 1.5,
                  ),
                  SolaPhotoState.retake => Border.all(
                    color: SolaColors.danger,
                    width: 2,
                  ),
                  SolaPhotoState.done => null,
                },
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (image != null)
                    Image(image: image, fit: BoxFit.cover)
                  else
                    const Center(
                      child: SolaIcon(
                        SolaIcons.camera,
                        color: SolaColors.faint,
                      ),
                    ),
                  if (state == SolaPhotoState.done)
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: SolaColors.successDot,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: SolaIcon(
                            SolaIcons.check,
                            size: 11,
                            color: SolaColors.surface,
                            strokeWidth: 2.6,
                          ),
                        ),
                      ),
                    ),
                  if (state == SolaPhotoState.retake)
                    Positioned(
                      left: 5,
                      right: 5,
                      bottom: 5,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: SolaColors.danger,
                          borderRadius: BorderRadius.circular(
                            SolaRadius.radiusPill,
                          ),
                        ),
                        child: Center(
                          child: SolaText(
                            retakeLabel,
                            style: SolaTextStyle.eyebrowSm,
                            color: SolaColors.surface,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SolaText(
              label,
              style: SolaTextStyle.caption,
              color: SolaColors.muted,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// One entry of a [SolaTimeline].
@immutable
class SolaTimelineEntry {
  /// Creates an entry.
  const new({
    required this.title,
    required this.subtitle,
    required this.dot,
    this.detail,
  });

  /// "Returned by admin".
  final String title;

  /// "Rajeeb Kumar · 12:10".
  final String subtitle;

  /// The dot's colour: what kind of step it was.
  final Color dot;

  /// A line in a cream box: the admin's words, what was sent.
  final String? detail;
}

/// A history, newest first: dots joined by a line, each with its detail.
class SolaTimeline extends StatelessWidget {
  /// Creates the timeline.
  const new({required this.entries, super.key});

  /// The entries, newest first.
  final List<SolaTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, e) in entries.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: SolaSpace.space14,
              children: [
                SizedBox(
                  width: 20,
                  child: Column(
                    children: [
                      const SizedBox(height: SolaSpace.space4),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: SolaColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: SolaColors.track),
                        ),
                        child: Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: e.dot,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      if (i < entries.length - 1)
                        const Expanded(
                          child: VerticalDivider(
                            width: 2,
                            thickness: 2,
                            color: SolaColors.track,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: MergeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: SolaSpace.space20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: SolaSpace.space2,
                        children: [
                          SolaText(e.title, style: SolaTextStyle.rowTitle),
                          SolaText(
                            e.subtitle,
                            style: SolaTextStyle.small,
                            color: SolaColors.muted,
                          ),
                          if (e.detail case final detail?)
                            Container(
                              margin: const EdgeInsets.only(
                                top: SolaSpace.space8,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: SolaSpace.space14,
                                vertical: SolaSpace.space10,
                              ),
                              decoration: BoxDecoration(
                                color: SolaColors.cream,
                                borderRadius: BorderRadius.circular(
                                  SolaRadius.radius12,
                                ),
                              ),
                              child: SolaText(
                                detail,
                                style: SolaTextStyle.small,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
