import 'package:flutter_test/flutter_test.dart';
import 'package:solacliq/expenses/data/amount_entry.dart';

AmountEntry _type(String keys) =>
    keys.split('').fold(const AmountEntry(), (a, k) => a.add(k));

void main() {
  group(AmountEntry, () {
    test('empty is zero and shows ₹0', () {
      expect(const AmountEntry().paise, 0);
      expect(const AmountEntry().display, '₹0');
    });

    test('whole rupees become paise, grouped the Indian way', () {
      final a = _type('124000');
      expect(a.paise, 12400000);
      expect(a.display, '₹1,24,000');
    });

    test('decimals: at most two, one point', () {
      expect(_type('12.5').paise, 1250);
      expect(_type('12.505').text, '12.50');
      expect(_type('1..2').text, '1.2');
      expect(_type('.5').text, '0.5');
      expect(_type('1240.').display, '₹1,240.');
    });

    test('no leading zeros, and seven digits at most', () {
      expect(_type('007').text, '7');
      expect(_type('123456789').text, '1234567');
    });

    test('delete removes the last key', () {
      expect(_type('12.5').delete().text, '12.');
      expect(const AmountEntry().delete().text, '');
    });
  });
}
