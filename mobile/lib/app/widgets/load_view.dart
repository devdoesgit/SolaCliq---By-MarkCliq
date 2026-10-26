import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/auth/view/auth_text.dart';
import 'package:solacliq/l10n/l10n.dart';

/// Shows [builder] once [future] completes, a spinner while it runs, and a
/// notice with Retry when it fails.
class LoadView<T> extends StatelessWidget {
  const new({
    required this.future,
    required this.failedTitle,
    required this.onRetry,
    required this.builder,
    super.key,
  });

  final Future<T> future;
  final String failedTitle;
  final VoidCallback onRetry;
  final Widget Function(BuildContext context, T data) builder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) => switch (snapshot) {
        AsyncSnapshot(:final Object error) => Padding(
          padding: const EdgeInsets.only(top: SolaSpace.space26),
          child: SolaNotice(
            title: failedTitle,
            body: error is AuthFailure
                ? error.code.message(context.l10n)
                : null,
            action: SolaButton(
              key: const Key('load_retry'),
              label: context.l10n.retry,
              variant: SolaButtonVariant.white,
              compact: true,
              expand: false,
              onPressed: onRetry,
            ),
          ),
        ),
        AsyncSnapshot(:final T data?) => builder(context, data),
        _ => const Padding(
          padding: EdgeInsets.only(top: 120),
          child: Center(
            child: CircularProgressIndicator(color: SolaColors.ink),
          ),
        ),
      },
    );
  }
}

/// A row in a group that opens something: icon, title, line, chevron.
class NavRow extends StatelessWidget {
  const new({
    required Key super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  final SolaIcons icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SolaListRow(
      title: title,
      subtitle: subtitle,
      leading: SolaAvatar(icon: icon, color: SolaColors.tan),
      trailing:
          trailing ??
          (onTap == null
              ? null
              : const SolaIcon(
                  SolaIcons.chevronRight,
                  size: 18,
                  color: SolaColors.faint,
                )),
      onTap: onTap,
    );
  }
}
