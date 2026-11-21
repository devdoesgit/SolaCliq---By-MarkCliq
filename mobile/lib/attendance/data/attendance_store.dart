import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where unsent attendance taps are kept between app runs, as one JSON
/// string.
abstract interface class AttendanceStore {
  Future<String?> read();
  Future<void> write(String json);
}

/// The phone's secure storage, beside the login.
class SecureAttendanceStore implements AttendanceStore {
  new([this._storage = const FlutterSecureStorage()]);

  static const _key = 'attendance_outbox';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String json) => _storage.write(key: _key, value: json);
}

/// Kept in memory only: for tests.
class MemoryAttendanceStore implements AttendanceStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String json) async => value = json;
}
