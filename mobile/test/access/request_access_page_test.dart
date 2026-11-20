import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solacliq/access/data/company_registration_repository.dart';
import 'package:solacliq/access/view/request_access_page.dart';
import 'package:solacliq/auth/auth.dart';

import '../helpers/helpers.dart';

Finder _input(String key) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byType(TextField),
);

void main() {
  late MockCompanyRegistrationRepository registrations;

  setUpAll(
    () => registerFallbackValue(
      const CompanyRegistration(
        legalName: '',
        businessType: BusinessType.other,
        gstin: '',
        addressLine1: '',
        city: '',
        pinCode: '',
        ownerName: '',
        email: '',
        phone: '',
        termsVersion: 1,
      ),
    ),
  );

  setUp(() => registrations = MockCompanyRegistrationRepository());

  Future<void> pump(WidgetTester tester) => tester.pumpApp(
    const RequestAccessPage(),
    repositories: [
      RepositoryProvider<CompanyRegistrationRepository>.value(
        value: registrations,
      ),
    ],
  );

  Future<void> fill(
    WidgetTester tester,
    String gstin, {
    bool agree = true,
  }) async {
    await tester.enterText(_input('access_owner'), 'Asha Owner');
    await tester.enterText(_input('access_email'), 'asha@example.com');
    await tester.enterText(_input('access_phone'), '98140 22671');
    await tester.enterText(_input('access_gstin'), gstin);
    await tester.enterText(
      _input('access_legal_name'),
      'Example Solar Pvt Ltd',
    );
    await tester.enterText(_input('access_address1'), 'Plot 4, MIDC');
    await tester.enterText(_input('access_city'), 'Pune');
    await tester.enterText(_input('access_pin'), '411001');
    await tester.tapKey('access_business_type');
    await tester.pumpAndSettle();
    await tester.tapKey('business_type_privateLimited');
    await tester.pumpAndSettle();
    if (agree) {
      await tester.tapKey('terms_agree');
      await tester.tapKey('terms_agree_company');
    }
  }

  group(RequestAccessPage, () {
    testWidgets('sends the registration, with the GSTIN tidied', (
      tester,
    ) async {
      when(() => registrations.register(any())).thenAnswer((_) async {});
      await pump(tester);
      await fill(tester, '27aapfu0939f1zv');
      await tester.pump();
      // The state follows the GSTIN.
      expect(find.text('Maharashtra'), findsOneWidget);

      await tester.tapKey('access_submit');
      await tester.pumpAndSettle();
      final sent =
          verify(() => registrations.register(captureAny())).captured.single
              as CompanyRegistration;
      expect(sent.gstin, '27AAPFU0939F1ZV');
      expect(sent.phone, '9814022671');
      expect(sent.businessType, BusinessType.privateLimited);
      expect(sent.tradeName, isNull);
      expect(sent.addressLine2, isNull);
      expect(sent.termsVersion, 1);
      expect(find.textContaining('route:/request-access/sent'), findsOneWidget);
    });

    testWidgets('both ticks are needed before sending', (tester) async {
      await pump(tester);
      await fill(tester, '27AAPFU0939F1ZV', agree: false);
      // Only the Terms of Use: the Company Terms are still needed.
      await tester.tapKey('terms_agree');
      await tester.tapKey('access_submit');
      await tester.pump();
      expect(find.text('Tick to agree to continue.'), findsOneWidget);
      expect(find.byKey(const Key('terms_read_company')), findsOneWidget);
      verifyNever(() => registrations.register(any()));
    });

    testWidgets('a mistyped GSTIN is caught before sending', (tester) async {
      await pump(tester);
      await fill(tester, '27AAPFU0939F1ZW');
      await tester.tapKey('access_submit');
      await tester.pump();
      expect(
        find.text('Check the 15-character GSTIN on your GST certificate.'),
        findsOneWidget,
      );
      verifyNever(() => registrations.register(any()));
    });

    testWidgets('a GSTIN already registered shows the server message', (
      tester,
    ) async {
      when(() => registrations.register(any()))
          .thenThrow(const AuthFailure(AuthFailureCode.gstinTaken));
      await pump(tester);
      await fill(tester, '27AAPFU0939F1ZV');
      await tester.tapKey('access_submit');
      await tester.pumpAndSettle();
      expect(find.textContaining('already registered'), findsOneWidget);
    });
  });
}
