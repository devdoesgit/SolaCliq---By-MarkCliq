//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

// ignore: unused_import
import 'dart:convert';

import 'package:api_client/src/deserialize.dart';
import 'package:dio/dio.dart';

import 'package:api_client/src/model/lead.dart';
import 'package:api_client/src/model/lead_create.dart';
import 'package:api_client/src/model/lead_key_info.dart';
import 'package:api_client/src/model/lead_key_new.dart';
import 'package:api_client/src/model/lead_page.dart';
import 'package:api_client/src/model/lead_receipt.dart';
import 'package:api_client/src/model/lead_status.dart';
import 'package:api_client/src/model/lead_update.dart';
import 'package:api_client/src/model/problem.dart';

class LeadsApi {
  final Dio _dio;

  const LeadsApi(this._dio);

  /// Whether the company has a lead key
  /// Company admins only. Never the key itself: it&#39;s shown once, when made.
  ///
  /// Parameters:
  /// * [orgId] - The org the request is for; the caller needs a membership in it. Every `/orgs/{org_id}/...` request answers 403 with `org.not_member` (no membership, or it was removed), `org.role_not_allowed` (the endpoint is for another role), `org.pending` (MarkCliq hasn't approved the company yet), `org.suspended` or `org.rejected`. A company that isn't active gives its members none of its data, only its name and status in `/me`, so the app shows a message.
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [LeadKeyInfo] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<LeadKeyInfo>> adminGetLeadKey({
    required String orgId,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/orgs/{org_id}/admin/lead-key'.replaceAll(
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

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    LeadKeyInfo? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<LeadKeyInfo, LeadKeyInfo>(
              rawData,
              'LeadKeyInfo',
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

    return Response<LeadKeyInfo>(
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

  /// Make a new lead key
  /// Company admins only. Returns the key once. Any earlier key stops working at once.
  ///
  /// Parameters:
  /// * [orgId] - The org the request is for; the caller needs a membership in it. Every `/orgs/{org_id}/...` request answers 403 with `org.not_member` (no membership, or it was removed), `org.role_not_allowed` (the endpoint is for another role), `org.pending` (MarkCliq hasn't approved the company yet), `org.suspended` or `org.rejected`. A company that isn't active gives its members none of its data, only its name and status in `/me`, so the app shows a message.
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [LeadKeyNew] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<LeadKeyNew>> adminMakeLeadKey({
    required String orgId,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/orgs/{org_id}/admin/lead-key'.replaceAll(
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
      validateStatus: validateStatus,
    );

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    LeadKeyNew? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<LeadKeyNew, LeadKeyNew>(
              rawData,
              'LeadKeyNew',
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

    return Response<LeadKeyNew>(
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

  /// Send a lead to a company
  /// For a landing page&#39;s server, with the company&#39;s lead key as the bearer token (made in the website&#39;s Settings). Never call it from a browser: the key would be public. 401 &#x60;lead.bad_key&#x60; for a missing, wrong or replaced key. &#x60;consent&#x60; must be true (422 &#x60;lead.consent_required&#x60;). With an &#x60;external_id&#x60; already sent, the first lead comes back with 200 and nothing changes. At most 300 an hour per company (429 &#x60;auth.too_many_attempts&#x60;).
  ///
  /// Parameters:
  /// * [leadCreate]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [LeadReceipt] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<LeadReceipt>> createLead({
    required LeadCreate leadCreate,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/leads';
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{...?headers},
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {'type': 'http', 'scheme': 'bearer', 'name': 'leadKey'},
        ],
        ...?extra,
      },
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      _bodyData = jsonEncode(leadCreate);
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

    LeadReceipt? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<LeadReceipt, LeadReceipt>(
              rawData,
              'LeadReceipt',
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

    return Response<LeadReceipt>(
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

  /// Delete a lead for good
  /// Company admins only. For a person asking to be forgotten.
  ///
  /// Parameters:
  /// * [orgId] - The org the request is for; the caller needs a membership in it. Every `/orgs/{org_id}/...` request answers 403 with `org.not_member` (no membership, or it was removed), `org.role_not_allowed` (the endpoint is for another role), `org.pending` (MarkCliq hasn't approved the company yet), `org.suspended` or `org.rejected`. A company that isn't active gives its members none of its data, only its name and status in `/me`, so the app shows a message.
  /// * [leadId]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future]
  /// Throws [DioException] if API call or serialization fails
  Future<Response<void>> deleteLead({
    required String orgId,
    required String leadId,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/orgs/{org_id}/leads/{lead_id}'
        .replaceAll(
          '{'
          r'org_id'
          '}',
          orgId.toString(),
        )
        .replaceAll(
          '{'
          r'lead_id'
          '}',
          leadId.toString(),
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

  /// One lead, with everything the form sent
  /// Company admins, or the agent it&#39;s with (404 for anyone else).
  ///
  /// Parameters:
  /// * [orgId] - The org the request is for; the caller needs a membership in it. Every `/orgs/{org_id}/...` request answers 403 with `org.not_member` (no membership, or it was removed), `org.role_not_allowed` (the endpoint is for another role), `org.pending` (MarkCliq hasn't approved the company yet), `org.suspended` or `org.rejected`. A company that isn't active gives its members none of its data, only its name and status in `/me`, so the app shows a message.
  /// * [leadId]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [Lead] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<Lead>> getLead({
    required String orgId,
    required String leadId,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/orgs/{org_id}/leads/{lead_id}'
        .replaceAll(
          '{'
          r'org_id'
          '}',
          orgId.toString(),
        )
        .replaceAll(
          '{'
          r'lead_id'
          '}',
          leadId.toString(),
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

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    Lead? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<Lead, Lead>(rawData, 'Lead', growable: true);
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<Lead>(
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

  /// The company&#39;s leads, newest first
  /// Company admins only. &#x60;q&#x60; matches the name, phone, email or city.
  ///
  /// Parameters:
  /// * [orgId] - The org the request is for; the caller needs a membership in it. Every `/orgs/{org_id}/...` request answers 403 with `org.not_member` (no membership, or it was removed), `org.role_not_allowed` (the endpoint is for another role), `org.pending` (MarkCliq hasn't approved the company yet), `org.suspended` or `org.rejected`. A company that isn't active gives its members none of its data, only its name and status in `/me`, so the app shows a message.
  /// * [status]
  /// * [agentId] - Only the leads with this agent.
  /// * [q]
  /// * [cursor] - The previous page's `next_cursor`.
  /// * [limit]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [LeadPage] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<LeadPage>> listLeads({
    required String orgId,
    LeadStatus? status,
    String? agentId,
    String? q,
    String? cursor,
    int? limit = 25,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/orgs/{org_id}/leads'.replaceAll(
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
      if (status != null) r'status': status,
      if (agentId != null) r'agent_id': agentId,
      if (q != null) r'q': q,
      if (cursor != null) r'cursor': cursor,
      if (limit != null) r'limit': limit,
    };

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    LeadPage? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<LeadPage, LeadPage>(
              rawData,
              'LeadPage',
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

    return Response<LeadPage>(
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

  /// The leads handed to the caller, newest first
  /// Sales agents only.
  ///
  /// Parameters:
  /// * [orgId] - The org the request is for; the caller needs a membership in it. Every `/orgs/{org_id}/...` request answers 403 with `org.not_member` (no membership, or it was removed), `org.role_not_allowed` (the endpoint is for another role), `org.pending` (MarkCliq hasn't approved the company yet), `org.suspended` or `org.rejected`. A company that isn't active gives its members none of its data, only its name and status in `/me`, so the app shows a message.
  /// * [status]
  /// * [cursor] - The previous page's `next_cursor`.
  /// * [limit]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [LeadPage] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<LeadPage>> listMyLeads({
    required String orgId,
    LeadStatus? status,
    String? cursor,
    int? limit = 25,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/orgs/{org_id}/leads/mine'.replaceAll(
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
      if (status != null) r'status': status,
      if (cursor != null) r'cursor': cursor,
      if (limit != null) r'limit': limit,
    };

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    LeadPage? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<LeadPage, LeadPage>(
              rawData,
              'LeadPage',
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

    return Response<LeadPage>(
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

  /// Change a lead&#39;s status, note or agent
  /// Company admins: any field. &#x60;agent_id&#x60; hands it to a Sales Agent of the company (422 &#x60;lead.not_an_agent&#x60; otherwise), who is notified; null takes it back. The agent it&#39;s with: &#x60;status&#x60; and &#x60;note&#x60; only (403 &#x60;lead.admin_only&#x60; for &#x60;agent_id&#x60;). An empty note removes it.
  ///
  /// Parameters:
  /// * [orgId] - The org the request is for; the caller needs a membership in it. Every `/orgs/{org_id}/...` request answers 403 with `org.not_member` (no membership, or it was removed), `org.role_not_allowed` (the endpoint is for another role), `org.pending` (MarkCliq hasn't approved the company yet), `org.suspended` or `org.rejected`. A company that isn't active gives its members none of its data, only its name and status in `/me`, so the app shows a message.
  /// * [leadId]
  /// * [leadUpdate]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [Lead] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<Lead>> updateLead({
    required String orgId,
    required String leadId,
    required LeadUpdate leadUpdate,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/orgs/{org_id}/leads/{lead_id}'
        .replaceAll(
          '{'
          r'org_id'
          '}',
          orgId.toString(),
        )
        .replaceAll(
          '{'
          r'lead_id'
          '}',
          leadId.toString(),
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
      _bodyData = jsonEncode(leadUpdate);
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

    Lead? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<Lead, Lead>(rawData, 'Lead', growable: true);
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<Lead>(
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
