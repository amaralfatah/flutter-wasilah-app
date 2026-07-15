import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SecureStorageService {
  Future<void> writeToken(String token);

  Future<String?> readToken();

  Future<void> deleteToken();
}

class FlutterSecureStorageService implements SecureStorageService {
  FlutterSecureStorageService(this._storage);

  static const _accessTokenKey = 'access_token';

  final FlutterSecureStorage _storage;

  @override
  Future<void> deleteToken() => _storage.delete(key: _accessTokenKey);

  @override
  Future<String?> readToken() => _storage.read(key: _accessTokenKey);

  @override
  Future<void> writeToken(String token) {
    return _storage.write(key: _accessTokenKey, value: token);
  }
}

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return FlutterSecureStorageService(const FlutterSecureStorage());
});
