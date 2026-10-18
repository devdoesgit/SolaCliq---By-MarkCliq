import 'package:flutter_test/flutter_test.dart';
import 'package:sola_ui/sola_ui.dart';

void main() {
  group('formatDate', () {
    test('day month year, no leading zero on the day', () {
      expect(formatDate(DateTime(2026, 10, 18)), '18 Oct 2026');
      expect(formatDate(DateTime(2026, 1, 5)), '5 Jan 2026');
      expect(formatDate(DateTime(2027, 12, 31)), '31 Dec 2027');
    });

    test('UTC input is shown in local time', () {
      final utc = DateTime.utc(2026, 10, 18, 12);
      expect(formatDate(utc), formatDate(utc.toLocal()));
    });
  });

  group('formatDateTime', () {
    test('24-hour time with leading zeros', () {
      expect(
        formatDateTime(DateTime(2026, 10, 18, 14, 5)),
        '18 Oct 2026, 14:05',
      );
      expect(formatDateTime(DateTime(2026, 10, 18)), '18 Oct 2026, 00:00');
      expect(
        formatDateTime(DateTime(2026, 10, 18, 23, 59)),
        '18 Oct 2026, 23:59',
      );
    });
  });
}
