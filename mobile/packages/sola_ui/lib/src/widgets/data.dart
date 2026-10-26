import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/src/icons/sola_icon.dart';
import 'package:sola_ui/src/theme/sola_text.dart';
import 'package:sola_ui/src/theme/sola_tone.dart';
import 'package:sola_ui/src/tokens/tokens.g.dart';
import 'package:sola_ui/src/widgets/controls.dart';
import 'package:sola_ui/src/widgets/rows.dart';
import 'package:sola_ui/src/widgets/semantics_id.dart';
import 'package:sola_ui/src/widgets/surfaces.dart';
import 'package:sola_ui/src/widgets/tappable.dart';

/// The big number at the top of a home: "3 tasks · on site today".
class SolaHeadline extends StatelessWidget {
  /// Creates the headline.
  const new({
    required this.value,
    required this.label,
    this.detail,
    this.style = SolaTextStyle.numberXl,
    super.key,
  });

  /// The number: "3", "₹78k".
  final String value;

  /// What it counts: "tasks".
  final String label;

  /// More about it: "on site today".
  final String? detail;

  /// Number size.
  final SolaTextStyle style;

  @override
  Widget build(BuildContext context) {
    final detail = this.detail;
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: SolaSpace.space12,
        children: [
          SolaText(value, style: style),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: SolaSpace.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SolaText(label, style: SolaTextStyle.headlineLabel),
                  if (detail != null)
                    SolaText(
                      detail,
                      style: SolaTextStyle.small,
                      color: SolaColors.muted,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A stat tile: a label and icon, a big value, and avatars with a footer.
/// [dark] is the brown tile that leads a pair.
class SolaStatTile extends StatelessWidget {
  /// Creates the tile.
  const new({
    required this.label,
    required this.value,
    this.icon,
    this.footer,
    this.avatars = const [],
    this.dark = false,
    this.onTap,
    super.key,
  });

  /// "Proof due".
  final String label;

  /// "2".
  final String value;

  /// An icon at the top right.
  final SolaIcons? icon;

  /// At the bottom right: "today".
  final String? footer;

  /// At the bottom left: who or what.
  final List<SolaAvatar> avatars;

  /// The brown tile.
  final bool dark;

  /// Opens what the tile counts.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    final footer = this.footer;
    final soft = dark ? SolaColors.onBrownMuted : SolaColors.muted;
    final tile = Container(
      height: SolaSize.tile,
      padding: const EdgeInsets.symmetric(
        horizontal: SolaSpace.space16,
        vertical: SolaSpace.space14,
      ),
      decoration: BoxDecoration(
        color: dark ? SolaColors.brown : SolaColors.surface,
        borderRadius: BorderRadius.circular(SolaRadius.radius22),
        boxShadow: dark ? SolaShadows.lift : SolaShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: SolaText(
                  label,
                  style: SolaTextStyle.eyebrow,
                  color: soft,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (icon != null) SolaIcon(icon, size: 16, color: soft),
            ],
          ),
          SolaText(
            value,
            style: SolaTextStyle.stat,
            color: dark ? SolaColors.cream : SolaColors.ink,
            maxLines: 1,
          ),
          Row(
            children: [
              SolaAvatarStack(
                avatars: avatars,
                ring: dark ? SolaColors.brown : SolaColors.surface,
              ),
              const Spacer(),
              if (footer != null)
                SolaText(footer, style: SolaTextStyle.caption, color: soft),
            ],
          ),
        ],
      ),
    );
    final onTap = this.onTap;
    if (onTap == null) return MergeSemantics(child: tile);
    return SolaTappable(
      identifier: semanticsIdentifier(key),
      semanticsLabel: '$label: $value${footer == null ? '' : ', $footer'}',
      onTap: onTap,
      builder: (context, state) => AnimatedScale(
        duration: SolaMotion.durationInstant,
        scale: state.pressed ? 0.98 : 1,
        child: tile,
      ),
    );
  }
}

/// One part of a [SolaSegmentBar].
@immutable
class SolaSegment {
  /// Creates a part, [flex] wide in [color].
  const new(this.flex, this.color);

  /// Relative width.
  final int flex;

  /// Its colour.
  final Color color;
}

/// A bar in rounded segments: stages done and to come, or a split of
/// counts.
class SolaSegmentBar extends StatelessWidget {
  /// Creates the bar.
  const new({
    required this.segments,
    this.height = 6,
    this.gap = SolaSpace.space4,
    this.semanticsLabel,
    super.key,
  });

  /// The parts, left to right.
  final List<SolaSegment> segments;

  /// Bar height.
  final double height;

  /// Gap between parts.
  final double gap;

  /// What a screen reader says: "Stage 1 of 7".
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: Row(
        spacing: gap,
        children: [
          for (final s in segments)
            Expanded(
              flex: s.flex,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: s.color,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A coloured dot and a label, as in a chart legend.
@immutable
class SolaLegendItem {
  /// Creates an item.
  const new(this.label, this.color);

  /// "12 done".
  final String label;

  /// The dot's colour.
  final Color color;
}

/// A card with a label, a segmented bar and what the bar means under it:
/// stage names spread across, or a legend.
class SolaProgressCard extends StatelessWidget {
  /// Creates the card.
  const new({
    required this.label,
    required this.segments,
    this.trailing,
    this.trailingTone,
    this.stageLabels = const [],
    this.legend = const [],
    this.barHeight = 6,
    this.semanticsLabel,
    super.key,
  });

  /// "Install progress".
  final String label;

  /// At the top right: "Arka Solar EPC", "16 total".
  final String? trailing;

  /// Shows [trailing] as a pill in this tone instead of plain text.
  final SolaTone? trailingTone;

  /// The bar.
  final List<SolaSegment> segments;

  /// Names spread under the bar: Survey, Install, Handover.
  final List<String> stageLabels;

  /// Or a legend of dots.
  final List<SolaLegendItem> legend;

  /// Bar height.
  final double barHeight;

  /// What a screen reader says about the bar.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    return SolaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: SolaSpace.space12,
        children: [
          Row(
            children: [
              Expanded(
                child: SolaText(
                  label,
                  style: SolaTextStyle.eyebrow,
                  color: SolaColors.muted,
                ),
              ),
              if (trailing != null)
                if (trailingTone case final tone?)
                  SolaPill(trailing, tone: tone)
                else
                  SolaText(
                    trailing,
                    style: SolaTextStyle.meta,
                    color: SolaColors.muted,
                  ),
            ],
          ),
          SolaSegmentBar(
            segments: segments,
            height: barHeight,
            semanticsLabel: semanticsLabel,
          ),
          if (stageLabels.isNotEmpty)
            ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final s in stageLabels)
                    SolaText(
                      s,
                      style: SolaTextStyle.caption,
                      color: SolaColors.muted,
                    ),
                ],
              ),
            ),
          if (legend.isNotEmpty)
            Wrap(
              spacing: SolaSpace.space14,
              children: [
                for (final item in legend)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: SolaSpace.space6,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: item.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SolaText(
                        item.label,
                        style: SolaTextStyle.caption,
                        color: SolaColors.muted,
                      ),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// One line of [SolaStepsCard].
@immutable
class SolaStep {
  /// Creates a step.
  const new(this.title, this.subtitle);

  /// What happens.
  final String title;

  /// More about it.
  final String subtitle;
}

/// "What happens next": numbered rows in a card, the first number in sun.
class SolaStepsCard extends StatelessWidget {
  /// Creates the card.
  const new({required this.steps, super.key});

  /// The steps, in order.
  final List<SolaStep> steps;

  @override
  Widget build(BuildContext context) {
    return SolaGroup(
      children: [
        for (final (i, step) in steps.indexed)
          SolaListRow(
            title: step.title,
            subtitle: step.subtitle,
            leading: SolaAvatar(
              initials: '${i + 1}',
              size: 36,
              color: i == 0 ? SolaColors.sun : SolaColors.tan,
            ),
          ),
      ],
    );
  }
}

/// The top of a success screen: the green tick, a title, a line, and an
/// optional pill with the reference.
class SolaSuccessHeader extends StatelessWidget {
  /// Creates the header.
  const new({required this.title, required this.body, this.pill, super.key});

  /// "Request sent".
  final String title;

  /// What happens now.
  final String body;

  /// A reference pill: "REQ SC-1042 · In review".
  final Widget? pill;

  @override
  Widget build(BuildContext context) {
    final pill = this.pill;
    return Column(
      spacing: SolaSpace.space10,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: SolaColors.success,
            shape: BoxShape.circle,
            boxShadow: SolaShadows.success,
          ),
          child: const Center(
            child: SolaIcon(
              SolaIcons.check,
              size: 32,
              strokeWidth: 2.4,
              color: SolaColors.surface,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: SolaSpace.space8),
          child: SolaText(
            title,
            style: SolaTextStyle.title,
            textAlign: TextAlign.center,
          ),
        ),
        SolaText(body, color: SolaColors.muted, textAlign: TextAlign.center),
        ?pill,
      ],
    );
  }
}

/// A day of [SolaWeekStrip].
@immutable
class SolaDay {
  /// Creates a day.
  const new({
    required this.name,
    required this.date,
    this.dots = const [],
    this.today = false,
  });

  /// "Mon".
  final String name;

  /// "20".
  final String date;

  /// One dot per task, coloured by its state.
  final List<Color> dots;

  /// Highlights the day.
  final bool today;
}

/// The worker's week: seven days with a dot per task, today in dark.
class SolaWeekStrip extends StatelessWidget {
  /// Creates the strip.
  const new({required this.days, super.key});

  /// The days, Monday first.
  final List<SolaDay> days;

  @override
  Widget build(BuildContext context) {
    return SolaCard(
      padding: const EdgeInsets.all(SolaSpace.space6),
      child: Row(
        spacing: SolaSpace.space4,
        children: [
          for (final day in days)
            Expanded(
              child: Semantics(
                label: '${day.name} ${day.date}, ${day.dots.length} tasks',
                selected: day.today,
                excludeSemantics: true,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
                  decoration: BoxDecoration(
                    color: day.today ? SolaColors.ink : null,
                    borderRadius: BorderRadius.circular(SolaRadius.radius16),
                  ),
                  child: Column(
                    spacing: SolaSpace.space6,
                    children: [
                      SolaText(
                        day.name,
                        style: SolaTextStyle.day,
                        color: day.today
                            ? SolaColors.onBrownMuted
                            : SolaColors.muted,
                      ),
                      SolaText(
                        day.date,
                        style: SolaTextStyle.navTitle,
                        color: day.today ? SolaColors.surface : SolaColors.ink,
                      ),
                      SizedBox(
                        height: 5,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 3,
                          children: [
                            for (final c in day.dots)
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The customer's live energy card: the sun's arc through the day, energy
/// today, and the hours as bars.
class SolaEnergyCard extends StatelessWidget {
  /// Creates the card.
  const new({
    required this.label,
    required this.liveLabel,
    required this.value,
    required this.unit,
    required this.sunrise,
    required this.sunset,
    required this.dayProgress,
    required this.hours,
    required this.nowIndex,
    super.key,
  });

  /// "Generating now".
  final String label;

  /// The live pill: "3.8 kW".
  final String liveLabel;

  /// "18.4".
  final String value;

  /// "kWh today".
  final String unit;

  /// "6:12".
  final String sunrise;

  /// "Sunset 17:41".
  final String sunset;

  /// How far through daylight it is, 0 to 1: where the sun sits.
  final double dayProgress;

  /// Generation per hour, any scale; bars after [nowIndex] are empty.
  final List<double> hours;

  /// The current hour's index in [hours].
  final int nowIndex;

  @override
  Widget build(BuildContext context) {
    final peak = hours.fold<double>(0, math.max);
    return Semantics(
      container: true,
      label: '$label $liveLabel. $value $unit.',
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SolaRadius.radius28),
          gradient: const RadialGradient(
            center: Alignment(0.2, -1),
            radius: 1.2,
            colors: [
              SolaColors.energyTop,
              SolaColors.brown,
              SolaColors.energyBottom,
            ],
            stops: [0, 0.55, 1],
          ),
        ),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SolaText(
                      label,
                      style: SolaTextStyle.eyebrow,
                      color: SolaColors.onBrownMuted,
                    ),
                  ),
                  SolaPill(
                    liveLabel,
                    tone: SolaTone.live,
                    icon: SolaIcons.bolt,
                  ),
                ],
              ),
              SizedBox(
                height: 120,
                child: CustomPaint(painter: _ArcPainter(dayProgress)),
              ),
              Transform.translate(
                offset: const Offset(0, -6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SolaText(
                      sunrise,
                      style: SolaTextStyle.caption,
                      color: SolaColors.energyMuted,
                    ),
                    SolaText(
                      sunset,
                      style: SolaTextStyle.caption,
                      color: SolaColors.energyMuted,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: SolaSpace.space6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: SolaSpace.space10,
                children: [
                  SolaText(
                    value,
                    style: SolaTextStyle.energy,
                    color: SolaColors.surface,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: SolaText(
                      unit,
                      style: SolaTextStyle.button,
                      fontWeight: FontWeight.w400,
                      color: SolaColors.energyText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SolaSpace.space8),
              SizedBox(
                height: 64,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: SolaSpace.space4,
                  children: [
                    for (final (i, h) in hours.indexed)
                      Expanded(
                        child: Container(
                          height: peak == 0 ? 4 : math.max(4, 64 * h / peak),
                          decoration: BoxDecoration(
                            color: i <= nowIndex
                                ? SolaColors.sun
                                : const Color(0x1FFFFFFF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const new(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // The design's arc: centre (155, 128), radius 118, in a 310x120 box.
    final scale = size.width / 310;
    canvas
      ..save()
      ..translate((size.width - 310 * scale) / 2, 0)
      ..scale(scale, size.height / 120);
    final rect = Rect.fromCircle(center: const Offset(155, 128), radius: 118);
    const start = math.pi + 0.0605; // matches the design's 37,128 start
    const sweep = math.pi - 0.121;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0x2EFFFFFF);
    final metric = (Path()..addArc(rect, start, sweep)).computeMetrics().first;
    for (var d = 0.0; d < metric.length; d += 8) {
      canvas.drawPath(metric.extractPath(d, d + 3), track);
    }
    final p = progress.clamp(0.0, 1.0);
    canvas.drawArc(
      rect,
      start,
      sweep * p,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = SolaColors.sun,
    );
    final angle = start + sweep * p;
    final sun = Offset(
      155 + 118 * math.cos(angle),
      128 + 118 * math.sin(angle),
    );
    canvas
      ..drawCircle(
        sun,
        26,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xE6F6C445), Color(0x00F6C445)],
          ).createShader(Rect.fromCircle(center: sun, radius: 26)),
      )
      ..drawCircle(sun, 9, Paint()..color = SolaColors.sun)
      ..restore();
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}

/// A message on a screen: what happened and, optionally, one action.
class SolaNotice extends StatelessWidget {
  /// Creates the notice.
  const new({
    required this.title,
    this.body,
    this.tone = SolaTone.danger,
    this.action,
    this.announce = false,
    super.key,
  });

  /// What happened.
  final String title;

  /// What to do.
  final String? body;

  /// Its meaning.
  final SolaTone tone;

  /// One action under the text.
  final Widget? action;

  /// Read out by screen readers as soon as it appears (errors).
  final bool announce;

  @override
  Widget build(BuildContext context) {
    final body = this.body;
    final action = this.action;
    return Semantics(
      container: true,
      liveRegion: announce,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SolaSpace.space16,
          vertical: SolaSpace.space12,
        ),
        decoration: BoxDecoration(
          color: tone.background,
          borderRadius: BorderRadius.circular(SolaRadius.radius16),
        ),
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
            if (action != null) ...[
              const SizedBox(height: SolaSpace.space8),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
