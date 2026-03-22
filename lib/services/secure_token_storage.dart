import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _jwtKey = 'jobswipe_jwt';
  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) =>
      _storage.write(key: _jwtKey, value: token);

  Future<String?> readToken() => _storage.read(key: _jwtKey);

  Future<void> clearToken() => _storage.delete(key: _jwtKey);
}
