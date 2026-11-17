import 'package:sola_ui/sola_ui.dart';

/// An amount in rupees typed on the keypad: digits, one point, at most two
/// decimals, up to [maxPaise] (the server's limit for an expense), so an
/// amount it would refuse can't be typed at all.
class AmountEntry {
  const new([this.text = '']);

  /// What was typed: "1240.5".
  final String text;

  /// ₹10,00,000: more is a typo (the API's `ExpenseCreate.amount`).
  static const maxPaise = 100000000;

  /// [key] added: a digit or ".". Ignores keys that would make it invalid.
  AmountEntry add(String key) {
    final point = text.indexOf('.');
    if (key == '.') {
      if (point >= 0) return this;
      return AmountEntry(text.isEmpty ? '0.' : '$text.');
    }
    if (point >= 0 && text.length - point > 2) return this;
    if (point >= 0) {
      final next = AmountEntry('$text$key');
      return next.paise > maxPaise ? this : next;
    }
    final next = AmountEntry(text == '0' ? key : '$text$key');
    return next.paise > maxPaise ? this : next;
  }

  /// The last key removed.
  AmountEntry delete() =>
      text.isEmpty ? this : AmountEntry(text.substring(0, text.length - 1));

  /// The amount in paise.
  int get paise {
    if (text.isEmpty) return 0;
    final parts = text.split('.');
    final rupees = int.parse(parts[0].isEmpty ? '0' : parts[0]);
    final fraction = parts.length > 1 ? parts[1].padRight(2, '0') : '00';
    return rupees * 100 + int.parse(fraction);
  }

  /// As shown while typing: "₹1,240.5", "₹0" when empty.
  String get display {
    if (text.isEmpty) return '₹0';
    final parts = text.split('.');
    final whole = groupIndian(parts[0]);
    return parts.length > 1 ? '₹$whole.${parts[1]}' : '₹$whole';
  }
}
