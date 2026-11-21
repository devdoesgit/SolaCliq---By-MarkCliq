import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:solacliq/attendance/data/attendance_repository.dart';
import 'package:solacliq/auth/data/auth_failure.dart';

/// What the home's attendance card shows.
class AttendanceCardState extends Equatable {
  const new({
    this.state = AttendanceState.notStarted,
    this.startAt,
    this.endAt,
    this.waiting = false,
    this.problem,
  });

  final AttendanceState state;

  /// Today's start and end, UTC: the server's, or the phone's while a tap
  /// waits to be sent.
  final DateTime? startAt;
  final DateTime? endAt;

  /// A tap is saved on the phone, not sent yet.
  final bool waiting;

  /// Why the server refused a tap for good, to show once.
  final AuthFailureCode? problem;

  @override
  List<Object?> get props => [state, startAt, endAt, waiting, problem];
}

/*
  The attendance card of one person in one company (F17)
  ----------------------------------------------------------------------
  - today's start and end come from, first to last: the server's home,
    the server's answer to a tap, a tap still saved on the phone, a tap
    made here that went through (the development mock keeps no state)
  - "today" is India's date, as the server counts days
  - a tap shows at once, is saved, then sent; one that can't reach the
    server is tried again every 30 seconds while the card is open, and
    when the app comes back to the front ([send])
*/
class AttendanceCubit extends Cubit<AttendanceCardState> {
  new(
    this._repository, {
    required this.userId,
    required this.orgId,
    this.onSent,
    DateTime Function()? clock,
    this.retryEvery = const Duration(seconds: 30),
  }) : _clock = clock ?? DateTime.now,
       super(const AttendanceCardState());

  final AttendanceRepository _repository;
  final String userId;
  final String orgId;

  /// A tap reached the server: the home may change (reload it).
  final void Function()? onSent;
  final DateTime Function() _clock;
  final Duration retryEvery;

  HomeAttendance? _server;
  AttendanceDay? _answer;
  List<PendingTap> _pending = const [];
  final Map<TapKind, DateTime> _made = {};
  AuthFailureCode? _problem;
  bool _tapping = false;
  Timer? _retry;

  /// The server's card, from a home load; then any taps still to send.
  Future<void> seed(HomeAttendance server) async {
    _server = server;
    _emit();
    await send();
  }

  Future<void> start() => _tap(TapKind.start);

  Future<void> end() => _tap(TapKind.end);

  Future<void> _tap(TapKind kind) async {
    // One tap at a time, and only the one the card offers.
    final offered = switch (kind) {
      TapKind.start => state.state == AttendanceState.notStarted,
      TapKind.end => state.state == AttendanceState.working,
    };
    if (_tapping || !offered || isClosed) return;
    _tapping = true;
    try {
      _problem = null;
      /*
        Shown at once: saving to the phone's secure storage can take a
        second or two. The saved tap's own time replaces this one
      */
      _made[kind] = _clock().toUtc();
      _emit();
      final tap = await _repository.tap(userId, orgId, kind);
      _made[kind] = tap.phoneAt;
      _pending = await _repository.pending(userId, orgId);
      _emit();
    } finally {
      _tapping = false;
    }
    await send();
  }

  /// Sends any taps still saved on the phone.
  Future<void> send() async {
    if (isClosed) return;
    _retry?.cancel();
    final before = _pending.length;
    final outcome = await _repository.send(userId, orgId);
    if (isClosed) return;
    _pending = await _repository.pending(userId, orgId);
    if (outcome.day case final day?) _answer = day;
    if (outcome.dropped case final code?) _problem = code;
    for (final (tap, _) in outcome.refused) {
      if (_made[tap.kind] == tap.phoneAt) _made.remove(tap.kind);
    }
    _emit();
    if (outcome.waiting) _retry = Timer(retryEvery, () => unawaited(send()));
    if (_pending.length < before || outcome.day != null) onSent?.call();
  }

  void _emit() {
    if (isClosed) return;
    final today = indiaDate(_clock());
    final server = _server?.day;
    final serverDay = server != null && server.date == today ? server : null;
    final answer = _answer?.date == today ? _answer : null;
    DateTime? waiting(TapKind kind) {
      for (final t in _pending) {
        if (t.kind == kind && indiaDate(t.phoneAt) == today) return t.phoneAt;
      }
      return null;
    }

    DateTime? made(TapKind kind) {
      final at = _made[kind];
      return at != null && indiaDate(at) == today ? at : null;
    }

    final startAt =
        serverDay?.start.at ??
        answer?.start.at ??
        waiting(TapKind.start) ??
        made(TapKind.start);
    final endAt = startAt == null
        ? null
        : serverDay?.end?.at ??
              answer?.end?.at ??
              waiting(TapKind.end) ??
              made(TapKind.end);
    emit(
      AttendanceCardState(
        state: endAt != null
            ? AttendanceState.ended
            : startAt != null
            ? AttendanceState.working
            : AttendanceState.notStarted,
        startAt: startAt,
        endAt: endAt,
        waiting: _pending.isNotEmpty,
        problem: _problem,
      ),
    );
  }

  @override
  Future<void> close() {
    _retry?.cancel();
    return super.close();
  }
}
