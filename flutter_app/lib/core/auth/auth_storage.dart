import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const _storage = FlutterSecureStorage(
    webOptions: WebOptions(
      dbName: 'order_management_db',
      publicKey: 'order_management_key',
    ),
  );

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'user_name';
  static const _userEmailKey = 'user_email';
  static const _userRoleKey = 'user_role';

  static Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    try {
      await Future.wait([
        _storage.write(key: _accessTokenKey, value: accessToken),
        _storage.write(key: _refreshTokenKey, value: refreshToken),
      ]);
    } catch (_) {}
  }

  static Future<String?> getAccessToken() async {
    try { return await _storage.read(key: _accessTokenKey); } catch (_) { return null; }
  }

  static Future<String?> getRefreshToken() async {
    try { return await _storage.read(key: _refreshTokenKey); } catch (_) { return null; }
  }

  static Future<void> updateAccessToken(String token) async {
    try { await _storage.write(key: _accessTokenKey, value: token); } catch (_) {}
  }

  static Future<void> saveUser({required String id, required String name, required String email, required String role}) async {
    try {
      await Future.wait([
        _storage.write(key: _userIdKey, value: id),
        _storage.write(key: _userNameKey, value: name),
        _storage.write(key: _userEmailKey, value: email),
        _storage.write(key: _userRoleKey, value: role),
      ]);
    } catch (_) {}
  }

  static Future<Map<String, String?>> getUser() async {
    try {
      final results = await Future.wait([
        _storage.read(key: _userIdKey),
        _storage.read(key: _userNameKey),
        _storage.read(key: _userEmailKey),
        _storage.read(key: _userRoleKey),
      ]);
      return {'id': results[0], 'name': results[1], 'email': results[2], 'role': results[3]};
    } catch (_) {
      return {'id': null, 'name': null, 'email': null, 'role': null};
    }
  }

  static Future<void> clear() async {
    try { await _storage.deleteAll(); } catch (_) {}
  }
}
