import 'package:flutter_test/flutter_test.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/workspace/data/workspace.dart';

import '../helpers/helpers.dart';

void main() {
  group('earnsCommission', () {
    bool earns(OrgRole role, [PayType? payType]) =>
        MemberWorkspace(testMembership(role: role, payType: payType))
            .earnsCommission;

    test('only commission agents earn one', () {
      expect(earns(OrgRole.agent, PayType.commission), isTrue);
      expect(earns(OrgRole.agent, PayType.salary), isFalse);
      expect(earns(OrgRole.worker), isFalse);
      expect(earns(OrgRole.customer), isFalse);
    });

    test('an agent without a pay type is treated as salaried', () {
      expect(earns(OrgRole.agent), isFalse);
    });
  });
}
