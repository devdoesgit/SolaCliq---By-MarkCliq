import 'package:flutter/services.dart';

/// An Indian mobile number as it's typed: digits only, at most 10, shown
/// as "98765 43210". The cursor stays after the same digit, so editing
/// in the middle works. Every phone field uses it, so none takes 11
/// digits (a plain length limit of 11, there to allow the space, did).
class MobileNumberFormatter extends TextInputFormatter {
  const new();

  static const maxDigits = 10;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final cursor = newValue.selection.baseOffset.clamp(0, text.length);
    var digits = text.replaceAll(RegExp(r'\D'), '');
    // A pasted "+91 98140 22671" or "098140 22671": drop the country code
    // or trunk 0, which the field's "+91" already stands for.
    final prefix = _prefixLength(digits);
    digits = digits.substring(prefix);
    final kept = digits.length > maxDigits
        ? digits.substring(0, maxDigits)
        : digits;
    final digitsBeforeCursor =
        (text.substring(0, cursor).replaceAll(RegExp(r'\D'), '').length -
                prefix)
            .clamp(0, kept.length);
    final formatted = format(kept);
    // A space follows the 5th digit, so the cursor moves one further.
    final offset = digitsBeforeCursor > 5
        ? digitsBeforeCursor + 1
        : digitsBeforeCursor;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: offset.clamp(0, formatted.length),
      ),
    );
  }

  /*
    Leading digits to drop: "91" or "0" only when they leave exactly a
    full number, so a number that itself starts with 91 is never cut
  */
  static int _prefixLength(String digits) {
    if (digits.length == maxDigits + 2 && digits.startsWith('91')) return 2;
    if (digits.length == maxDigits + 1 && digits.startsWith('0')) return 1;
    return 0;
  }

  /// "9876543210" as "98765 43210".
  static String format(String digits) => digits.length > 5
      ? '${digits.substring(0, 5)} ${digits.substring(5)}'
      : digits;
}
