import 'package:flutter_test/flutter_test.dart';
import 'package:sola_ui/sola_ui.dart';

void main() {
  group('formatPaise', () {
    test('zero', () {
      expect(formatPaise(0), '₹0.00');
    });

    test('paise only', () {
      expect(formatPaise(5), '₹0.05');
      expect(formatPaise(50), '₹0.50');
    });

    test('hundreds and thousands', () {
      expect(formatPaise(100), '₹1.00');
      expect(formatPaise(99900), '₹999.00');
      expect(formatPaise(100000), '₹1,000.00');
      expect(formatPaise(4250000), '₹42,500.00');
    });

    test('lakhs', () {
      expect(formatPaise(10000000), '₹1,00,000.00');
      expect(formatPaise(18500000), '₹1,85,000.00');
    });

    test('crores', () {
      expect(formatPaise(1000000000), '₹1,00,00,000.00');
      expect(formatPaise(123456789012), '₹1,23,45,67,890.12');
    });

    test('negatives use a minus sign, not brackets or a hyphen', () {
      expect(formatPaise(-500000), '−₹5,000.00');
      expect(formatPaise(-1), '−₹0.01');
      expect(formatPaise(-500000), isNot(contains('-')));
    });

    test('largest and smallest int', () {
      expect(formatPaise(9223372036854775807), '₹92,23,37,20,36,85,47,758.07');
      expect(
        formatPaise(-9223372036854775808),
        '−₹92,23,37,20,36,85,47,758.08',
      );
    });
  });

  group('groupIndian', () {
    test('up to three digits stays as is', () {
      expect(groupIndian('7'), '7');
      expect(groupIndian('123'), '123');
    });

    test('groups of two before the last three', () {
      expect(groupIndian('1234'), '1,234');
      expect(groupIndian('12345'), '12,345');
      expect(groupIndian('123456'), '1,23,456');
      expect(groupIndian('1234567'), '12,34,567');
    });
  });

  group('formatRupees', () {
    test('whole rupees with Indian grouping', () {
      expect(formatRupees(7800000), '₹78,000');
      expect(formatRupees(28500000), '₹2,85,000');
      expect(formatRupees(-50000), '$minusSign₹500');
    });
  });

  group('formatLakh', () {
    test('one decimal at most', () {
      expect(formatLakh(24000000), '2.4');
      expect(formatLakh(30000000), '3');
      expect(formatLakh(29000000), '2.9');
    });
  });
}
