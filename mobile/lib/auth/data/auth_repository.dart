import 'dart:async';

import 'package:api_client/api_client.dart' as api;
import 'package:dio/dio.dart';
import 'package:solacliq/auth/data/account.dart';
import 'package:solacliq/auth/data/auth_failure.dart';
import 'package:solacliq/auth/data/auth_status.dart';
import 'package:solacliq/auth/data/token_store.dart';

/// Accounts and the app's login: the only place that knows about tokens.
///
/// Every method that talks to the API throws [AuthFailure] on failure.
/// [statusChanges] tells the app when someone signs in or out. Call
/// [dispose] when the app closes.
class AuthRepository {
  new({
    required api.AuthApi authApi,
    required this._store,
    DateTime Function()? clock,
  }) : _api = authApi,
       _now = clock ?? DateTime.now;

  final api.AuthApi _api;
  final TokenStore _store;
  final DateTime Function() _now;
  final _statusController = StreamController<AuthStatus>.broadcast();

  AuthStatus _status = const AuthUnknown();
  StoredSession? _session;
  Future<String?>? _refreshing;
  DateTime? _accountCheckedAt;

  /// Refresh a little before the access token runs out.
  static const _expiryMargin = Duration(seconds: 30);

  /// How often [refreshAccount] may ask the server again.
  static const _accountMaxAge = Duration(minutes: 1);

  AuthStatus get status => _status;
  Stream<AuthStatus> get statusChanges => _statusController.stream;

  /// Reads the stored login at start-up. Opens with the last known account
  /// straight away (installers often have no signal), then checks it with
  /// the server.
  Future<void> restore() async {
    final stored = await _store.read();
    if (stored == null) return _emit(const AuthUnauthenticated());
    _session = stored;
    final cached = stored.accountJson;
    if (cached != null) {
      _emit(AuthAuthenticated(_toAccount(api.Me.fromJson(cached))));
    }
    try {
      await _loadAccount();
    } on AuthFailure catch (failure) {
      // Only the server rejecting the login ends it. No signal or a server
      // error keeps the person signed in with the cached account.
      if (_isRejected(failure)) return await _endSession();
      if (cached == null) _emit(const AuthUnauthenticated());
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) => _call(
    () => _api.signup(
      signupRequest: api.SignupRequest(
        name: name,
        email: email,
        password: password,
        phone: phone,
      ),
    ),
  );

  Future<void> verifyEmail({required String email, required String code}) =>
      _call(
        () => _api.verifyEmail(
          verifyEmailRequest: api.VerifyEmailRequest(email: email, code: code),
        ),
      );

  Future<void> resendVerification({required String email}) => _call(
    () => _api.resendVerification(emailRequest: api.EmailRequest(email: email)),
  );

  Future<void> requestPasswordReset({required String email}) => _call(
    () => _api.forgotPassword(emailRequest: api.EmailRequest(email: email)),
  );

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => _call(
    () => _api.resetPassword(
      resetPasswordRequest: api.ResetPasswordRequest(
        email: email,
        code: code,
        newPassword: newPassword,
      ),
    ),
  );

  Future<void> logIn({required String email, required String password}) async {
    final response = await _call(
      () => _api.login(
        loginRequest: api.LoginRequest(
          email: email,
          password: password,
          client: api.LoginRequestClientEnum.app,
        ),
      ),
    );
    final body = response.data;
    final tokens = body?.tokens;
    if (body == null || tokens == null) {
      throw const AuthFailure(AuthFailureCode.unknown);
    }
    _session = _sessionFrom(tokens).withAccount(_json(body.user));
    _accountCheckedAt = _now();
    await _store.write(_session!);
    _emit(AuthAuthenticated(_toAccount(body.user)));
  }

  /// Re-reads the account, so a new membership, a removal or a suspended
  /// company shows without logging out. At most once a minute unless
  /// [force]. No signal or a server error is ignored; only the server
  /// rejecting the login ends it.
  Future<void> refreshAccount({bool force = false}) async {
    if (_session == null) return;
    final checked = _accountCheckedAt;
    final now = _now();
    if (!force && checked != null && now.difference(checked) < _accountMaxAge) {
      return;
    }
    _accountCheckedAt = now;
    try {
      await _loadAccount();
    } on AuthFailure catch (failure) {
      if (_isRejected(failure)) await _endSession();
    }
  }

  /// Takes an updated account the server returned (after accepting an
  /// invite, say), so the app reflects it at once.
  Future<void> applyAccount(api.Me me) async {
    final session = _session;
    if (session == null) return;
    _accountCheckedAt = _now();
    _session = session.withAccount(_json(me));
    await _store.write(_session!);
    _emit(AuthAuthenticated(_toAccount(me)));
  }

  /// Ends this login. Works offline: the server call is best effort.
  Future<void> logOut() async {
    try {
      await _api.logout();
    } on DioException {
      // The server forgets the session when it expires anyway.
    }
    await _endSession();
  }

  /// A usable access token, refreshing it first when it has run out.
  /// Null when nobody is signed in.
  Future<String?> accessToken() async {
    final session = _session;
    if (session == null) return null;
    final fresh = session.accessExpiresAt.isAfter(_now().add(_expiryMargin));
    return fresh ? session.accessToken : await refreshAccessToken();
  }

  /// Swaps the refresh token for a new pair. Concurrent callers share one
  /// request. Returns null when there is no login to refresh, or the server
  /// can't be reached; a rejected refresh token signs the person out.
  Future<String?> refreshAccessToken() =>
      _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<String?> _refresh() async {
    final session = _session;
    if (session == null) return null;
    try {
      final response = await _api.refreshSession(
        refreshRequest: api.RefreshRequest(refreshToken: session.refreshToken),
      );
      final tokens = response.data;
      if (tokens == null) return null;
      final updated = _sessionFrom(tokens);
      _session = session.accountJson == null
          ? updated
          : updated.withAccount(session.accountJson!);
      await _store.write(_session!);
      return _session!.accessToken;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) await _endSession();
      return null;
    }
  }

  Future<void> _loadAccount() async {
    final response = await _call(_api.getMe);
    final me = response.data;
    final session = _session;
    if (me == null || session == null) return;
    _accountCheckedAt = _now();
    _session = session.withAccount(_json(me));
    await _store.write(_session!);
    _emit(AuthAuthenticated(_toAccount(me)));
  }

  /// The server refused the login itself, as opposed to no signal or a
  /// server error.
  static bool _isRejected(AuthFailure failure) =>
      failure.code == AuthFailureCode.sessionExpired ||
      failure.code == AuthFailureCode.invalidCredentials;

  Future<void> _endSession() async {
    _session = null;
    _accountCheckedAt = null;
    await _store.clear();
    _emit(const AuthUnauthenticated());
  }

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw AuthFailure.fromDio(error);
    }
  }

  StoredSession _sessionFrom(api.TokenPair tokens) => StoredSession(
    accessToken: tokens.accessToken,
    refreshToken: tokens.refreshToken,
    accessExpiresAt: _now().add(Duration(seconds: tokens.accessExpiresIn)),
  );

  void _emit(AuthStatus status) {
    if (status == _status || _statusController.isClosed) return;
    _status = status;
    _statusController.add(status);
  }

  static Map<String, Object?> _json(api.Me me) =>
      Map<String, Object?>.from(me.toJson());

  static Account _toAccount(api.Me me) => Account(
    id: me.id,
    name: me.name,
    email: me.email,
    phone: me.phone,
    isPlatformAdmin: me.isPlatformAdmin,
    memberships: [
      for (final m in me.memberships)
        AccountMembership(
          orgId: m.org.id,
          orgName: m.org.name,
          orgStatus: switch (m.org.status) {
            api.OrgStatus.pending => OrgStatus.pending,
            api.OrgStatus.active => OrgStatus.active,
            api.OrgStatus.suspended => OrgStatus.suspended,
          },
          role: switch (m.role) {
            api.Role.orgAdmin => OrgRole.orgAdmin,
            api.Role.worker => OrgRole.worker,
            api.Role.agent => OrgRole.agent,
            api.Role.customer => OrgRole.customer,
          },
          payType: switch (m.payType) {
            api.MembershipPayTypeEnum.commission => PayType.commission,
            api.MembershipPayTypeEnum.salary => PayType.salary,
            _ => m.role == api.Role.agent ? PayType.commission : null,
          },
          orgPhone: m.org.phone,
        ),
    ],
  );

  Future<void> dispose() => _statusController.close();
}
