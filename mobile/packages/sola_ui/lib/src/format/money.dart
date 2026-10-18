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
