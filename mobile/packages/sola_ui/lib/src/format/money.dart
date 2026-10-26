/// Minus sign used for negative amounts (U+2212), never a hyphen or brackets.
const minusSign = '−';

/// Formats an amount in paise as rupees for display: `₹1,85,000.00`.
///
/// Uses Indian digit grouping (lakhs and crores), always two decimals, and a
/// leading minus sign for negatives: `−₹5,000.00`. Money is stored and sent
/// as integer paise everywhere; this is the only place it becomes text.
String formatPaise(int paise) {
  final negative = paise < 0;
  // Work on the magnitude digit by digit so the most negative int is safe.
  final digits = paise.toString().replaceFirst('-', '').padLeft(3, '0');
  final rupees = digits.substring(0, digits.length - 2);
  final fraction = digits.substring(digits.length - 2);
  final sign = negative ? minusSign : '';
  return '$sign₹${groupIndian(rupees)}.$fraction';
}

/// Groups a string of digits the Indian way: `18500000` → `1,85,00,000`.
///
/// The last three digits form one group; every group before it has two.
String groupIndian(String digits) {
  if (digits.length <= 3) return digits;
  final head = digits.substring(0, digits.length - 3);
  final tail = digits.substring(digits.length - 3);
  final groups = <String>[];
  for (var end = head.length; end > 0; end -= 2) {
    groups.insert(0, head.substring(end - 2 < 0 ? 0 : end - 2, end));
  }
  return '${groups.join(',')},$tail';
}

/// Formats paise as whole rupees, for estimates and headline figures where
/// paise would be noise: `₹78,000`. Rounds to the nearest rupee.
String formatRupees(int paise) {
  final rupees = (paise / 100).round();
  final sign = rupees < 0 ? minusSign : '';
  return '$sign₹${groupIndian(rupees.abs().toString())}';
}

/// Paise in lakh of rupees with at most one decimal, for price ranges:
/// 24000000 → `2.4`, 30000000 → `3`.
String formatLakh(int paise) {
  final tenths = (paise / 1000000).round();
  final whole = tenths ~/ 10;
  final rest = tenths % 10;
  return rest == 0 ? '$whole' : '$whole.$rest';
}

/// Paise as thousands of rupees with at most one decimal, for small
/// figures in tight places: 400000 → `₹4k`, 410000 → `₹4.1k`, 50000 →
/// `₹500`.
String formatThousands(int paise) {
  final rupees = (paise / 100).round();
  if (rupees.abs() < 1000) return formatRupees(paise);
  final tenths = (rupees / 100).round();
  final whole = tenths ~/ 10;
  final rest = tenths % 10;
  return rest == 0 ? '₹${whole}k' : '₹$whole.${rest}k';
}
