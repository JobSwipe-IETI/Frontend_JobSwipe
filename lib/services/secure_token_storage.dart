import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _accessTokenKey = 'jobswipe_access_token';
  static const String _refreshTokenKey = 'jobswipe_refresh_token';
  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) => saveAccessToken(token);

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<void> saveSession({required String accessToken, String? refreshToken}) async {
    await saveAccessToken(accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await saveRefreshToken(refreshToken);
    }
  }

  Future<String?> readToken() => readAccessToken();

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> clearToken() => clearSession();

  Future<void> clearSession() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
