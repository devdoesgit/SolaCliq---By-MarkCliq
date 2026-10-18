import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/l10n/l10n.dart';

/// The frame every account screen shares: an optional "Back" at the top, an
/// uppercase title and intro, the fields, and the main action at the bottom
/// within thumb reach. The action rides above the keyboard.
class AuthLayout extends StatelessWidget {
  const new({
    required this.title,
    required this.primaryAction,
    this.intro,
    this.notice,
    this.children = const [],
    this.secondaryActions = const [],
    this.onBack,
    super.key,
  });

  final String title;
  final String? intro;

  /// A message above the fields: an error, or a success from the last step.
  final Widget? notice;

  /// The fields.
  final List<Widget> children;

  /// The screen's one primary button, full width.
  final Widget primaryAction;

  /// Less important actions under it ("Forgot password?").
  final List<Widget> secondaryActions;

  /// Shows "Back" when set.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final onBack = this.onBack;
    final intro = this.intro;
    final notice = this.notice;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  SolaSpace.space6,
                  SolaSpace.space4,
                  SolaSpace.space6,
                  SolaSpace.space8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (onBack != null)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: SolaButton(
                          key: const Key('auth_back'),
                          label: context.l10n.back,
                          variant: SolaButtonVariant.ghost,
                          onPressed: onBack,
                        ),
                      )
                    else
                      const SizedBox(height: SolaSpace.space12),
                    const SizedBox(height: SolaSpace.space6),
                    SolaText(title, style: SolaTextStyle.h1),
                    if (intro != null) ...[
                      const SizedBox(height: SolaSpace.space3),
                      SolaText(intro, color: SolaColors.inkMuted),
                    ],
                    if (notice != null) ...[
                      const SizedBox(height: SolaSpace.space6),
                      notice,
                    ],
                    const SizedBox(height: SolaSpace.space8),
                    ...[
                      for (final (i, child) in children.indexed) ...[
                        if (i > 0) const SizedBox(height: SolaSpace.space6),
                        child,
                      ],
                    ],
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: SolaColors.line)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(SolaSpace.space6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: SolaSpace.space2,
                  children: [primaryAction, ...secondaryActions],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
