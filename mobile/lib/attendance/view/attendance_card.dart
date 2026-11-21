import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/attendance/cubit/attendance_cubit.dart';
import 'package:solacliq/attendance/data/attendance_repository.dart';
import 'package:solacliq/auth/view/auth_text.dart';
import 'package:solacliq/l10n/l10n.dart';

/*
  The home's attendance card (F17): Start day, Working since 9:12 with
  End day, or the day's span once ended. Shown only when the home has an
  attendance part (installers and salaried sales)
  ----------------------------------------------------------------------
  - the cubit lives with the card; taps still saved on the phone are
    sent when the card opens, every 30 seconds while they wait, and when
    the app comes back to the front
*/
class AttendanceCard extends StatelessWidget {
  const new({
    required this.userId,
    required this.orgId,
    required this.server,
    this.onSent,
    super.key,
  });

  final String userId;
  final String orgId;

  /// Today's attendance as the home loaded it.
  final HomeAttendance server;

  /// A tap reached the server: reload the home.
  final VoidCallback? onSent;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AttendanceCubit(
        context.read<AttendanceRepository>(),
        userId: userId,
        orgId: orgId,
        onSent: onSent,
      ),
      child: AttendanceCardView(server: server),
    );
  }
}

class AttendanceCardView extends StatefulWidget {
  const new({required this.server, super.key});

  final HomeAttendance server;

  @override
  State<AttendanceCardView> createState() => _AttendanceCardViewState();
}

class _AttendanceCardViewState extends State<AttendanceCardView> {
  late final AppLifecycleListener _lifecycle;

  AttendanceCubit get _cubit => context.read<AttendanceCubit>();

  @override
  void initState() {
    super.initState();
    unawaited(_cubit.seed(widget.server));
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(_cubit.send()));
  }

  @override
  void didUpdateWidget(AttendanceCardView old) {
    super.didUpdateWidget(old);
    // The home reloaded: the server's word comes first.
    if (old.server != widget.server) unawaited(_cubit.seed(widget.server));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _confirmEnd() async {
    final l10n = context.l10n;
    final end = await showSolaSheet<bool>(
      context: context,
      title: l10n.attendanceEndTitle,
      doneLabel: l10n.attendanceKeepWorking,
      builder: (sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: SolaSpace.space14,
        children: [
          SolaText(l10n.attendanceEndBody, color: SolaColors.muted),
          SolaButton(
            key: const Key('attendance_end_confirm'),
            label: l10n.attendanceEnd,
            variant: SolaButtonVariant.dark,
            onPressed: () => Navigator.of(sheet).pop(true),
          ),
        ],
      ),
    );
    if ((end ?? false) && mounted) await _cubit.end();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<AttendanceCubit>().state;
    final locale = Localizations.localeOf(context).toString();
    String clock(DateTime at) => DateFormat.jm(locale).format(at.toLocal());

    final (title, detail) = switch (state) {
      AttendanceCardState(state: AttendanceState.notStarted) => (
        l10n.attendanceNotStarted,
        l10n.attendanceNotStartedHint,
      ),
      AttendanceCardState(state: AttendanceState.working, :final startAt?) => (
        l10n.attendanceWorkingSince(clock(startAt)),
        null,
      ),
      AttendanceCardState(:final startAt?, :final endAt?) => (
        l10n.attendanceEnded,
        _span(l10n, clock(startAt), clock(endAt), endAt.difference(startAt)),
      ),
      // Not reached: working and ended always carry their times.
      _ => (l10n.attendanceNotStarted, null),
    };
    final button = switch (state.state) {
      AttendanceState.notStarted => SolaButton(
        key: const Key('attendance_start'),
        label: l10n.attendanceStart,
        compact: true,
        expand: false,
        onPressed: () => unawaited(_cubit.start()),
      ),
      AttendanceState.working => SolaButton(
        key: const Key('attendance_end'),
        label: l10n.attendanceEnd,
        variant: SolaButtonVariant.dark,
        compact: true,
        expand: false,
        onPressed: () => unawaited(_confirmEnd()),
      ),
      AttendanceState.ended => null,
    };

    return SolaCard(
      key: const Key('attendance_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: SolaSpace.space6,
        children: [
          Row(
            spacing: SolaSpace.space12,
            children: [
              Expanded(
                child: Semantics(
                  container: true,
                  label: [l10n.attendanceTitle, title, ?detail].join('. '),
                  excludeSemantics: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: SolaSpace.space2,
                    children: [
                      SolaText(
                        l10n.attendanceTitle,
                        style: SolaTextStyle.eyebrow,
                        color: SolaColors.muted,
                      ),
                      SolaText(title, style: SolaTextStyle.rowTitle),
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
              ?button,
            ],
          ),
          if (state.waiting)
            SolaText(
              l10n.attendanceWaiting,
              key: const Key('attendance_waiting'),
              style: SolaTextStyle.small,
              color: SolaColors.warning,
            ),
          if (state.problem case final problem?)
            SolaText(
              problem.message(l10n),
              key: const Key('attendance_problem'),
              style: SolaTextStyle.small,
              color: SolaColors.danger,
            ),
        ],
      ),
    );
  }

  static String _span(
    AppLocalizations l10n,
    String start,
    String end,
    Duration worked,
  ) => l10n.attendanceSpan(
    start,
    end,
    worked.inHours,
    worked.inMinutes.remainder(60),
  );
}
