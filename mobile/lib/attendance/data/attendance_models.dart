import 'package:equatable/equatable.dart';

/// Start day or End day.
enum TapKind { start, end }

/// What the home's attendance card shows (F17).
enum AttendanceState { notStarted, working, ended }

/// A day's status as the server tells it.
enum AttendanceStatus { working, ended, noCheckOut }

/// One tap as the server recorded it.
class AttendanceTap extends Equatable {
  const new({required this.at, this.sentLate = false});

  /// When it counts as made, by the server's clock (UTC).
  final DateTime at;

  /// It waited on the phone over 5 minutes (sent from offline).
  final bool sentLate;

  @override
  List<Object> get props => [at, sentLate];
}

/// One working day: its India date, start and, once ended, its end.
class AttendanceDay extends Equatable {
  const new({
    required this.date,
    required this.status,
    required this.start,
    this.end,
    this.minutes,
  });

  /// `YYYY-MM-DD`, the India date the day started.
  final String date;
  final AttendanceStatus status;
  final AttendanceTap start;
  final AttendanceTap? end;

  /// Worked time, once ended.
  final int? minutes;

  @override
  List<Object?> get props => [date, status, start, end, minutes];
}

/// The home's attendance part: today's day in India, if started.
class HomeAttendance extends Equatable {
  const new({required this.state, this.day});

  final AttendanceState state;
  final AttendanceDay? day;

  @override
  List<Object?> get props => [state, day];
}

/*
  A tap the phone hasn't got to the server yet
  ----------------------------------------------------------------------
  - made with no signal, or whose request failed on the way. Kept on the
    phone and sent, in order, when the server can be reached
  - [phoneAt] is fixed at the tap; the time of sending is read on each
    try. The server takes their gap, so a wrong phone clock moves
    nothing (`docs/features/F17-attendance.md`)
  - [key] is fixed at the tap too: every retry is the same request, so
    the server never records it twice
  - [userId] and [orgId]: a tap is only ever sent for the person who made
    it, in the company they made it in, even if someone else logs in on
    this phone in between
*/
class PendingTap extends Equatable {
  const new({
    required this.userId,
    required this.orgId,
    required this.kind,
    required this.phoneAt,
    required this.key,
  });

  /// Reads one written by [toJson]; null for anything else (an old or
  /// damaged entry is dropped, never guessed at).
  static PendingTap? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final userId = json['user_id'];
    final orgId = json['org_id'];
    final kind = json['kind'];
    final phoneAt = json['phone_at'];
    final key = json['key'];
    if (userId is! String ||
        orgId is! String ||
        kind is! String ||
        phoneAt is! String ||
        key is! String) {
      return null;
    }
    final tapKind = TapKind.values.asNameMap()[kind];
    final at = DateTime.tryParse(phoneAt);
    if (tapKind == null || at == null) return null;
    return PendingTap(
      userId: userId,
      orgId: orgId,
      kind: tapKind,
      phoneAt: at.toUtc(),
      key: key,
    );
  }

  final String userId;
  final String orgId;
  final TapKind kind;

  /// The phone's clock at the tap, UTC.
  final DateTime phoneAt;

  /// The `Idempotency-Key`, the same on every try.
  final String key;

  bool belongsTo(String user, String org) => userId == user && orgId == org;

  Map<String, Object> toJson() => {
    'user_id': userId,
    'org_id': orgId,
    'kind': kind.name,
    'phone_at': phoneAt.toUtc().toIso8601String(),
    'key': key,
  };

  @override
  List<Object> get props => [userId, orgId, kind, phoneAt, key];
}

/// India's date at [moment], as the server counts days (UTC+5:30, no
/// daylight saving), whatever the phone's own time zone.
String indiaDate(DateTime moment) {
  final india = moment.toUtc().add(const Duration(hours: 5, minutes: 30));
  final m = india.month.toString().padLeft(2, '0');
  final d = india.day.toString().padLeft(2, '0');
  return '${india.year}-$m-$d';
}
