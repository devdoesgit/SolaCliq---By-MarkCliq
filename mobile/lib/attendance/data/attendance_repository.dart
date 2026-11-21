import 'dart:async';
import 'dart:convert';

import 'package:api_client/api_client.dart' as api;
import 'package:dio/dio.dart';
import 'package:solacliq/app/data/api_call.dart';
import 'package:solacliq/attendance/data/attendance_models.dart';
import 'package:solacliq/attendance/data/attendance_store.dart';
import 'package:solacliq/auth/data/auth_failure.dart';
import 'package:uuid/uuid.dart';

export 'attendance_models.dart';
export 'attendance_store.dart';

/// What sending the unsent taps came to.
class SendOutcome {
  const new({this.day, this.refused = const [], this.waiting = false});

  /// The day as the server last confirmed it, if a tap went through.
  final AttendanceDay? day;

  /// Taps the server refused for good (too old, not started...), and why.
  /// They're dropped: sending them again can't help.
  final List<(PendingTap, AuthFailureCode)> refused;

  /// Why the last refused tap was refused, to tell the person.
  AuthFailureCode? get dropped => refused.isEmpty ? null : refused.last.$2;

  /// Taps still waiting: the server couldn't be reached (or failed).
  final bool waiting;
}

/*
  Attendance taps (F17): kept on the phone until the server has them
  ----------------------------------------------------------------------
  - [tap] saves the tap first, then [send] posts every unsent one of
    that person and company, oldest first. A start always goes before
    its end
  - a tap that can't reach the server (no signal, a server error, a
    login being refreshed) stays and the sending stops there, so the
    order holds; the next [send] tries again with the same key
  - a tap the server refuses for good is dropped and reported once;
    "already started" or "already ended" means the server has it
  - two locks: saving a tap never waits for a slow network, and two
    sends never run at once
*/
class AttendanceRepository {
  new(this._api, this._store, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final api.AttendanceApi _api;
  final AttendanceStore _store;
  final DateTime Function() _clock;

  Future<void> _storage = Future.value();
  Future<void> _sending = Future.value();

  /// Runs [work] after the work already chained on [lock].
  static Future<T> _after<T>(
    Future<void> lock,
    void Function(Future<void>) setLock,
    Future<T> Function() work,
  ) {
    final run = lock.then((_) => work());
    setLock(run.then<void>((_) {}, onError: (Object _) {}));
    return run;
  }

  Future<T> _stored<T>(Future<T> Function() work) =>
      _after(_storage, (l) => _storage = l, work);

  /// The person's unsent taps in this company, oldest first.
  Future<List<PendingTap>> pending(String userId, String orgId) => _stored(
    () async => [
      for (final t in await _read())
        if (t.belongsTo(userId, orgId)) t,
    ],
  );

  /*
    Saves a tap made now. A second tap of the same kind on the same
    India date, still unsent, is the same tap: it's returned, not added
  */
  Future<PendingTap> tap(String userId, String orgId, TapKind kind) =>
      _stored(() async {
        final now = _clock().toUtc();
        final all = await _read();
        for (final t in all) {
          if (t.belongsTo(userId, orgId) &&
              t.kind == kind &&
              indiaDate(t.phoneAt) == indiaDate(now)) {
            return t;
          }
        }
        final tap = PendingTap(
          userId: userId,
          orgId: orgId,
          kind: kind,
          phoneAt: now,
          key: const Uuid().v4(),
        );
        await _write([...all, tap]);
        return tap;
      });

  /// Sends the person's unsent taps in this company, oldest first.
  Future<SendOutcome> send(String userId, String orgId) =>
      _after(_sending, (l) => _sending = l, () async {
        AttendanceDay? day;
        final refused = <(PendingTap, AuthFailureCode)>[];
        while (true) {
          final queue = await pending(userId, orgId);
          if (queue.isEmpty) break;
          final next = queue.first;
          try {
            day = await _post(next);
          } on AuthFailure catch (failure) {
            if (_retryable(failure)) {
              return SendOutcome(day: day, refused: refused, waiting: true);
            }
            if (!_serverHasIt(next.kind, failure.code)) {
              refused.add((next, failure.code));
            }
          }
          await _remove(next);
        }
        return SendOutcome(day: day, refused: refused);
      });

  Future<AttendanceDay> _post(PendingTap tap) async {
    final body = api.AttendanceTapCreate(
      phoneAt: tap.phoneAt,
      // Read on each try: the gap to [phoneAt] is how long it waited.
      sentAt: _clock().toUtc(),
    );
    final response = await apiCall(
      () => switch (tap.kind) {
        TapKind.start => _api.startAttendanceDay(
          idempotencyKey: tap.key,
          orgId: tap.orgId,
          attendanceTapCreate: body,
        ),
        TapKind.end => _api.endAttendanceDay(
          idempotencyKey: tap.key,
          orgId: tap.orgId,
          attendanceTapCreate: body,
        ),
      },
    );
    return attendanceDay(response.data!);
  }

  /*
    Worth trying again later: no answer at all, a server error, a login
    that needs renewing, or "slow down". Anything else is the server's
    final word on this tap
  */
  static bool _retryable(AuthFailure failure) {
    if (failure.code == AuthFailureCode.network ||
        failure.code == AuthFailureCode.sessionExpired) {
      return true;
    }
    final cause = failure.cause;
    final status = cause is DioException ? cause.response?.statusCode : null;
    return status == null ||
        status == 401 ||
        status == 408 ||
        status == 429 ||
        status >= 500;
  }

  // The server already has this tap's effect, from this phone or another.
  static bool _serverHasIt(TapKind kind, AuthFailureCode code) =>
      switch (kind) {
        TapKind.start => code == AuthFailureCode.attendanceAlreadyStarted,
        TapKind.end => code == AuthFailureCode.attendanceAlreadyEnded,
      };

  Future<void> _remove(PendingTap tap) => _stored(() async {
    await _write([
      for (final t in await _read())
        if (t != tap) t,
    ]);
  });

  Future<List<PendingTap>> _read() async {
    final raw = await _store.read();
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return [];
      return [for (final e in list) ?PendingTap.fromJson(e)];
    } on FormatException {
      return [];
    }
  }

  Future<void> _write(List<PendingTap> taps) =>
      _store.write(jsonEncode([for (final t in taps) t.toJson()]));
}

/// The app's [AttendanceDay] from the API's.
AttendanceDay attendanceDay(api.AttendanceDay d) {
  final end = d.end;
  return AttendanceDay(
    date: d.date,
    status: switch (d.status) {
      api.AttendanceStatus.working => AttendanceStatus.working,
      api.AttendanceStatus.ended => AttendanceStatus.ended,
      api.AttendanceStatus.noCheckOut => AttendanceStatus.noCheckOut,
    },
    start: AttendanceTap(at: d.start.at.toUtc(), sentLate: d.start.sentLate),
    end: end == null
        ? null
        : AttendanceTap(at: end.at.toUtc(), sentLate: end.sentLate),
    minutes: d.minutes,
  );
}

/// The home's attendance part from the API's.
HomeAttendance homeAttendance(api.HomeAttendance a) {
  final day = a.day;
  return HomeAttendance(
    state: switch (a.state) {
      api.HomeAttendanceStateEnum.notStarted => AttendanceState.notStarted,
      api.HomeAttendanceStateEnum.working => AttendanceState.working,
      api.HomeAttendanceStateEnum.ended => AttendanceState.ended,
    },
    day: day == null ? null : attendanceDay(day),
  );
}
