import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solacliq/profile/data/profile_repository.dart';
import 'package:solacliq/profile/view/settings_page.dart';
import 'package:solacliq/push/push_controller.dart';

import '../helpers/helpers.dart';

class _MockProfileRepository extends Mock implements ProfileRepository;

class _MockPushController extends Mock implements PushController;

void main() {
  late _MockProfileRepository profile;
  late _MockPushController push;

  setUp(() {
    profile = _MockProfileRepository();
    push = _MockPushController();
    when(() => push.openSettings()).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester, {required bool pushOn}) async {
    when(() => profile.settings()).thenAnswer(
      (_) async => AppSettings(push: pushOn, whatsapp: false, sound: true),
    );
    await tester.pumpApp(
      const SettingsPage(),
      repositories: [
        RepositoryProvider<ProfileRepository>.value(value: profile),
        RepositoryProvider<PushController>.value(value: push),
      ],
    );
    await tester.pumpAndSettle();
  }

  group('Android blocking notifications', () {
    testWidgets('says so and opens Android settings', (tester) async {
      when(() => push.allowed()).thenAnswer((_) async => false);
      await pump(tester, pushOn: true);
      expect(find.byKey(const Key('settings_push_blocked')), findsOneWidget);
      await tester.tap(find.byKey(const Key('settings_open_android')));
      verify(() => push.openSettings()).called(1);
    });

    testWidgets('says nothing when allowed', (tester) async {
      when(() => push.allowed()).thenAnswer((_) async => true);
      await pump(tester, pushOn: true);
      expect(find.byKey(const Key('settings_push_blocked')), findsNothing);
    });

    testWidgets('says nothing when push is off here anyway', (tester) async {
      when(() => push.allowed()).thenAnswer((_) async => false);
      await pump(tester, pushOn: false);
      expect(find.byKey(const Key('settings_push_blocked')), findsNothing);
    });
  });
}
