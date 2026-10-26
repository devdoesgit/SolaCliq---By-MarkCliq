import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/auth/view/forgot_password_page.dart';
import 'package:solacliq/auth/view/login_page.dart';
import 'package:solacliq/auth/view/reset_password_page.dart';
import 'package:solacliq/auth/view/signup_page.dart';
import 'package:solacliq/auth/view/verify_email_page.dart';
import 'package:solacliq/auth/view/welcome_page.dart';

import '../helpers/helpers.dart';

Finder _input(String key) =>
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));

void main() {
  late MockAuthRepository auth;

  setUp(() => auth = MockAuthRepository());

  group(WelcomePage, () {
    testWidgets('get started opens the intro', (tester) async {
      await tester.pumpApp(const WelcomePage(), authRepository: auth);
      await tester.tapKey('welcome_get_started');
      await tester.pumpAndSettle();
      expect(find.text('route:/intro'), findsOneWidget);
    });
  });

  group(LoginPage, () {
    testWidgets('checks fields before sending anything', (tester) async {
      await tester.pumpApp(const LoginPage(), authRepository: auth);
      await tester.tapKey('login_submit');
      await tester.pump();
      expect(find.text('Enter Email.'), findsOneWidget);
      expect(find.text('Enter Password.'), findsOneWidget);
      verifyNever(
        () => auth.logIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    testWidgets('logs in with the trimmed email', (tester) async {
      when(
        () => auth.logIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {});
      await tester.pumpApp(const LoginPage(), authRepository: auth);
      await tester.enterText(_input('login_email'), ' person@example.com ');
      await tester.enterText(_input('login_password'), 'secret');
      await tester.tapKey('login_submit');
      await tester.pump();
      verify(() => auth.logIn(email: 'person@example.com', password: 'secret'))
          .called(1);
    });

    testWidgets('wrong details show one message for both', (tester) async {
      when(
        () => auth.logIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthFailure(AuthFailureCode.invalidCredentials));
      await tester.pumpApp(const LoginPage(), authRepository: auth);
      await tester.enterText(_input('login_email'), 'person@example.com');
      await tester.enterText(_input('login_password'), 'wrong');
      await tester.tapKey('login_submit');
      await tester.pump();
      expect(find.text('Email or password is wrong.'), findsOneWidget);
    });

    testWidgets('an unverified email offers to verify', (tester) async {
      when(
        () => auth.logIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthFailure(AuthFailureCode.emailUnverified));
      when(() => auth.resendVerification(email: any(named: 'email')))
          .thenAnswer((_) async {});
      await tester.pumpApp(const LoginPage(), authRepository: auth);
      await tester.enterText(_input('login_email'), 'person@example.com');
      await tester.enterText(_input('login_password'), 'secret');
      await tester.tapKey('login_submit');
      await tester.pump();
      // Let the scroll that revealed the focused field finish first.
      await tester.pumpAndSettle();
      await tester.tapKey('login_verify_now');
      await tester.pumpAndSettle();
      verify(() => auth.resendVerification(email: 'person@example.com'))
          .called(1);
      expect(
        find.text('route:/verify?email=person%40example.com'),
        findsOneWidget,
      );
    });

    testWidgets('shows where the person came from', (tester) async {
      await tester.pumpApp(
        const LoginPage(
          initialEmail: 'person@example.com',
          notice: LoginNotice.emailVerified,
        ),
        authRepository: auth,
      );
      expect(find.text('Email verified. Log in to continue.'), findsOneWidget);
      expect(find.text('person@example.com'), findsOneWidget);
    });

    testWidgets('password can be shown', (tester) async {
      await tester.pumpApp(const LoginPage(), authRepository: auth);
      bool obscured() =>
          tester.widget<TextField>(_input('login_password')).obscureText;
      expect(obscured(), isTrue);
      await tester.ensureVisible(
        find.byKey(const Key('login_password_toggle')),
      );
      await tester.tapKey('login_password_toggle');
      await tester.pump();
      expect(obscured(), isFalse);
    });
  });

  group(SignupPage, () {
    testWidgets('a short password is caught before sending', (tester) async {
      await tester.pumpApp(const SignupPage(), authRepository: auth);
      await tester.enterText(_input('signup_name'), 'Asha');
      await tester.enterText(_input('signup_email'), 'asha@example.com');
      await tester.enterText(_input('signup_password'), 'short1');
      await tester.tapKey('signup_submit');
      await tester.pump();
      expect(find.text('Use at least 8 characters.'), findsOneWidget);
    });

    testWidgets('success goes to verify email', (tester) async {
      when(
        () => auth.signUp(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {});
      await tester.pumpApp(const SignupPage(), authRepository: auth);
      await tester.enterText(_input('signup_name'), ' Asha ');
      await tester.enterText(_input('signup_email'), 'asha@example.com');
      await tester.enterText(_input('signup_password'), 'longenough1');
      await tester.tapKey('signup_submit');
      await tester.pumpAndSettle();
      verify(
        () => auth.signUp(
          name: 'Asha',
          email: 'asha@example.com',
          password: 'longenough1',
        ),
      ).called(1);
      expect(
        find.text('route:/verify?email=asha%40example.com'),
        findsOneWidget,
      );
    });
  });

  group(VerifyEmailPage, () {
    testWidgets('accepts digits only, six at most', (tester) async {
      await tester.pumpApp(
        const VerifyEmailPage(email: 'asha@example.com'),
        authRepository: auth,
      );
      await tester.enterText(_input('verify_code'), '12a34567');
      expect(find.text('123456'), findsOneWidget);
    });

    testWidgets('success goes to log in with a message', (tester) async {
      when(
        () => auth.verifyEmail(
          email: any(named: 'email'),
          code: any(named: 'code'),
        ),
      ).thenAnswer((_) async {});
      await tester.pumpApp(
        const VerifyEmailPage(email: 'asha@example.com'),
        authRepository: auth,
      );
      await tester.enterText(_input('verify_code'), '482913');
      await tester.tapKey('verify_submit');
      await tester.pumpAndSettle();
      verify(() => auth.verifyEmail(email: 'asha@example.com', code: '482913'))
          .called(1);
      expect(
        find.text('route:/login?email=asha%40example.com&notice=verified'),
        findsOneWidget,
      );
    });

    testWidgets('an expired code says so', (tester) async {
      when(
        () => auth.verifyEmail(
          email: any(named: 'email'),
          code: any(named: 'code'),
        ),
      ).thenThrow(const AuthFailure(AuthFailureCode.codeExpired));
      await tester.pumpApp(
        const VerifyEmailPage(email: 'asha@example.com'),
        authRepository: auth,
      );
      await tester.enterText(_input('verify_code'), '482913');
      await tester.tapKey('verify_submit');
      await tester.pump();
      expect(
        find.text('That code has expired. Send a new one.'),
        findsOneWidget,
      );
    });

    testWidgets('sends a new code', (tester) async {
      when(() => auth.resendVerification(email: any(named: 'email')))
          .thenAnswer((_) async {});
      await tester.pumpApp(
        const VerifyEmailPage(email: 'asha@example.com'),
        authRepository: auth,
      );
      // Another code can be sent once the countdown ends.
      expect(find.byKey(const Key('verify_resend')), findsNothing);
      await tester.pump(const Duration(seconds: 31));
      await tester.tapKey('verify_resend');
      await tester.pump();
      expect(find.text('New code sent'), findsOneWidget);
    });
  });

  group('password reset', () {
    testWidgets('forgot sends a code and moves on', (tester) async {
      when(() => auth.requestPasswordReset(email: any(named: 'email')))
          .thenAnswer((_) async {});
      await tester.pumpApp(
        const ForgotPasswordPage(initialEmail: 'asha@example.com'),
        authRepository: auth,
      );
      await tester.tapKey('forgot_submit');
      await tester.pumpAndSettle();
      expect(
        find.text('route:/reset?email=asha%40example.com'),
        findsOneWidget,
      );
    });

    testWidgets('reset saves the password and logs straight in', (
      tester,
    ) async {
      when(
        () => auth.resetPassword(
          email: any(named: 'email'),
          code: any(named: 'code'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => auth.logIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {});
      await tester.pumpApp(
        const ResetPasswordPage(email: 'asha@example.com'),
        authRepository: auth,
      );
      await tester.enterText(_input('reset_code'), '111222');
      await tester.enterText(_input('reset_password'), 'newpassword1');
      await tester.enterText(_input('reset_confirm'), 'newpassword1');
      await tester.tapKey('reset_submit');
      await tester.pumpAndSettle();
      verify(
        () => auth.resetPassword(
          email: 'asha@example.com',
          code: '111222',
          newPassword: 'newpassword1',
        ),
      ).called(1);
      verify(
        () => auth.logIn(email: 'asha@example.com', password: 'newpassword1'),
      ).called(1);
    });

    testWidgets('passwords that differ are caught before sending', (
      tester,
    ) async {
      await tester.pumpApp(
        const ResetPasswordPage(email: 'asha@example.com'),
        authRepository: auth,
      );
      await tester.enterText(_input('reset_code'), '111222');
      await tester.enterText(_input('reset_password'), 'newpassword1');
      await tester.enterText(_input('reset_confirm'), 'newpassword2');
      await tester.tapKey('reset_submit');
      await tester.pump();
      verifyNever(
        () => auth.resetPassword(
          email: any(named: 'email'),
          code: any(named: 'code'),
          newPassword: any(named: 'newPassword'),
        ),
      );
    });
  });

  group('first-time set-up', () {
    testWidgets('logging in to an account with no password offers set-up', (
      tester,
    ) async {
      when(
        () => auth.logIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthFailure(AuthFailureCode.passwordNotSet));
      await tester.pumpApp(const LoginPage(), authRepository: auth);
      await tester.enterText(_input('login_email'), 'asha@example.com');
      await tester.enterText(_input('login_password'), 'guess');
      await tester.tapKey('login_submit');
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Your account was set up for you. Create a password to log in.',
        ),
        findsOneWidget,
      );
      await tester.tapKey('login_set_up_now');
      await tester.pumpAndSettle();
      expect(
        find.text('route:/forgot?email=asha%40example.com&setup=1'),
        findsOneWidget,
      );
    });

    testWidgets('set-up wording, then back to log in with a message', (
      tester,
    ) async {
      when(() => auth.requestPasswordReset(email: any(named: 'email')))
          .thenAnswer((_) async {});
      await tester.pumpApp(
        const ForgotPasswordPage(initialEmail: 'asha@example.com', setup: true),
        authRepository: auth,
      );
      expect(find.text('Set up your account'), findsOneWidget);
      await tester.tapKey('forgot_submit');
      await tester.pumpAndSettle();
      expect(
        find.text('route:/reset?email=asha%40example.com&setup=1'),
        findsOneWidget,
      );
    });

    testWidgets('creating the password is worded for set-up', (tester) async {
      await tester.pumpApp(
        const ResetPasswordPage(email: 'asha@example.com', setup: true),
        authRepository: auth,
      );
      expect(find.text('Create your password'), findsOneWidget);
      expect(find.text("You'll log in with asha@example.com"), findsOneWidget);
    });
  });

  testWidgets('auth screens meet tap target and label guidelines', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    // A typical phone: 360 x 780 logical pixels.
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    for (final page in const <Widget>[
      WelcomePage(),
      LoginPage(),
      SignupPage(),
      VerifyEmailPage(email: 'a@example.com'),
      ForgotPasswordPage(),
      ResetPasswordPage(email: 'a@example.com'),
    ]) {
      await tester.pumpApp(page, authRepository: auth);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    }
    handle.dispose();
  });
}
