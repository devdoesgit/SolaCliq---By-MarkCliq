import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solacliq/auth/auth.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final session = StoredSession(
    accessToken: 'a',
    refreshToken: 'r',
    accessExpiresAt: DateTime.utc(2026, 10, 18, 12),
    accountJson: const {'name': 'Asha'},
  );

  group(StoredSession, () {
    test('round-trips through JSON', () {
      expect(StoredSession.fromJson(session.toJson()), session);
    });

    test('rejects incomplete JSON instead of half a login', () {
      expect(StoredSession.fromJson(const {'access_token': 'a'}), isNull);
      expect(
        StoredSession.fromJson(const {
          'access_token': 'a',
          'refresh_token': 'r',
          'access_expires_at': 'not a date',
        }),
        isNull,
      );
    });

    test('withAccount keeps the tokens', () {
      final updated = session.withAccount(const {'name': 'New'});
      expect(updated.refreshToken, 'r');
      expect(updated.accountJson, const {'name': 'New'});
    });
  });

  group(SecureTokenStore, () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('writes, reads and clears', () async {
      final store = SecureTokenStore();
      expect(await store.read(), isNull);
      await store.write(session);
      expect(await store.read(), session);
      await store.clear();
      expect(await store.read(), isNull);
    });

    test('corrupt data is cleared, not a crash', () async {
      FlutterSecureStorage.setMockInitialValues({'session': '{not json'});
      final store = SecureTokenStore();
      expect(await store.read(), isNull);
      expect(await store.read(), isNull);
    });
  });
}
