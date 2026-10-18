import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/l10n/l10n.dart';

/// A password field with a "Show password" button under it.
class PasswordField extends StatefulWidget {
  const new({
    required Key super.key,
    required this.controller,
    required this.label,
    this.error,
    this.help,
    this.isNew = false,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? error;
  final String? help;

  /// A password being chosen (autofill offers to generate and save one).
  final bool isNew;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SolaTextField(
          key: ValueKey('${key.value}_input'),
          label: widget.label,
          controller: widget.controller,
          obscureText: !_visible,
          error: widget.error,
          help: widget.help,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.done,
          autofillHints: [
            if (widget.isNew)
              AutofillHints.newPassword
            else
              AutofillHints.password,
          ],
          inputFormatters: [LengthLimitingTextInputFormatter(128)],
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
        ),
        SolaButton(
          key: ValueKey('${key.value}_toggle'),
          label: _visible ? l10n.hidePassword : l10n.showPassword,
          variant: SolaButtonVariant.ghost,
          onPressed: () => setState(() => _visible = !_visible),
        ),
      ],
    );
  }
}
