import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/health/cubit/health_cubit.dart';
import 'package:solacliq/health/data/health_repository.dart';
import 'package:solacliq/l10n/l10n.dart';

/// Shows whether the API and its database are up, with a retry when the
/// server can't be reached.
class HealthStatus extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = HealthCubit(context.read<HealthRepository>());
        unawaited(cubit.check());
        return cubit;
      },
      child: const HealthStatusView(),
    );
  }
}

class HealthStatusView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<HealthCubit>().state;
    return switch (state) {
      HealthChecking() => SolaText(
        l10n.healthChecking,
        style: SolaTextStyle.meta,
        color: SolaColors.muted,
      ),
      HealthLoaded(:final report) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: SolaSpace.space4,
        children: [
          SolaPill(
            report.databaseOk ? l10n.healthOk : l10n.healthDegraded,
            tone: report.databaseOk ? SolaTone.success : SolaTone.warning,
          ),
          SolaText(
            l10n.healthVersion(report.version),
            style: SolaTextStyle.meta,
            color: SolaColors.muted,
          ),
        ],
      ),
      HealthUnreachable() => SolaNotice(
        title: l10n.healthUnreachableTitle,
        body: l10n.healthUnreachableBody,
        announce: true,
        action: SolaButton(
          key: const Key('health_retry'),
          label: l10n.retry,
          variant: SolaButtonVariant.white,
          compact: true,
          expand: false,
          onPressed: () => context.read<HealthCubit>().check(),
        ),
      ),
    };
  }
}
