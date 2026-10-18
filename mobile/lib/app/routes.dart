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

  static String loginAfterReset(String email) => Uri(
    path: login,
    queryParameters: {'email': email, 'notice': 'reset'},
  ).toString();

  static String forgotPassword(String email) => Uri(
    path: forgot,
    queryParameters: email.isEmpty ? null : {'email': email},
  ).toString();

  static String resetPassword(String email) =>
      Uri(path: reset, queryParameters: {'email': email}).toString();
}
