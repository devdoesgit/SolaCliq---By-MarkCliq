//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

// ignore: unused_import
import 'dart:convert';

import 'package:api_client/src/deserialize.dart';
import 'package:dio/dio.dart';

import 'package:api_client/src/model/add_member_request.dart';
import 'package:api_client/src/model/member.dart';
import 'package:api_client/src/model/member_page.dart';
import 'package:api_client/src/model/member_update.dart';
import 'package:api_client/src/model/problem.dart';
import 'package:api_client/src/model/role.dart';

class TeamApi {
  final Dio _dio;

  const TeamApi(this._dio);

  /// Add a worker or agent
  /// Org admin only. If the email has no account, one is created with no password and a set-up email is sent (the person then uses \&quot;Set up your account\&quot;, F1). If it has an account, only a membership is added and the person is emailed that they were added. One role per person per org: &#x60;member.already_in_org&#x60; (409) otherwise. The role must be &#x60;worker&#x60; or &#x60;agent&#x60;: &#x60;member.role_not_allowed&#x60; (422). Agents need a &#x60;pay_type&#x60; (&#x60;member.pay_type_required&#x60;, 422) and other roles can&#39;t have one (&#x60;member.pay_type_not_allowed&#x60;, 422). Someone removed earlier can be added again: their membership comes back with the new role and pay type.
  ///
  /// Parameters:
  /// * [orgId] - The org the request is for; the caller needs a membership in it. Every `/orgs/{org_id}/...` request answers 403 with `org.not_member` (no membership, or it was removed), `org.role_not_allowed` (the endpoint is for another role), `org.pending` (MarkCliq hasn't approved the company yet), `org.suspended` or `org.rejected`. A company that isn't active gives its members none of its data, only its name and status in `/me`, so the app shows a message.
  /// * [addMemberRequest]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [Member] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<Member>> addMember({
    required String orgId,
    required AddMemberRequest addMemberRequest,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/orgs/{org_id}/members'.replaceAll(
      '{'
      r'org_id'
      '}',
      orgId.toString(),
    );
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{...?headers},
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'apiKey',
            'name': 'cookie',
            'keyName': 'solacliq_session',
            'where': '',
          },
          {'type': 'http', 'scheme': 'bearer', 'name': 'bearer'},
        ],
        ...?extra,
      },
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      _bodyData = jsonEncode(addMemberRequest);
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _options.compose(_dio.options, _path),
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    final _response = await _dio.request<Object>(
      _path,
      data: _bodyData,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    Member? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<Member, Member>(rawData, 'Member', growable: true);
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<Member>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// The org&#39;s admin, workers and agents
  /// Org admin only. Used by the admin website&#39;s team page.
  ///
  /// Parameters:
  /// * [orgId] - The org the request is for; the caller needs a membership in it. Every `/orgs/{org_id}/...` request answers 403 with `org.not_member` (no membership, or it was removed), `org.role_not_allowed` (the endpoint is for another role), `org.pending` (MarkCliq hasn't approved the company yet), `org.suspended` or `org.rejected`. A company that isn't active gives its members none of its data, only its name and status in `/me`, so the app shows a message.
  /// * [cursor] - Opaque cursor from the previous page's `next_cursor`.
  /// * [limit] - Page size.
  /// * [role]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [MemberPage] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<MemberPage>> listMembers({
    required String orgId,
    String? cursor,
    int? limit = 25,
    Role? role,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/orgs/{org_id}/members'.replaceAll(
      '{'
      r'org_id'
      '}',
      orgId.toString(),
    );
    final _options = Options(
      method: r'GET',
      headers: <String, dynamic>{...?headers},
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'apiKey',
            'name': 'cookie',
            'keyName': 'solacliq_session',
            'where': '',
          },
          {'type': 'http', 'scheme': 'bearer', 'name': 'bearer'},
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _queryParameters = <String, dynamic>{
      if (cursor != null) r'cursor': cursor,
      if (limit != null) r'limit': limit,
      if (role != null) r'role': role,
    };

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    MemberPage? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<MemberPage, MemberPage>(
              rawData,
              'MemberPage',
              growable: true,
            );
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<MemberPage>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// Remove a worker or agent from the org
  /// Org admin only. Ends the membership, not the account: it is marked removed (kept, not deleted), drops out of the member list and the person&#39;s &#x60;/me&#x60;, and their requests to this org get 403 &#x60;org.not_member&#x60; at once. The org admin can&#39;t be removed (&#x60;member.cannot_remove_admin&#x60;, 422). Their past records (jobs, expenses, customers) stay with the org.
  ///
  /// Parameters:
  /// * [orgId] - The org the request is for; the caller needs a membership in it. Every `/orgs/{org_id}/...` request answers 403 with `org.not_member` (no membership, or it was removed), `org.role_not_allowed` (the endpoint is for another role), `org.pending` (MarkCliq hasn't approved the company yet), `org.suspended` or `org.rejected`. A company that isn't active gives its members none of its data, only its name and status in `/me`, so the app shows a message.
  /// * [userId]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future]
  /// Throws [DioException] if API call or serialization fails
  Future<Response<void>> removeMember({
    required String orgId,
    required String userId,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/orgs/{org_id}/members/{user_id}'
        .replaceAll(
          '{'
          r'org_id'
          '}',
          orgId.toString(),
        )
        .replaceAll(
          '{'
          r'user_id'
          '}',
          userId.toString(),
        );
    final _options = Options(
      method: r'DELETE',
      headers: <String, dynamic>{...?headers},
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'apiKey',
            'name': 'cookie',
            'keyName': 'solacliq_session',
            'where': '',
          },
          {'type': 'http', 'scheme': 'bearer', 'name': 'bearer'},
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    return _response;
  }

  /// Send a member&#39;s invite again
  /// Org admin only (F21). For a member who hasn&#39;t set a password yet: the same email as when they were added. 409 &#x60;member.already_set_up&#x60; once they have one. At most 3 an hour per address (429 &#x60;auth.too_many_attempts&#x60;).
  ///
  /// Parameters:
  /// * [orgId] - The org the request is for; the caller needs a membership in it. Every `/orgs/{org_id}/...` request answers 403 with `org.not_member` (no membership, or it was removed), `org.role_not_allowed` (the endpoint is for another role), `org.pending` (MarkCliq hasn't approved the company yet), `org.suspended` or `org.rejected`. A company that isn't active gives its members none of its data, only its name and status in `/me`, so the app shows a message.
  /// * [userId]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future]
  /// Throws [DioException] if API call or serialization fails
  Future<Response<void>> resendInvite({
    required String orgId,
    required String userId,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/orgs/{org_id}/members/{user_id}/invite'
        .replaceAll(
          '{'
          r'org_id'
          '}',
          orgId.toString(),
        )
        .replaceAll(
          '{'
          r'user_id'
          '}',
          userId.toString(),
        );
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{...?headers},
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'apiKey',
            'name': 'cookie',
            'keyName': 'solacliq_session',
            'where': '',
          },
          {'type': 'http', 'scheme': 'bearer', 'name': 'bearer'},
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    return _response;
  }

  /// Change a worker&#39;s or agent&#39;s role or pay type
  /// Org admin only (F21). &#x60;pay_type&#x60; (agents) applies from now on: customers already registered keep their commission. &#x60;role&#x60; between &#x60;worker&#x60; and &#x60;agent&#x60; only when nothing is open in the old role (409 &#x60;member.has_open_work&#x60;, with what&#39;s open): an installer&#39;s tasks assigned, in review or sent back; an agent&#39;s customers in review or with them, commissions not yet paid, leads new or contacted. Becoming an agent needs &#x60;pay_type&#x60;. The admin&#39;s own membership can&#39;t change (422 &#x60;member.cannot_change_admin&#x60;). The person&#39;s name, phone and email are theirs to edit, not here.
  ///
  /// Parameters:
  /// * [orgId] - The org the request is for; the caller needs a membership in it. Every `/orgs/{org_id}/...` request answers 403 with `org.not_member` (no membership, or it was removed), `org.role_not_allowed` (the endpoint is for another role), `org.pending` (MarkCliq hasn't approved the company yet), `org.suspended` or `org.rejected`. A company that isn't active gives its members none of its data, only its name and status in `/me`, so the app shows a message.
  /// * [userId]
  /// * [memberUpdate]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [Member] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<Member>> updateMember({
    required String orgId,
    required String userId,
    required MemberUpdate memberUpdate,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/orgs/{org_id}/members/{user_id}'
        .replaceAll(
          '{'
          r'org_id'
          '}',
          orgId.toString(),
        )
        .replaceAll(
          '{'
          r'user_id'
          '}',
          userId.toString(),
        );
    final _options = Options(
      method: r'PATCH',
      headers: <String, dynamic>{...?headers},
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'apiKey',
            'name': 'cookie',
            'keyName': 'solacliq_session',
            'where': '',
          },
          {'type': 'http', 'scheme': 'bearer', 'name': 'bearer'},
        ],
        ...?extra,
      },
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      _bodyData = jsonEncode(memberUpdate);
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _options.compose(_dio.options, _path),
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    final _response = await _dio.request<Object>(
      _path,
      data: _bodyData,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    Member? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<Member, Member>(rawData, 'Member', growable: true);
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<Member>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }
}
