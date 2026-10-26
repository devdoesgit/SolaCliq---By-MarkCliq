import 'package:api_client/api_client.dart' as api;
import 'package:equatable/equatable.dart';
import 'package:solacliq/app/data/api_call.dart';
import 'package:solacliq/auth/data/account.dart';

/// What a status, a bar segment or a day dot means.
enum HomeTone { success, warning, danger, neutral, live, empty }

/// A drawn picture for rows without a photo.
enum HomeGlyph { card, bill, passbook, rupee }

/// A tile's icon.
enum HomeIcon { camera, receipt, alarm, hourglass, shield, wallet, sun, users }

/// A day's dot on the worker's week.
enum HomeDot { done, live, planned }

/// A small picture: a photo reference, initials or a glyph.
class HomeVisual extends Equatable {
  const new({this.image, this.initials, this.glyph});

  /// A URL, or `asset:<name>` for a picture bundled in the app.
  final String? image;
  final String? initials;
  final HomeGlyph? glyph;

  @override
  List<Object?> get props => [image, initials, glyph];
}

class HomeHeadline extends Equatable {
  const new({required this.value, required this.label, this.detail});

  final String value;
  final String label;
  final String? detail;

  @override
  List<Object?> get props => [value, label, detail];
}

class HomeDay extends Equatable {
  const new({
    required this.day,
    required this.date,
    required this.dots,
    this.today = false,
  });

  final String day;
  final int date;
  final List<HomeDot> dots;
  final bool today;

  @override
  List<Object> get props => [day, date, dots, today];
}

/// A customer's live generation, after handover.
class HomeEnergy extends Equatable {
  const new({
    required this.nowKw,
    required this.todayKwh,
    required this.sunrise,
    required this.sunset,
    required this.dayProgress,
    required this.hours,
    required this.nowIndex,
  });

  final double nowKw;
  final double todayKwh;
  final String sunrise;
  final String sunset;
  final double dayProgress;
  final List<double> hours;
  final int nowIndex;

  @override
  List<Object> get props => [
    nowKw,
    todayKwh,
    sunrise,
    sunset,
    dayProgress,
    hours,
    nowIndex,
  ];
}

class HomeTile extends Equatable {
  const new({
    required this.label,
    required this.value,
    this.icon,
    this.footer,
    this.dark = false,
    this.avatars = const [],
    this.action,
  });

  final String label;
  final String value;
  final HomeIcon? icon;
  final String? footer;
  final bool dark;
  final List<HomeVisual> avatars;

  /// What tapping it opens, named by the server.
  final String? action;

  @override
  List<Object?> get props => [
    label,
    value,
    icon,
    footer,
    dark,
    avatars,
    action,
  ];
}

class HomeSegment extends Equatable {
  const new({required this.weight, required this.tone, this.label});

  final int weight;
  final HomeTone tone;
  final String? label;

  @override
  List<Object?> get props => [weight, tone, label];
}

/// A split bar: install stages, or KYC by status.
class HomeProgress extends Equatable {
  const new({
    required this.label,
    required this.segments,
    this.trailing,
    this.stages = const [],
    this.legend = false,
  });

  final String label;
  final String? trailing;
  final List<HomeSegment> segments;
  final List<String> stages;

  /// Shows the segments' labels under the bar.
  final bool legend;

  @override
  List<Object?> get props => [label, trailing, segments, stages, legend];
}

class HomeStatus extends Equatable {
  const new({required this.label, required this.tone});

  final String label;
  final HomeTone tone;

  @override
  List<Object> get props => [label, tone];
}

/// One row of a home's list: a task, a customer, a document.
class HomeRow extends Equatable {
  const new({
    required this.id,
    required this.visual,
    required this.title,
    required this.detail,
    this.status,
    this.action,
  });

  final String id;
  final HomeVisual visual;
  final String title;
  final String detail;
  final HomeStatus? status;

  /// What tapping it opens: `task`, `customer`, `documents`, `track`.
  final String? action;

  @override
  List<Object?> get props => [id, visual, title, detail, status, action];
}

/// What a company home shows, composed by the server for the role.
class HomeSummary extends Equatable {
  const new({
    required this.eyebrow,
    required this.title,
    required this.tiles,
    required this.rows,
    this.headline,
    this.week = const [],
    this.energy,
    this.progress,
    this.listTitle,
    this.unreadNotifications = 0,
  });

  final String eyebrow;
  final String title;
  final HomeHeadline? headline;
  final List<HomeDay> week;
  final HomeEnergy? energy;
  final List<HomeTile> tiles;
  final HomeProgress? progress;
  final String? listTitle;
  final List<HomeRow> rows;

  /// Shows a dot on the bell when above zero.
  final int unreadNotifications;

  @override
  List<Object?> get props => [
    eyebrow,
    title,
    headline,
    week,
    energy,
    tiles,
    progress,
    listTitle,
    rows,
    unreadNotifications,
  ];
}

/// Loads company homes.
class HomeRepository {
  new(this._api);

  final api.HomeApi _api;

  /// Request extra read by the development mock to pick the example for
  /// the role; a real server ignores it.
  static const mockExampleKey = 'solacliq.mock_example';

  Future<HomeSummary> orgHome(String orgId, OrgRole role) async {
    final response = await apiCall(
      () => _api.getOrgHome(orgId: orgId, extra: {mockExampleKey: role.name}),
    );
    return _summary(response.data!);
  }

  static HomeSummary _summary(api.HomeSummary s) {
    final headline = s.headline;
    final energy = s.energy;
    final progress = s.progress;
    return HomeSummary(
      eyebrow: s.eyebrow,
      title: s.title,
      headline: headline == null
          ? null
          : HomeHeadline(
              value: headline.value,
              label: headline.label,
              detail: headline.detail,
            ),
      week: [
        for (final d in s.week ?? const <api.HomeDay>[])
          HomeDay(
            day: d.day,
            date: d.date,
            today: d.today ?? false,
            dots: [for (final dot in d.dots) HomeDot.values.byName(dot.name)],
          ),
      ],
      energy: energy == null
          ? null
          : HomeEnergy(
              nowKw: energy.nowKw.toDouble(),
              todayKwh: energy.todayKwh.toDouble(),
              sunrise: energy.sunrise,
              sunset: energy.sunset,
              dayProgress: energy.dayProgress.toDouble(),
              hours: [for (final h in energy.hours) h.toDouble()],
              nowIndex: energy.nowIndex,
            ),
      tiles: [
        for (final t in s.tiles)
          HomeTile(
            label: t.label,
            value: t.value,
            icon: t.icon == null ? null : HomeIcon.values.byName(t.icon!.name),
            footer: t.footer,
            dark: t.dark ?? false,
            avatars: [
              for (final v in t.avatars ?? const <api.HomeVisual>[])
                HomeVisual(
                  image: v.image,
                  initials: v.initials,
                  glyph: v.glyph == null
                      ? null
                      : HomeGlyph.values.byName(v.glyph!.name),
                ),
            ],
            action: t.action,
          ),
      ],
      progress: progress == null
          ? null
          : HomeProgress(
              label: progress.label,
              trailing: progress.trailing,
              segments: [
                for (final g in progress.segments)
                  HomeSegment(
                    weight: g.weight,
                    tone: _tone(g.tone),
                    label: g.label,
                  ),
              ],
              stages: progress.stages ?? const [],
              legend: progress.legend ?? false,
            ),
      listTitle: s.list.title,
      unreadNotifications: s.unreadNotifications ?? 0,
      rows: [
        for (final r in s.list.rows)
          HomeRow(
            id: r.id,
            visual: HomeVisual(
              image: r.image,
              initials: r.initials,
              glyph: r.glyph == null
                  ? null
                  : HomeGlyph.values.byName(r.glyph!.name),
            ),
            title: r.title,
            detail: r.detail,
            action: r.action,
            status: r.status == null
                ? null
                : HomeStatus(
                    label: r.status!.label,
                    tone: _tone(r.status!.tone),
                  ),
          ),
      ],
    );
  }

  static HomeTone _tone(api.HomeTone tone) => switch (tone) {
    api.HomeTone.success => HomeTone.success,
    api.HomeTone.warning => HomeTone.warning,
    api.HomeTone.danger => HomeTone.danger,
    api.HomeTone.neutral => HomeTone.neutral,
    api.HomeTone.live => HomeTone.live,
    api.HomeTone.empty => HomeTone.empty,
  };
}
