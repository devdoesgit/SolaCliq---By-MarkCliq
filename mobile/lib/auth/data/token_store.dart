import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The app's login: tokens and the last known account, so the app opens
/// signed in even without signal.
class StoredSession extends Equatable {
  const new({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
    this.accountJson,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime accessExpiresAt;

  /// The account as last fetched, for opening offline.
  final Map<String, Object?>? accountJson;

  StoredSession withAccount(Map<String, Object?> json) => StoredSession(
    accessToken: accessToken,
    refreshToken: refreshToken,
    accessExpiresAt: accessExpiresAt,
    accountJson: json,
  );

  Map<String, Object?> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'access_expires_at': accessExpiresAt.toUtc().toIso8601String(),
    'account': accountJson,
  };

  static StoredSession? fromJson(Map<String, Object?> json) {
    final access = json['access_token'];
    final refresh = json['refresh_token'];
    final expires = DateTime.tryParse('${json['access_expires_at']}');
    if (access is! String || refresh is! String || expires == null) {
      return null;
    }
    final account = json['account'];
    return StoredSession(
      accessToken: access,
      refreshToken: refresh,
      accessExpiresAt: expires,
      accountJson: account is Map<String, Object?> ? account : null,
    );
  }

  @override
  List<Object?> get props => [
    accessToken,
    refreshToken,
    accessExpiresAt,
    accountJson,
  ];
}

/// Where the app keeps its login between launches.
abstract interface class TokenStore {
  Future<StoredSession?> read();
  Future<void> write(StoredSession session);
  Future<void> clear();
}

/// Keeps the login in the phone's secure storage (Android Keystore,
/// iOS Keychain), never in plain preferences.
class SecureTokenStore implements TokenStore {
  new([this._storage = const FlutterSecureStorage()]);

  static const _key = 'session';
  final FlutterSecureStorage _storage;

  @override
  Future<StoredSession?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      return json is Map<String, Object?> ? StoredSession.fromJson(json) : null;
    } on FormatException {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(StoredSession session) =>
      _storage.write(key: _key, value: jsonEncode(session.toJson()));

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
