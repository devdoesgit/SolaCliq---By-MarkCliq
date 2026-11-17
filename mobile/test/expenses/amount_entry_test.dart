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

    test("no leading zeros, and never past the server's ₹10,00,000", () {
      expect(_type('007').text, '7');
      expect(_type('1000000').paise, AmountEntry.maxPaise);
      expect(_type('10000000').text, '1000000');
      expect(_type('1234567').text, '123456');
      expect(_type('1000000.5').text, '1000000.');
      expect(_type('999999.99').paise, 99999999);
    });

    test('delete removes the last key', () {
      expect(_type('12.5').delete().text, '12.');
      expect(const AmountEntry().delete().text, '');
    });
  });
}
