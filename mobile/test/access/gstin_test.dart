import 'package:flutter_test/flutter_test.dart';
import 'package:solacliq/access/data/gstin.dart';

void main() {
  // A GSTIN published as an example by GST portals; the server's tests
  // use the same one (backend/src/gstin.rs).
  const sample = '27AAPFU0939F1ZV';

  group(Gstin, () {
    test('a valid GSTIN gives its PAN and state', () {
      final g = Gstin.tryParse(sample)!;
      expect(g.number, sample);
      expect(g.pan, 'AAPFU0939F');
      expect(g.state, 'Maharashtra');
    });

    test('spaces and lowercase are fine', () {
      expect(Gstin.tryParse(' 27aapfu0939f 1zv ')?.number, sample);
    });

    test('a typo fails the check character', () {
      expect(Gstin.tryParse('27AAPFU0939F1ZW'), isNull);
      expect(Gstin.tryParse('27AAPFU0938F1ZV'), isNull);
    });

    test('wrong shapes and unknown states fail', () {
      expect(Gstin.tryParse(''), isNull);
      expect(Gstin.tryParse('27AAPFU0939F1Z'), isNull);
      expect(Gstin.tryParse('27AAPFU0939F1YV'), isNull);
      expect(Gstin.tryParse('99AAPFU0939F1ZV'), isNull);
    });
  });
}
