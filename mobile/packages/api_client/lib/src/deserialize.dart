import 'package:api_client/src/model/add_member_request.dart';
import 'package:api_client/src/model/email_request.dart';
import 'package:api_client/src/model/health.dart';
import 'package:api_client/src/model/login_request.dart';
import 'package:api_client/src/model/login_response.dart';
import 'package:api_client/src/model/me.dart';
import 'package:api_client/src/model/member.dart';
import 'package:api_client/src/model/member_page.dart';
import 'package:api_client/src/model/membership.dart';
import 'package:api_client/src/model/membership_org.dart';
import 'package:api_client/src/model/page_info.dart';
import 'package:api_client/src/model/problem.dart';
import 'package:api_client/src/model/problem_errors_inner.dart';
import 'package:api_client/src/model/refresh_request.dart';
import 'package:api_client/src/model/reset_password_request.dart';
import 'package:api_client/src/model/signup_request.dart';
import 'package:api_client/src/model/token_pair.dart';
import 'package:api_client/src/model/verify_email_request.dart';

final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

ReturnType deserialize<ReturnType, BaseType>(
  dynamic value,
  String targetType, {
  bool growable = true,
}) {
  switch (targetType) {
    case 'String':
      return '$value' as ReturnType;
    case 'int':
      return (value is int ? value : int.parse('$value')) as ReturnType;
    case 'bool':
      if (value is bool) {
        return value as ReturnType;
      }
      final valueString = '$value'.toLowerCase();
      return (valueString == 'true' || valueString == '1') as ReturnType;
    case 'double':
      return (value is double ? value : double.parse('$value')) as ReturnType;
    case 'AddMemberRequest':
      return AddMemberRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'EmailRequest':
      return EmailRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Health':
      return Health.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'LoginRequest':
      return LoginRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'LoginResponse':
      return LoginResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Me':
      return Me.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Member':
      return Member.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'MemberPage':
      return MemberPage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'MemberStatus':
    case 'Membership':
      return Membership.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'MembershipOrg':
      return MembershipOrg.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'OrgStatus':
    case 'PageInfo':
      return PageInfo.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Problem':
      return Problem.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ProblemErrorsInner':
      return ProblemErrorsInner.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'RefreshRequest':
      return RefreshRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ResetPasswordRequest':
      return ResetPasswordRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Role':
    case 'SignupRequest':
      return SignupRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'TokenPair':
      return TokenPair.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'VerifyEmailRequest':
      return VerifyEmailRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    default:
      RegExpMatch? match;

      if (value is List && (match = _regList.firstMatch(targetType)) != null) {
        targetType = match![1]!; // ignore: parameter_assignments
        return value
                .map<BaseType>(
                  (dynamic v) => deserialize<BaseType, BaseType>(
                    v,
                    targetType,
                    growable: growable,
                  ),
                )
                .toList(growable: growable)
            as ReturnType;
      }
      if (value is Set && (match = _regSet.firstMatch(targetType)) != null) {
        targetType = match![1]!; // ignore: parameter_assignments
        return value
                .map<BaseType>(
                  (dynamic v) => deserialize<BaseType, BaseType>(
                    v,
                    targetType,
                    growable: growable,
                  ),
                )
                .toSet()
            as ReturnType;
      }
      if (value is Map && (match = _regMap.firstMatch(targetType)) != null) {
        targetType = match![1]!.trim(); // ignore: parameter_assignments
        return Map<String, BaseType>.fromIterables(
          value.keys as Iterable<String>,
          value.values.map(
            (dynamic v) => deserialize<BaseType, BaseType>(
              v,
              targetType,
              growable: growable,
            ),
          ),
        ) as ReturnType;
      }
      break;
  }
  throw Exception('Cannot deserialize');
}
