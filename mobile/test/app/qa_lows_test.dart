import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/dev/quick_forms.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/auth/view/login_page.dart';
import 'package:solacliq/auth/view/reset_password_page.dart';
import 'package:solacliq/auth/view/signup_page.dart';
import 'package:solacliq/auth/view/welcome_page.dart';
import 'package:solacliq/customers/data/customer_repository.dart';
import 'package:solacliq/customers/data/registration_repository.dart';
import 'package:solacliq/customers/view/add_customer_page.dart';
import 'package:solacliq/customers/view/customers_tab.dart';
import 'package:solacliq/expenses/view/expense_page.dart';
import 'package:solacliq/home/data/home_repository.dart';
import 'package:solacliq/home/view/home_parts.dart';
import 'package:solacliq/uploads/data/upload_repository.dart';
import 'package:solacliq/workspace/data/workspace.dart';

import '../helpers/helpers.dart';

Finder _input(String key) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byType(TextField),
);

void _phone(WidgetTester tester, {double keyboard = 0}) {
  tester.view.physicalSize = const Size(360, 720);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.reset);
}

class _Picks extends ImagePickerPlatform with MockPlatformInterfaceMixin {
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async => XFile.fromData(Uint8List(4), path: 'a.jpg');
}

/// The low issues of docs/qa/2026-11-22-mobile-e2e.md, by number.
void main() {
  setUpAll(() {
    registerFallbackValue(UploadFile(name: 'a.jpg', bytes: Uint8List(4)));
    registerFallbackValue(UploadPurpose.kyc);
  });

  testWidgets('QA-10 one task is "1 task"', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpApp(
      const Scaffold(
        body: HomeWeek(
          days: [
            HomeDay(day: 'Sat', date: 21, dots: [HomeDot.live]),
            HomeDay(day: 'Sun', date: 22, dots: [HomeDot.live, HomeDot.live]),
          ],
        ),
      ),
    );
    expect(find.bySemanticsLabel('Sat 21, 1 task'), findsOne);
    expect(find.bySemanticsLabel('Sun 22, 2 tasks'), findsOne);
    semantics.dispose();
  });

  testWidgets('QA-12 an empty field asks in a sentence', (tester) async {
    await tester.pumpApp(const LoginPage());
    await tester.tapKey('login_submit');
    await tester.pump();
    expect(find.text('Enter an email address.'), findsOne);
    expect(find.text('Enter a password.'), findsOne);
  });

  group('QA-14 customers search', () {
    Future<void> pump(WidgetTester tester) async {
      final customers = MockCustomerRepository();
      when(() => customers.mine(any())).thenAnswer(
        (_) async => [
          CustomerSummary(
            id: 'c1',
            name: 'Sunita Rao',
            systemKw: 3,
            place: 'Mohali',
            kyc: KycStatus.inReview,
            detail: 'Sent today',
            sentAt: DateTime(2026, 10, 22),
          ),
        ],
      );
      await tester.pumpApp(
        const CustomersTab(orgId: 'o1'),
        repositories: [
          RepositoryProvider<CustomerRepository>.value(value: customers),
        ],
      );
      await tester.pumpAndSettle();
      await tester.tapKey('customers_search');
      await tester.pumpAndSettle();
    }

    testWidgets('the icon focuses the field', (tester) async {
      await pump(tester);
      expect(tester.testTextInput.isVisible, isTrue);
      // It searches names only, so it mustn't offer phone numbers.
      expect(find.text('Search by name'), findsOne);
    });

    testWidgets('back from a customer, the keyboard stays down', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.text('Sunita Rao'));
      await tester.pumpAndSettle();
      tester.state<NavigatorState>(find.byType(Navigator).last).pop();
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isFalse);
    });

    testWidgets('no match says so', (tester) async {
      await pump(tester);
      await tester.enterText(_input('customers_query'), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('No customers match "zzz".'), findsOne);
    });
  });

  testWidgets('QA-15 closing a sheet leaves the keyboard down', (tester) async {
    await tester.pumpApp(
      Scaffold(
        body: Builder(
          builder: (context) => Column(
            children: [
              const TextField(key: Key('field')),
              TextButton(
                key: const Key('open'),
                onPressed: () => showSolaSheet<void>(
                  context: context,
                  title: 'Sheet',
                  doneLabel: 'Done',
                  builder: (_) => const SizedBox(height: 80),
                ),
                child: const Text('Open'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('field')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('QA-16 the keypad makes way for the keyboard', (tester) async {
    _phone(tester, keyboard: 280);
    await tester.pumpApp(
      ExpensePage(workspace: MemberWorkspace(testMembership())),
      repositories: [
        RepositoryProvider<UploadRepository>.value(
          value: MockUploadRepository(),
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.byType(SolaKeypad), findsNothing);
  });

  testWidgets('QA-18 a notice is as tall as its text', (tester) async {
    _phone(tester);
    await tester.pumpApp(
      const Scaffold(
        body: Center(
          child: SolaNotice(title: 'Camera not allowed', body: 'Allow it.'),
        ),
      ),
    );
    expect(tester.getSize(find.byType(SolaNotice)).height, lessThan(120));
  });

  testWidgets('QA-19 scrolled content fades under the header', (tester) async {
    _phone(tester);
    await tester.pumpApp(
      const SolaScreen(
        navBar: SolaNavBar(title: 'Payments'),
        body: SizedBox(height: 2000, width: 100),
      ),
    );
    const edge = Key('screen_scroll_edge');
    expect(find.byKey(edge), findsNothing);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(edge), findsOne);
  });

  testWidgets('QA-20 a light screen has dark status icons', (tester) async {
    await tester.pumpApp(const SolaScreen(body: Text('Body')));
    final styles = tester
        .widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
        )
        .map((r) => r.value.statusBarIconBrightness);
    expect(styles, contains(Brightness.dark));
  });

  testWidgets('QA-21 the checklist shows above the keyboard', (tester) async {
    _phone(tester, keyboard: 280);
    await tester.pumpApp(const ResetPasswordPage(email: 'asha@example.com'));
    await tester.pumpAndSettle();
    await tester.showKeyboard(_input('reset_password'));
    await tester.enterText(_input('reset_password'), 'sun');
    await tester.pumpAndSettle();
    expect(find.text('Has a number').hitTestable(), findsOne);
  });

  testWidgets('QA-23 the sample pills say they are illustrative', (
    tester,
  ) async {
    await tester.pumpApp(const WelcomePage());
    expect(find.text('Illustrative'), findsOne);
  });

  testWidgets('QA-24 the install bar says how far it has got', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpApp(
      const Scaffold(
        body: HomeProgressView(
          progress: HomeProgress(
            label: 'Install progress',
            segments: [
              HomeSegment(weight: 1, tone: HomeTone.success),
              HomeSegment(weight: 1, tone: HomeTone.live),
              HomeSegment(weight: 1, tone: HomeTone.empty),
            ],
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Install progress, 2 of 3'), findsOne);
    semantics.dispose();
  });

  group('add customer', () {
    Future<void> pumpDetails(WidgetTester tester) async {
      _phone(tester);
      await tester.pumpApp(
        AddCustomerPage(
          workspace: MemberWorkspace(
            testMembership(role: OrgRole.agent, payType: PayType.salary),
          ),
        ),
        repositories: [
          RepositoryProvider<UploadRepository>.value(
            value: MockUploadRepository(),
          ),
          RepositoryProvider<RegistrationRepository>.value(
            value: MockRegistrationRepository(),
          ),
        ],
      );
      await tester.pumpAndSettle();
    }

    testWidgets('QA-22 a long state name is shown whole', (tester) async {
      await pumpDetails(tester);
      await tester.tapKey('customer_state');
      await tester.pumpAndSettle();
      final name = tester.widget<Text>(
        find.text('Dadra and Nagar Haveli and Daman and Diu'),
      );
      expect(name.maxLines, isNot(1));
    });

    testWidgets('QA-17 an upload error is shown whole', (tester) async {
      ImagePickerPlatform.instance = _Picks();
      final uploads = MockUploadRepository();
      when(() => uploads.upload(any(), any(), any()))
          .thenThrow(const UploadRefused(UploadProblem.tooLarge));
      _phone(tester);
      await tester.pumpApp(
        AddCustomerPage(
          workspace: MemberWorkspace(
            testMembership(role: OrgRole.agent, payType: PayType.salary),
          ),
        ),
        repositories: [
          RepositoryProvider<UploadRepository>.value(value: uploads),
          RepositoryProvider<RegistrationRepository>.value(
            value: MockRegistrationRepository(),
          ),
          RepositoryProvider<QuickForms>(
            create: (_) => QuickForms(available: true),
            dispose: (quick) => quick.dispose(),
          ),
        ],
      );
      for (var step = 0; step < 2; step++) {
        await tester.tapKey('add_customer_next');
        await tester.pumpAndSettle();
      }
      await tester.tapKey('doc_aadhaar');
      await tester.pumpAndSettle();
      await tester.tapKey('pick_gallery');
      await tester.pumpAndSettle();
      final error = tester.widget<Text>(find.textContaining('over 10 MB'));
      expect(error.maxLines, greaterThan(1));
    });

    testWidgets('QA-25 over 1,000 kW is caught in the app', (tester) async {
      await pumpDetails(tester);
      for (final (key, value) in [
        ('customer_name', 'Test Customer'),
        ('customer_mobile', '9814022671'),
        ('customer_email', 't@example.com'),
        ('customer_address', 'H 1'),
        ('customer_city_pin', 'Mohali 160062'),
      ]) {
        await tester.enterText(_input(key), value);
      }
      await tester.tapKey('customer_state');
      await tester.pumpAndSettle();
      await tester.tapKey('option_Punjab');
      await tester.pumpAndSettle();
      await tester.tapKey('add_customer_next');
      await tester.pumpAndSettle();
      await tester.enterText(_input('customer_proposed'), '1001');
      await tester.tapKey('add_customer_next');
      await tester.pumpAndSettle();
      expect(find.text('Up to 1,000 kW.'), findsOne);
    });
  });

  testWidgets('QA-26 sign-up errors clear while typing', (tester) async {
    await tester.pumpApp(const SignupPage());
    await tester.tapKey('signup_submit');
    await tester.pumpAndSettle();
    expect(find.text('Enter a password.'), findsOne);
    await tester.enterText(_input('signup_password'), 'l');
    await tester.pumpAndSettle();
    expect(find.text('Enter a password.'), findsNothing);
  });
}
