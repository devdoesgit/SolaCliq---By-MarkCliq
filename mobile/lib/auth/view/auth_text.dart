import 'package:solacliq/auth/data/account.dart';
import 'package:solacliq/auth/data/auth_failure.dart';
import 'package:solacliq/l10n/l10n.dart';

/// Field checks run before any request, so obvious mistakes never wait on
/// the network. The server checks again.
abstract final class AuthValidators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _code = RegExp(r'^\d{6}$');

  static String? name(String value, AppLocalizations l10n) =>
      value.trim().isEmpty ? l10n.errorNameRequired : null;

  static String? email(String value, AppLocalizations l10n) {
    final v = value.trim();
    if (v.isEmpty) return l10n.errorEmailRequired;
    return _email.hasMatch(v) ? null : l10n.errorEmail;
  }

  /// For log in: anything non-empty, since old passwords may predate rules.
  static String? existingPassword(String value, AppLocalizations l10n) =>
      value.isEmpty ? l10n.errorPasswordRequired : null;

  static final _digit = RegExp(r'\d');
  static final _mobile = RegExp(r'^[6-9]\d{9}$');

  static String? newPassword(String value, AppLocalizations l10n) {
    if (value.isEmpty) return l10n.errorPasswordRequired;
    if (value.length < 8) return l10n.errorPasswordShort;
    return _digit.hasMatch(value) ? null : l10n.errorPasswordNumber;
  }

  /// Whether [value] meets each new-password rule, for the live checklist.
  static ({bool length, bool number}) passwordRules(String value) =>
      (length: value.length >= 8, number: _digit.hasMatch(value));

  static String? confirmPassword(
    String value,
    String password,
    AppLocalizations l10n,
  ) => value == password ? null : l10n.errorPasswordsDiffer;

  /// Optional: empty is fine, otherwise a 10-digit Indian mobile.
  static String? optionalMobile(String value, AppLocalizations l10n) {
    final digits = value.replaceAll(RegExp(r'\s'), '');
    if (digits.isEmpty) return null;
    return _mobile.hasMatch(digits) ? null : l10n.errorPhone;
  }

  static String? mobile(String value, AppLocalizations l10n) {
    final digits = value.replaceAll(RegExp(r'\s'), '');
    return _mobile.hasMatch(digits) ? null : l10n.errorPhone;
  }

  static String? required(String value, String error) =>
      value.trim().isEmpty ? error : null;

  /// A mobile number's 10 digits, without spaces.
  static String digits(String value) => value.replaceAll(RegExp(r'\s'), '');

  static String? code(String value, AppLocalizations l10n) =>
      _code.hasMatch(value.trim()) ? null : l10n.errorCode;
}

extension AuthFailureText on AuthFailureCode {
  String message(AppLocalizations l10n) => switch (this) {
    AuthFailureCode.invalidCredentials => l10n.failInvalidCredentials,
    AuthFailureCode.codeInvalid => l10n.failCodeInvalid,
    AuthFailureCode.signupExpired => l10n.failSignupExpired,
    AuthFailureCode.passwordIncorrect => l10n.failPasswordIncorrect,
    AuthFailureCode.lastAdmin ||
    AuthFailureCode.platformAdmin => l10n.failAdminAccount,
    AuthFailureCode.codeExpired => l10n.failCodeExpired,
    AuthFailureCode.tooManyAttempts => l10n.failTooManyAttempts,
    AuthFailureCode.passwordTooWeak => l10n.failPasswordTooWeak,
    AuthFailureCode.sessionExpired => l10n.failSessionExpired,
    AuthFailureCode.validation => l10n.failValidation,
    AuthFailureCode.gstinInvalid => l10n.failGstinInvalid,
    AuthFailureCode.gstinTaken => l10n.failGstinTaken,
    AuthFailureCode.taskLocked => l10n.failTaskLocked,
    AuthFailureCode.taskIncomplete => l10n.failTaskIncomplete,
    AuthFailureCode.expenseLocked => l10n.failExpenseLocked,
    AuthFailureCode.registrationDuplicate => l10n.failRegistrationDuplicate,
    AuthFailureCode.registrationLocked => l10n.failRegistrationLocked,
    AuthFailureCode.uploadUnavailable => l10n.failUploadUnavailable,
    AuthFailureCode.uploadIncomplete => l10n.failUploadIncomplete,
    AuthFailureCode.installNotStarted => l10n.installSetUpTitle,
    AuthFailureCode.paymentNotDue => l10n.failPaymentNotDue,
    AuthFailureCode.attendanceAlreadyStarted => l10n.failAttendanceStarted,
    AuthFailureCode.attendanceAlreadyEnded => l10n.failAttendanceEnded,
    AuthFailureCode.attendanceNotStarted => l10n.failAttendanceNotStarted,
    AuthFailureCode.attendanceTooOld => l10n.failAttendanceTooOld,
    AuthFailureCode.attendanceNotTracked => l10n.failAttendanceNotTracked,
    AuthFailureCode.network => l10n.failNetwork,
    AuthFailureCode.unknown => l10n.failUnknown,
  };
}

extension OrgRoleText on OrgRole {
  String label(AppLocalizations l10n) => switch (this) {
    OrgRole.orgAdmin => l10n.roleOrgAdmin,
    OrgRole.worker => l10n.roleWorker,
    OrgRole.agent => l10n.roleAgent,
    OrgRole.customer => l10n.roleCustomer,
  };
}

extension OrgStatusText on OrgStatus {
  String label(AppLocalizations l10n) => switch (this) {
    OrgStatus.pending => l10n.orgPending,
    OrgStatus.active => l10n.orgActive,
    OrgStatus.suspended => l10n.orgSuspended,
    OrgStatus.rejected => l10n.orgRejected,
  };
}
