//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

// ignore: unused_import
import 'dart:convert';

import 'package:api_client/src/deserialize.dart';
import 'package:dio/dio.dart';

import 'package:api_client/src/model/problem.dart';
import 'package:api_client/src/model/upload.dart';
import 'package:api_client/src/model/upload_create.dart';

class UploadsApi {
  final Dio _dio;

  const UploadsApi(this._dio);

  /// Get a presigned URL to upload one file for this company
  /// The app PUTs the file to &#x60;url&#x60; with &#x60;headers&#x60;, then sends &#x60;upload_id&#x60; with the record it belongs to, in the same company. Every file belongs to one company: an upload made here can only be attached to this company&#39;s records, and is stored under the company&#39;s own prefix. URLs expire after 15 minutes. Sample data uses a &#x60;.invalid&#x60; host, which the development app treats as uploaded.
  ///
  /// Parameters:
  /// * [orgId] - The org the request is for; the caller needs a membership in it. Every `/orgs/{org_id}/...` request answers 403 with `org.not_member` (no membership, or it was removed), `org.role_not_allowed` (the endpoint is for another role), `org.pending` (MarkCliq hasn't approved the company yet), `org.suspended` or `org.rejected`. A company that isn't active gives its members none of its data, only its name and status in `/me`, so the app shows a message.
  /// * [uploadCreate]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [Upload] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<Upload>> createUpload({
    required String orgId,
    required UploadCreate uploadCreate,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/orgs/{org_id}/uploads'.replaceAll(
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
      _bodyData = jsonEncode(uploadCreate);
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

    Upload? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<Upload, Upload>(rawData, 'Upload', growable: true);
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<Upload>(
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
