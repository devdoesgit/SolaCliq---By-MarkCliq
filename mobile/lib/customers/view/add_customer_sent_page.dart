import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/app/widgets/back_to.dart';
import 'package:solacliq/l10n/l10n.dart';

/// What [AddCustomerSentPage] shows, passed by the flow.
class AddCustomerSentArgs {
  const new({
    required this.firstName,
    required this.documents,
    required this.reference,
    this.commissionPaise,
  });

  final String firstName;
  final int documents;

  /// "SC-1042".
  final String reference;

  /// A commission agent's commission, reviewed with the documents.
  final int? commissionPaise;
}

/// The new customer is with the admin: the reference and what happens next.
class AddCustomerSentPage extends StatelessWidget {
  const new({required this.args, super.key});

  final AddCustomerSentArgs args;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SolaScreen(
      background: SolaBackground.stone,
      navBar: const SolaNavBar(
        trailing: BackTo(fallback: AppRoutes.home, close: true),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: SolaSpace.space10),
          SolaSuccessHeader(
            title: l10n.sentToAdmin,
            body: l10n.custSentBody(args.firstName, '${args.documents}'),
            pill: SolaPill(
              l10n.reqInReview(args.reference),
              icon: SolaIcons.hourglass,
            ),
          ),
          const SizedBox(height: SolaSpace.space22),
          SolaStepsCard(
            steps: [
              SolaStep(l10n.custStep1, l10n.custStep1Sub),
              if (args.commissionPaise case final paise?) ...[
                SolaStep(
                  l10n.custStepCommission(formatRupees(paise)),
                  l10n.custStepCommissionSub,
                ),
                SolaStep(
                  l10n.custStepPaid,
                  l10n.custStepPaidSub(args.firstName),
                ),
              ] else ...[
                SolaStep(l10n.custStep2, l10n.custStep2Sub),
                SolaStep(l10n.custStep3(args.firstName), l10n.custStep3Sub),
              ],
            ],
          ),
        ],
      ),
      bottom: SolaBottomBar(
        children: [
          SolaButton(
            key: const Key('add_customer_another'),
            label: l10n.addAnother,
            onPressed: () => context.pushReplacement(AppRoutes.addCustomer),
          ),
          SolaButton(
            key: const Key('add_customer_home'),
            label: l10n.backToHome,
            variant: SolaButtonVariant.link,
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
    );
  }
}
