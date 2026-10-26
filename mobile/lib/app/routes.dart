/// Every route path, and helpers that build them with their parameters.
abstract final class AppRoutes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const intro = '/intro';
  static const login = '/login';
  static const signup = '/signup';
  static const verify = '/verify';
  static const forgot = '/forgot';
  static const reset = '/reset';
  static const requestAccess = '/request-access';
  static const requestSent = '/request-access/sent';
  static const home = '/home';
  static const useWebsite = '/use-website';
  static const quote = '/quote';
  static const quoteSent = '/quote/sent';
  static const invite = '/invite';
  static const expense = '/expense';
  static const expenseSent = '/expense/sent';
  static const addCustomer = '/customers/new';
  static const addCustomerSent = '/customers/new/sent';
  static const tasks = '/tasks';
  static const expenses = '/expenses';
  static const notifications = '/notifications';
  static const gallery = '/gallery';
  static const customers = '/customers';
  static const settings = '/settings';
  static const details = '/details';
  static const bank = '/bank';
  static const documents = '/documents';
  static const learn = '/learn';
  static const profile = '/profile';

  /// Reachable without signing in; signed-in people are sent home.
  static const Set<String> public = {
    welcome,
    intro,
    login,
    signup,
    verify,
    forgot,
    reset,
    requestAccess,
    requestSent,
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

  static String requestSentTo({
    required String company,
    required String email,
  }) => Uri(
    path: requestSent,
    queryParameters: {'company': company, 'email': email},
  ).toString();

  static String inviteDetail(String id) => '$invite/$id';

  static String task(String id) => '$tasks/$id';

  /// The proof camera for a task, at [slot] or the first missing photo.
  /// [fromTab]: opened from the tab bar, it shows the task when done.
  static String taskCamera(String id, {String? slot, bool fromTab = false}) =>
      Uri(
        path: '$tasks/$id/camera',
        queryParameters: {'slot': ?slot, if (fromTab) 'tab': '1'},
      ).toString();

  static String taskHistory(String id) => '$tasks/$id/history';

  static String expenseDetail(String id) => '$expenses/$id';

  static String customer(String id) => '$customers/$id';

  /// Send a clearer copy of the document the admin returned.
  static String customerFix(String id) => '$customers/$id/fix';
}
