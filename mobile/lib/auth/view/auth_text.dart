import 'package:solacliq/auth/data/account.dart';
import 'package:solacliq/auth/data/auth_failure.dart';
import 'package:solacliq/l10n/l10n.dart';

/// Field checks run before any request, so obvious mistakes never wait on
/// the network. The server checks again.
abstract final class AuthValidators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _code = RegExp(r'^\d{6}$');

  static String? name(String value, AppLocalizations l10n) =>
      value.trim().isEmpty ? l10n.errorRequired(l10n.fieldName) : null;

  static String? email(String value, AppLocalizations l10n) {
    final v = value.trim();
    if (v.isEmpty) return l10n.errorRequired(l10n.fieldEmail);
    return _email.hasMatch(v) ? null : l10n.errorEmail;
  }

  /// For log in: anything non-empty, since old passwords may predate rules.
  static String? existingPassword(String value, AppLocalizations l10n) =>
      value.isEmpty ? l10n.errorRequired(l10n.fieldPassword) : null;

  static String? newPassword(String value, AppLocalizations l10n) {
    if (value.isEmpty) return l10n.errorRequired(l10n.fieldPassword);
    return value.length < 8 ? l10n.errorPasswordShort : null;
  }

  static String? code(String value, AppLocalizations l10n) =>
      _code.hasMatch(value.trim()) ? null : l10n.errorCode;
}

extension AuthFailureText on AuthFailureCode {
  String message(AppLocalizations l10n) => switch (this) {
    AuthFailureCode.invalidCredentials => l10n.failInvalidCredentials,
    AuthFailureCode.emailUnverified => l10n.failEmailUnverified,
    AuthFailureCode.codeInvalid => l10n.failCodeInvalid,
    AuthFailureCode.passwordNotSet => l10n.failPasswordNotSet,
    AuthFailureCode.codeExpired => l10n.failCodeExpired,
    AuthFailureCode.tooManyAttempts => l10n.failTooManyAttempts,
    AuthFailureCode.passwordTooWeak => l10n.failPasswordTooWeak,
    AuthFailureCode.sessionExpired => l10n.failSessionExpired,
    AuthFailureCode.validation => l10n.failValidation,
    AuthFailureCode.network => l10n.failNetwork,
    AuthFailureCode.unknown => l10n.failUnknown,
  };
}

extension OrgRoleText on OrgRole {
  String label(AppLocalizations l10n) => switch (this) {
    OrgRole.orgAdmin => l10n.roleOrgAdmin,
    OrgRole.worker => l10n.roleWorker,
    OrgRole.agent => l10n.roleAgent,
  };
}

extension OrgStatusText on OrgStatus {
  String label(AppLocalizations l10n) => switch (this) {
    OrgStatus.pending => l10n.orgPending,
    OrgStatus.active => l10n.orgActive,
    OrgStatus.suspended => l10n.orgSuspended,
  };
}
