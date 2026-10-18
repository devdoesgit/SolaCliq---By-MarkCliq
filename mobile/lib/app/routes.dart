/// Every route path, and helpers that build them with their parameters.
abstract final class AppRoutes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const login = '/login';
  static const signup = '/signup';
  static const verify = '/verify';
  static const forgot = '/forgot';
  static const reset = '/reset';
  static const account = '/account';
  static const gallery = '/gallery';

  /// Reachable without signing in; signed-in people are sent home.
  static const Set<String> public = {
    welcome,
    login,
    signup,
    verify,
    forgot,
    reset,
  };

  static String verifyEmail(String email) =>
      Uri(path: verify, queryParameters: {'email': email}).toString();

  static String loginAfterVerify(String email) => Uri(
    path: login,
    queryParameters: {'email': email, 'notice': 'verified'},
  ).toString();

  static String loginAfterReset(String email, {bool setup = false}) => Uri(
    path: login,
    queryParameters: {'email': email, 'notice': setup ? 'setup' : 'reset'},
  ).toString();

  /// The code request. With [setup] it is worded as setting up an account
  /// that someone else created (no password yet).
  static String forgotPassword(String email, {bool setup = false}) => Uri(
    path: forgot,
    queryParameters: {
      if (email.isNotEmpty) 'email': email,
      if (setup) 'setup': '1',
    },
  ).toString();

  static String resetPassword(String email, {bool setup = false}) => Uri(
    path: reset,
    queryParameters: {'email': email, if (setup) 'setup': '1'},
  ).toString();
}
