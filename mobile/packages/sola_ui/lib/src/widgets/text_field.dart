import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/src/theme/sola_text.dart';
import 'package:sola_ui/src/tokens/tokens.g.dart';
import 'package:sola_ui/src/widgets/focus_ring.dart';
import 'package:sola_ui/src/widgets/semantics_id.dart';

/// A labelled SolaCliq text field: mono uppercase label above, 48dp input,
/// help or error text below.
///
/// The label, help and error are merged into the field's semantics, so a
/// screen reader (and mobile-mcp) reads them with the field.
class SolaTextField extends StatefulWidget {
  /// Creates a text field.
  const new({
    required Key super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.initialValue,
    this.hint,
    this.help,
    this.error,
    this.numeric = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.autofillHints,
    this.obscureText = false,
    this.enabled = true,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
  }) : assert(
         controller == null || initialValue == null,
         'Pass either a controller or an initialValue, not both.',
       );

  /// Field label, in sentence case; shown in uppercase.
  final String label;

  /// Owned and disposed by the caller. Without one the field keeps its own.
  final TextEditingController? controller;

  /// Owned and disposed by the caller.
  final FocusNode? focusNode;

  /// Starting text when no [controller] is given.
  final String? initialValue;

  /// Placeholder shown when empty.
  final String? hint;

  /// Help text under the field.
  final String? help;

  /// Error text under the field; replaces [help] and turns the edge red.
  final String? error;

  /// Mono, tabular figures and a number keyboard: amounts, kW, readings.
  final bool numeric;

  /// Keyboard type; defaults to a number pad when [numeric].
  final TextInputType? keyboardType;

  /// The keyboard's action button.
  final TextInputAction? textInputAction;

  /// Restricts what can be typed.
  final List<TextInputFormatter>? inputFormatters;

  /// Autofill hints, such as [AutofillHints.email].
  final Iterable<String>? autofillHints;

  /// Hide the text (passwords).
  final bool obscureText;

  /// Whether the field accepts input.
  final bool enabled;

  /// Maximum characters; no counter is shown.
  final int? maxLength;

  /// Called on every change.
  final ValueChanged<String>? onChanged;

  /// Called when the keyboard's action button is pressed.
  final ValueChanged<String>? onSubmitted;

  /// Focus the field when it first appears.
  final bool autofocus;

  @override
  State<SolaTextField> createState() => _SolaTextFieldState();
}

class _SolaTextFieldState extends State<SolaTextField> {
  // Only created when the caller passes no controller; disposed here.
  TextEditingController? _ownController;
  bool _focused = false;

  TextEditingController get _controller =>
      widget.controller ??
      (_ownController ??= TextEditingController(text: widget.initialValue));

  @override
  void didUpdateWidget(SolaTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null && _ownController != null) {
      _ownController!.dispose();
      _ownController = null;
    }
  }

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.error;
    final edge = error != null ? SolaColors.danger : SolaColors.lineStrong;
    final border = OutlineInputBorder(borderSide: BorderSide(color: edge));
    // Typed values sit one step heavier than running text (300) so they read
    // outdoors.
    final inputStyle = widget.numeric
        ? SolaTextStyle.num.textStyle()
        : SolaTextStyle.body.withWeight(
            SolaTextStyle.body.textStyle(),
            FontWeight.w400,
          );

    return Semantics(
      identifier: semanticsIdentifier(widget.key),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SolaText(widget.label, style: SolaTextStyle.label),
            const SizedBox(height: SolaSpace.space2),
            Focus(
              canRequestFocus: false,
              skipTraversal: true,
              onFocusChange: (value) {
                if (mounted) setState(() => _focused = value);
              },
              child: SolaFocusRing(
                visible: _focused,
                child: TextField(
                  controller: _controller,
                  focusNode: widget.focusNode,
                  enabled: widget.enabled,
                  obscureText: widget.obscureText,
                  autofocus: widget.autofocus,
                  maxLength: widget.maxLength,
                  keyboardType:
                      widget.keyboardType ??
                      (widget.numeric
                          ? const TextInputType.numberWithOptions(decimal: true)
                          : null),
                  textInputAction: widget.textInputAction,
                  inputFormatters: widget.inputFormatters,
                  autofillHints: widget.autofillHints,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  style: inputStyle.copyWith(
                    color: widget.enabled
                        ? SolaColors.ink
                        : SolaColors.inkMuted,
                  ),
                  cursorColor: SolaColors.ink,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: inputStyle.copyWith(color: SolaColors.inkMuted),
                    filled: true,
                    fillColor: widget.enabled
                        ? SolaColors.panel
                        : SolaColors.surfaceSunken,
                    counterText: '',
                    isDense: true,
                    constraints: const BoxConstraints(
                      minHeight: SolaSize.tapMin,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: SolaSpace.space3,
                      vertical: SolaSpace.space3,
                    ),
                    border: border,
                    enabledBorder: border,
                    focusedBorder: border,
                    disabledBorder: border.copyWith(
                      borderSide: const BorderSide(color: SolaColors.line),
                    ),
                  ),
                ),
              ),
            ),
            if (error != null || widget.help != null) ...[
              const SizedBox(height: SolaSpace.space2),
              SolaText(
                error ?? widget.help!,
                style: SolaTextStyle.bodySm,
                color: error != null ? SolaColors.danger : SolaColors.inkMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
