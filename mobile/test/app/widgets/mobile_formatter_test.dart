import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solacliq/app/widgets/mobile_formatter.dart';

TextEditingValue _type(String text, {int? cursor}) =>
    const MobileNumberFormatter().formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: cursor ?? text.length),
      ),
    );

void main() {
  group(MobileNumberFormatter, () {
    test('keeps at most 10 digits', () {
      expect(_type('98140226710').text, '98140 22671');
      expect(_type('981402267101234').text, '98140 22671');
    });

    test('spaces after the 5th digit only once there are more', () {
      expect(_type('98140').text, '98140');
      expect(_type('981402').text, '98140 2');
      expect(_type('9814022671').text, '98140 22671');
    });

    test('a pasted +91 or 0 in front is dropped, as are dashes', () {
      expect(_type('+91-98140-22671').text, '98140 22671');
      expect(_type('+91 98140 22671').text, '98140 22671');
      expect(_type('098140 22671').text, '98140 22671');
      expect(_type('98140-22671').text, '98140 22671');
    });

    test('a number that starts with 91 itself is kept', () {
      expect(_type('9198140226').text, '91981 40226');
      // An extra digit typed on the end is dropped, not the 91.
      expect(_type('91981402267').text, '91981 40226');
    });

    test('the cursor stays after the same digit', () {
      // Typing a digit at position 3 of "98140 2267".
      final v = _type('981X40 2267'.replaceFirst('X', '5'), cursor: 4);
      expect(v.text, '98154 02267');
      expect(v.selection.baseOffset, 4);
      // After the 7th digit, the space counts.
      final w = _type('9814022671', cursor: 7);
      expect(w.selection.baseOffset, 8);
    });
  });
}
