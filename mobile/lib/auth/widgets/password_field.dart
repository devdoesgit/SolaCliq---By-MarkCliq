import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/l10n/l10n.dart';

/// A password row of a [SolaGroup] with the "Show" link that shows or
/// hides it. Its input is `<key>_input` and the link is `<key>_toggle`.
class PasswordField extends StatefulWidget {
  const new({
    required ValueKey<String> super.key,
    required this.label,
    required this.controller,
    this.error,
    this.placeholder,
    this.isNew = false,
    this.showToggle = true,
    this.textInputAction = TextInputAction.done,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String? error;
  final String? placeholder;

  /// A new password: offers to save it instead of filling a saved one.
  final bool isNew;

  /// Shows the "Show" link.
  final bool showToggle;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final key = widget.key! as ValueKey<String>;
    return SolaFieldRow(
      key: key,
      label: widget.label,
      controller: widget.controller,
      error: widget.error,
      placeholder: widget.placeholder,
      obscureText: !_visible,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      autofillHints: [
        if (widget.isNew) AutofillHints.newPassword else AutofillHints.password,
      ],
      inputFormatters: [LengthLimitingTextInputFormatter(128)],
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      trailing: widget.showToggle
          ? SolaTextLink(
              _visible ? l10n.hide : l10n.show,
              key: ValueKey('${key.value}_toggle'),
              style: SolaTextStyle.body,
              onPressed: () => setState(() => _visible = !_visible),
            )
          : null,
    );
  }
}
