import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const _storage = FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'user_name';
  static const _userEmailKey = 'user_email';
  static const _userRoleKey = 'user_role';

  // ── Tokens ──────────────────────────────

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  static Future<String?> getAccessToken() =>
      _storage.read(key: _accessTokenKey);

  static Future<String?> getRefreshToken() =>
      _storage.read(key: _refreshTokenKey);

  static Future<void> updateAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  // ── Dados do utilizador ─────────────────

  static Future<void> saveUser({
    required String id,
    required String name,
    required String email,
    required String role,
  }) async {
    await Future.wait([
      _storage.write(key: _userIdKey, value: id),
      _storage.write(key: _userNameKey, value: name),
      _storage.write(key: _userEmailKey, value: email),
      _storage.write(key: _userRoleKey, value: role),
    ]);
  }

  static Future<Map<String, String?>> getUser() async {
    final results = await Future.wait([
      _storage.read(key: _userIdKey),
      _storage.read(key: _userNameKey),
      _storage.read(key: _userEmailKey),
      _storage.read(key: _userRoleKey),
    ]);
    return {
      'id': results[0],
      'name': results[1],
      'email': results[2],
      'role': results[3],
    };
  }

  // ── Logout ──────────────────────────────

  static Future<void> clear() => _storage.deleteAll();
}
