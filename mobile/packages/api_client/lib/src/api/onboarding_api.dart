//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

// ignore: unused_import
import 'dart:convert';

import 'package:api_client/src/deserialize.dart';
import 'package:dio/dio.dart';

import 'package:api_client/src/model/org_registration_create.dart';
import 'package:api_client/src/model/problem.dart';

class OnboardingApi {
  final Dio _dio;

  const OnboardingApi(this._dio);

  /// A solar company registers with SolaCliq
  /// Public. The server checks the details first: GSTIN format and checksum (&#x60;org.gstin_invalid&#x60;, 422), a GSTIN already registered and not rejected (&#x60;org.gstin_taken&#x60;, 409), and the usual field rules (&#x60;validation.failed&#x60;). PAN and state are taken from the GSTIN.  Then, in one transaction, it saves the company as &#x60;pending&#x60;, the owner&#39;s account (no password; an existing account with this email is used as it is) and their &#x60;org_admin&#x60; membership. MarkCliq is emailed to review it, and the owner is emailed that it arrived. A platform admin then approves or rejects it (&#x60;/platform/orgs/{org_id}/status&#x60;).
  ///
  /// Parameters:
  /// * [orgRegistrationCreate]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future]
  /// Throws [DioException] if API call or serialization fails
  Future<Response<void>> registerOrg({
    required OrgRegistrationCreate orgRegistrationCreate,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/org-registrations';
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{...?headers},
      extra: <String, dynamic>{'secure': <Map<String, String>>[], ...?extra},
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      _bodyData = jsonEncode(orgRegistrationCreate);
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

    return _response;
  }
}
