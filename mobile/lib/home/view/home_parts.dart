import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/home/data/home_repository.dart';
import 'package:solacliq/l10n/l10n.dart';

/// Maps a home's server-composed parts onto the design system.
extension HomeToneStyle on HomeTone {
  /// The pill tone for a status.
  SolaTone get pill => switch (this) {
    HomeTone.success => SolaTone.success,
    HomeTone.warning => SolaTone.warning,
    HomeTone.danger => SolaTone.danger,
    HomeTone.live => SolaTone.live,
    HomeTone.neutral || HomeTone.empty => SolaTone.neutral,
  };

  /// The colour of a bar segment or legend dot.
  Color get fill => switch (this) {
    HomeTone.success => SolaColors.successDot,
    HomeTone.warning => SolaColors.warning,
    HomeTone.danger => SolaColors.dangerDot,
    HomeTone.neutral => SolaColors.avatar,
    HomeTone.live => SolaColors.sun,
    HomeTone.empty => SolaColors.track,
  };
}

SolaIcons _icon(HomeIcon icon) => switch (icon) {
  HomeIcon.camera => SolaIcons.camera,
  HomeIcon.receipt => SolaIcons.receipt,
  HomeIcon.alarm => SolaIcons.alarm,
  HomeIcon.hourglass => SolaIcons.hourglass,
  HomeIcon.shield => SolaIcons.shield,
  HomeIcon.wallet => SolaIcons.wallet,
  HomeIcon.sun => SolaIcons.sun,
  HomeIcon.users => SolaIcons.users,
};

SolaGlyph? _glyph(HomeGlyph? glyph) => switch (glyph) {
  HomeGlyph.card => SolaGlyph.card,
  HomeGlyph.bill => SolaGlyph.bill,
  HomeGlyph.passbook => SolaGlyph.passbook,
  HomeGlyph.rupee => SolaGlyph.rupee,
  null => null,
};

/// A round avatar for a [HomeVisual]. Remote images are not shown yet: the
/// bundled `asset:` photos are, and anything else falls back to initials.
SolaAvatar homeAvatar(HomeVisual visual, {double size = 26}) => SolaAvatar(
  photo: SolaPhotos.fromReference(visual.image),
  glyph: _glyph(visual.glyph),
  initials: visual.initials,
  size: size,
);

/// The picture at the left of a list row: a photo or glyph in a rounded
/// square, or initials in a circle.
Widget homeThumb(HomeVisual visual) {
  final photo = SolaPhotos.fromReference(visual.image);
  final glyph = _glyph(visual.glyph);
  if (photo != null || glyph != null) {
    return SolaThumb(photo: photo, glyph: glyph);
  }
  return SolaAvatar(initials: visual.initials ?? '');
}

/// The big figure: "3 tasks · on site today".
class HomeHeadlineView extends StatelessWidget {
  const new({
    required this.headline,
    this.style = SolaTextStyle.numberXl,
    super.key,
  });

  final HomeHeadline headline;
  final SolaTextStyle style;

  @override
  Widget build(BuildContext context) => SolaHeadline(
    value: headline.value,
    label: headline.label,
    detail: headline.detail,
    style: style,
  );
}

/// The two tiles side by side.
class HomeTiles extends StatelessWidget {
  const new({required this.tiles, required this.onTap, super.key});

  final List<HomeTile> tiles;
  final ValueChanged<HomeTile> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: SolaSpace.space12,
      children: [
        for (final (i, tile) in tiles.indexed)
          Expanded(
            child: SolaStatTile(
              key: ValueKey('home_tile_$i'),
              label: tile.label,
              value: tile.value,
              icon: tile.icon == null ? null : _icon(tile.icon!),
              footer: tile.footer,
              dark: tile.dark,
              avatars: [for (final v in tile.avatars) homeAvatar(v)],
              onTap: () => onTap(tile),
            ),
          ),
      ],
    );
  }
}

/// A split bar card: install stages, or KYC by status with a legend.
class HomeProgressView extends StatelessWidget {
  const new({
    required this.progress,
    this.emptyColor = SolaColors.track,
    super.key,
  });

  final HomeProgress progress;

  /// The colour of segments still to come, tinted to the background.
  final Color emptyColor;

  Color _fill(HomeTone tone) => tone == HomeTone.empty ? emptyColor : tone.fill;

  @override
  Widget build(BuildContext context) {
    final segments = progress.segments;
    return SolaProgressCard(
      label: progress.label,
      trailing: progress.trailing,
      barHeight: progress.legend ? 8 : 6,
      segments: [
        for (final s in segments) SolaSegment(s.weight, _fill(s.tone)),
      ],
      stageLabels: progress.stages,
      legend: progress.legend
          ? [
              for (final s in segments)
                if (s.label case final label?)
                  SolaLegendItem(label, _fill(s.tone)),
            ]
          : const [],
      semanticsLabel: [
        progress.label,
        for (final s in segments) ?s.label,
      ].join(', '),
    );
  }
}

/// The worker's week, with a dot per task.
class HomeWeek extends StatelessWidget {
  const new({required this.days, super.key});

  final List<HomeDay> days;

  @override
  Widget build(BuildContext context) {
    return SolaWeekStrip(
      days: [
        for (final d in days)
          SolaDay(
            name: d.day,
            date: '${d.date}',
            today: d.today,
            dots: [
              for (final dot in d.dots)
                switch (dot) {
                  HomeDot.done => SolaColors.successDot,
                  HomeDot.live => SolaColors.sun,
                  HomeDot.planned => SolaColors.planned,
                },
            ],
          ),
      ],
    );
  }
}

/// A customer's live generation card, after handover.
class HomeEnergyView extends StatelessWidget {
  const new({required this.energy, super.key});

  final HomeEnergy energy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SolaEnergyCard(
      label: l10n.energyNow,
      liveLabel: l10n.energyKw(energy.nowKw.toStringAsFixed(1)),
      value: energy.todayKwh.toStringAsFixed(1),
      unit: l10n.energyToday,
      // "06:12" reads as "6:12".
      sunrise: energy.sunrise.replaceFirst(RegExp(r'^0(?=\d:)'), ''),
      sunset: l10n.energySunset(energy.sunset),
      dayProgress: energy.dayProgress,
      hours: energy.hours,
      nowIndex: energy.nowIndex,
    );
  }
}

/// The list at the bottom of a home: its heading, then the rows.
class HomeList extends StatelessWidget {
  const new({
    required this.rows,
    this.title,
    this.onSeeAll,
    this.onRow,
    super.key,
  });

  final String? title;
  final List<HomeRow> rows;
  final VoidCallback? onSeeAll;
  final ValueChanged<HomeRow>? onRow;

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    final onSeeAll = this.onSeeAll;
    final onRow = this.onRow;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SolaSpace.space12,
      children: [
        if (title != null)
          SolaSectionHeader(
            title,
            action: onSeeAll == null
                ? null
                : SolaTextLink(
                    context.l10n.seeAll,
                    key: const Key('home_see_all'),
                    style: SolaTextStyle.body,
                    color: SolaColors.muted,
                    onPressed: onSeeAll,
                  ),
          ),
        if (rows.isNotEmpty)
          SolaGroup(
            children: [
              for (final row in rows)
                SolaListRow(
                  key: ValueKey('home_row_${row.id}'),
                  title: row.title,
                  subtitle: row.detail,
                  leading: homeThumb(row.visual),
                  trailing: row.status == null
                      ? null
                      : SolaPill(
                          row.status!.label,
                          tone: row.status!.tone.pill,
                          icon: switch (row.status!.tone) {
                            HomeTone.success => SolaIcons.check,
                            HomeTone.danger => SolaIcons.alarm,
                            _ => null,
                          },
                        ),
                  onTap: onRow == null || row.action == null
                      ? null
                      : () => onRow(row),
                ),
            ],
          ),
      ],
    );
  }
}
