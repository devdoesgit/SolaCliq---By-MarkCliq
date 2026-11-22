import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/customers/cubit/site_location_cubit.dart';
import 'package:solacliq/l10n/l10n.dart';

/// Tap to save where the site is. It says what's read and why, as Google
/// Play asks before a location prompt.
class SiteLocationField extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.watch<SiteLocationCubit>();
    final SiteLocationState(:point, :locating, :problem) = cubit.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: SolaSpace.space6,
      children: [
        SolaGroup(
          children: [
            SolaValueRow(
              key: const Key('customer_location'),
              label: l10n.siteLocation,
              value: locating ? null : point?.label,
              placeholder: locating
                  ? l10n.findingLocation
                  : l10n.siteLocationTap,
              error: switch (problem) {
                null => null,
                SiteLocationProblem.off => l10n.siteLocationOff,
                SiteLocationProblem.denied => l10n.siteLocationDenied,
                SiteLocationProblem.notFound => l10n.siteLocationNotFound,
              },
              onTap: () => unawaited(cubit.locate()),
            ),
          ],
        ),
        // Above the note, so it isn't under the bottom button.
        if (problem == SiteLocationProblem.off ||
            problem == SiteLocationProblem.denied)
          SolaTextLink(
            l10n.openSettings,
            key: const Key('customer_location_settings'),
            onPressed: () => unawaited(cubit.openSettings()),
          ),
        SolaText(
          l10n.siteLocationWhy,
          style: SolaTextStyle.small,
          color: SolaColors.muted,
        ),
      ],
    );
  }
}
