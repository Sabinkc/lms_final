/// Centralized keys for [SecureStorageService] and [LocalPrefsService].
///
/// Kept in one place so two features never collide on the same key by
/// accident, and so a key rename is a one-file diff.
class StorageKeys {
  StorageKeys._();

  // Secure storage (flutter_secure_storage) — token-grade secrets only.
  static const String accessToken = 'auth.access_token';
  static const String refreshToken = 'auth.refresh_token';

  // Non-sensitive local prefs (shared_preferences).
  static const String themeMode = 'prefs.theme_mode';
  static const String lastSelectedChildId = 'prefs.last_selected_child_id';
  static const String cachedUser = 'prefs.cached_user';
}
