import 'package:flutter_test/flutter_test.dart';
import 'package:solacliq/app/data/api_call.dart';

void main() {
  group('allPages', () {
    test('follows the cursor until there is none', () async {
      final cursors = <String?>[];
      final items = await allPages<int>((cursor) async {
        cursors.add(cursor);
        return switch (cursor) {
          null => ([1, 2], 'b'),
          'b' => ([3], 'c'),
          _ => ([4], null),
        };
      });
      expect(items, [1, 2, 3, 4]);
      expect(cursors, [null, 'b', 'c']);
    });

    test('stops after maxPages if the server never ends', () async {
      var calls = 0;
      final items = await allPages<int>((_) async {
        calls++;
        return ([calls], 'again');
      }, maxPages: 3);
      expect(items, [1, 2, 3]);
      expect(calls, 3);
    });
  });
}
