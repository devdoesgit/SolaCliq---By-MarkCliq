import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Remembers which workspace the person last used, by its id.
abstract interface class WorkspaceStore {
  Future<String?> read();
  Future<void> write(String workspaceId);
  Future<void> clear();
}

/// Kept beside the login in secure storage, so it goes with it.
class SecureWorkspaceStore implements WorkspaceStore {
  new([this._storage = const FlutterSecureStorage()]);

  static const _key = 'workspace';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String workspaceId) =>
      _storage.write(key: _key, value: workspaceId);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
