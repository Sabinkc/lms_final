import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/storage_keys.dart';

/// Token-grade secrets only (access + refresh JWT — docs/api_spec.md §2
/// confirms both are real, returned in the login/refresh JSON body).
/// Everything else belongs in [LocalPrefsService]. No feature should import
/// `flutter_secure_storage` directly — always go through this service so
/// there's exactly one place that knows the underlying storage mechanism.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  const SecureStorageService(this._storage);

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: StorageKeys.accessToken, value: accessToken);
    await _storage.write(key: StorageKeys.refreshToken, value: refreshToken);
  }

  Future<String?> readAccessToken() => _storage.read(key: StorageKeys.accessToken);

  Future<String?> readRefreshToken() => _storage.read(key: StorageKeys.refreshToken);

  Future<void> clearTokens() async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
  }
}
