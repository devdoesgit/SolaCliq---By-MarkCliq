import 'package:flutter_test/flutter_test.dart';
import 'package:solacliq/app/dev/quick_forms.dart';

void main() {
  test('only the development flavor can turn it on', () {
    final dev = QuickForms(available: true);
    final prod = QuickForms(available: false);
    addTearDown(dev.dispose);
    addTearDown(prod.dispose);
    expect(dev.enabled.value, isTrue);
    expect(prod.enabled.value, isFalse);
  });
}
