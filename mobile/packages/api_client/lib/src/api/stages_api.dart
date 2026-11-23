//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

// ignore: unused_import
import 'dart:convert';

import 'package:api_client/src/deserialize.dart';
import 'package:dio/dio.dart';

import 'package:api_client/src/model/problem.dart';
import 'package:api_client/src/model/stage_list.dart';
import 'package:api_client/src/model/stage_template_set.dart';

class StagesApi {
  final Dio _dio;

  const StagesApi(this._dio);

  /// Change one stage&#39;s name and template
  /// Company admins only. Replaces the name, checklist and photos. Blank items are dropped and repeats kept once. Tasks already made keep what they were made with.
  ///
  /// Parameters:
  /// * [orgId] - The org the request is for; the caller needs a membership in it. Every `/orgs/{org_id}/...` request answers 403 with `org.not_member` (no membership, or it was removed), `org.role_not_allowed` (the endpoint is for another role), `org.pending` (MarkCliq hasn't approved the company yet), `org.suspended` or `org.rejected`. A company that isn't active gives its members none of its data, only its name and status in `/me`, so the app shows a message.
  /// * [index] - The stage, from 1 to 7.
  /// * [stageTemplateSet]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [StageList] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<StageList>> adminSetStage({
    required String orgId,
    required int index,
    required StageTemplateSet stageTemplateSet,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/orgs/{org_id}/admin/stages/{index}'
        .replaceAll(
          '{'
          r'org_id'
          '}',
          orgId.toString(),
        )
        .replaceAll(
          '{'
          r'index'
          '}',
          index.toString(),
        );
    final _options = Options(
      method: r'PUT',
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
      _bodyData = jsonEncode(stageTemplateSet);
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

    StageList? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<StageList, StageList>(
              rawData,
              'StageList',
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

    return Response<StageList>(
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

  /// The company&#39;s 7 install stages
  /// Any member. In order, with each stage&#39;s template: what a new task at that stage asks for. A stage the company hasn&#39;t changed has the standard name and an empty template.
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
  /// Returns a [Future] containing a [Response] with a [StageList] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<StageList>> listStages({
    required String orgId,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/orgs/{org_id}/stages'.replaceAll(
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

    StageList? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<StageList, StageList>(
              rawData,
              'StageList',
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

    return Response<StageList>(
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
