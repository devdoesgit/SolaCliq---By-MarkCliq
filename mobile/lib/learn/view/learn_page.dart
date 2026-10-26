import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/app/widgets/back_to.dart';
import 'package:solacliq/l10n/l10n.dart';

/// Short guides for people thinking of going solar: how it works, the
/// subsidy, the size and how long it takes.
class LearnPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final guides = [
      (SolaIcons.sun, l10n.learn1Title, l10n.learn1Body),
      (SolaIcons.shield, l10n.learn2Title, l10n.learn2Body),
      (SolaIcons.home, l10n.learn3Title, l10n.learn3Body),
      (SolaIcons.alarm, l10n.learn4Title, l10n.learn4Body),
    ];
    return SolaScreen(
      navBar: SolaNavBar(
        leading: const BackTo(fallback: AppRoutes.home),
        title: l10n.learnTitle,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: SolaSpace.space12,
        children: [
          for (final (icon, title, body) in guides)
            SolaCard(
              child: MergeSemantics(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: SolaSpace.space12,
                  children: [
                    SolaAvatar(icon: icon, color: SolaColors.butter),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: SolaSpace.space4,
                        children: [
                          SolaText(title, style: SolaTextStyle.rowTitle),
                          SolaText(
                            body,
                            style: SolaTextStyle.small,
                            color: SolaColors.muted,
                          ),
                        ],
                      ),
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
