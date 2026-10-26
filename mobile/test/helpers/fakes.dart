import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/workspace/data/workspace_store.dart';

/// Keeps the login in memory instead of the phone's secure storage.
class FakeTokenStore implements TokenStore {
  new([this.session]);

  StoredSession? session;
  int writes = 0;

  @override
  Future<StoredSession?> read() async => session;

  @override
  Future<void> write(StoredSession session) async {
    writes++;
    this.session = session;
  }

  @override
  Future<void> clear() async => session = null;
}

/// Remembers the workspace in memory.
class FakeWorkspaceStore implements WorkspaceStore {
  new([this.id]);

  String? id;

  @override
  Future<String?> read() async => id;

  @override
  Future<void> write(String workspaceId) async => id = workspaceId;

  @override
  Future<void> clear() async => id = null;
}

/// A Dio adapter that answers from [handler], with no network.
class FakeAdapter implements HttpClientAdapter {
  new(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(int status, Object? body) => ResponseBody.fromString(
  body == null ? '' : jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [
      if (status >= 400)
        'application/problem+json'
      else
        Headers.jsonContentType,
    ],
  },
);

Map<String, Object?> problem(int status, String code) => {
  'type': 'about:blank',
  'title': code,
  'status': status,
  'code': code,
};

Map<String, Object?> meJson({
  String name = 'Test Person',
  List<Map<String, Object?>> memberships = const [],
}) => {
  'id': '0192a000-0000-7000-8000-000000000001',
  'name': name,
  'email': 'person@example.com',
  'email_verified': true,
  'is_platform_admin': false,
  'memberships': memberships,
};

Map<String, Object?> tokensJson({
  String access = 'access-1',
  String refresh = 'refresh-1',
  int expiresIn = 900,
}) => {
  'access_token': access,
  'refresh_token': refresh,
  'access_expires_in': expiresIn,
  'token_type': 'Bearer',
};

Map<String, Object?> membershipJson({
  String orgId = '0192a000-0000-7000-8000-0000000000a1',
  String orgName = 'Example Solar',
  String status = 'active',
  String role = 'worker',
}) => {
  'org': {'id': orgId, 'name': orgName, 'status': status},
  'role': role,
};

AccountMembership testMembership({
  String orgId = 'o1',
  String orgName = 'Example Solar',
  OrgStatus status = OrgStatus.active,
  OrgRole role = OrgRole.worker,
  PayType? payType,
}) => AccountMembership(
  orgId: orgId,
  orgName: orgName,
  orgStatus: status,
  role: role,
  payType: payType,
  orgPhone: '9814000000',
);

Account testAccount({
  String id = '1',
  String name = 'Asha',
  List<AccountMembership> memberships = const [],
}) => Account(
  id: id,
  name: name,
  email: 'asha@example.com',
  isPlatformAdmin: false,
  memberships: memberships,
);
