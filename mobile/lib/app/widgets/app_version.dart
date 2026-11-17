import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/l10n/l10n.dart';

/// "v1.0.0 · [SolaCliq wordmark] by MarkCliq": the installed version, read
/// from the build (pubspec's `version`), so support can ask which one a
/// person has. Screen readers hear it as one line. Nothing while it's
/// read, or if it can't be.
class AppVersionFooter extends StatefulWidget {
  const new({super.key});

  @override
  State<AppVersionFooter> createState() => _AppVersionFooterState();
}

class _AppVersionFooterState extends State<AppVersionFooter> {
  // Read once per footer; the platform answers from memory after the first.
  late final Future<PackageInfo> _info = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _info,
    builder: (context, snapshot) {
      final version = snapshot.data?.version;
      if (version == null || version.isEmpty) return const SizedBox.shrink();
      final l10n = context.l10n;
      return Semantics(
        key: const Key('app_version'),
        label: l10n.appVersion(version, l10n.appName),
        excludeSemantics: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: SolaSpace.space4,
          children: [
            SolaText(
              l10n.appVersionNumber(version),
              style: SolaTextStyle.meta,
              color: SolaColors.muted,
            ),
            // The wordmark's ink runs from the sun dot to the q's tail, so
            // this height sets its letters at about the text's size.
            const SolaWordmark(height: 17),
            SolaText(
              l10n.appByMarkCliq,
              style: SolaTextStyle.meta,
              color: SolaColors.muted,
            ),
          ],
        ),
      );
    },
  );
}
