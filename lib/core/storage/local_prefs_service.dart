import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';

/// Non-sensitive, lightweight cached UI state only (theme mode, last-
/// selected child for a multi-child Parent account — docs/user_flows.md
/// Flow 6). Never a token, never anything school/student-data-shaped — that
/// belongs to a repository's cache layer if one is ever added, not here.
///
/// [cachedUserJson] is the one exception worth calling out: it's not a
/// token (that's [SecureStorageService]'s job) and not school/student data —
/// it's the logged-in user's own identity, cached at login time because no
/// confirmed "who am I" endpoint exists yet to re-fetch it from on restart
/// (docs/production_roadmap.md Phase A step 4). Kept as a raw JSON string
/// here rather than a typed `AppUser` so this class — `core/` infrastructure
/// — never has to import a `features/auth` model.
class LocalPrefsService {
  final SharedPreferences _prefs;

  const LocalPrefsService(this._prefs);

  String? get themeMode => _prefs.getString(StorageKeys.themeMode);

  Future<void> setThemeMode(String mode) => _prefs.setString(StorageKeys.themeMode, mode);

  String? get lastSelectedChildId => _prefs.getString(StorageKeys.lastSelectedChildId);

  Future<void> setLastSelectedChildId(String childId) => _prefs.setString(StorageKeys.lastSelectedChildId, childId);

  Future<void> clearLastSelectedChildId() => _prefs.remove(StorageKeys.lastSelectedChildId);

  String? get cachedUserJson => _prefs.getString(StorageKeys.cachedUser);

  Future<void> setCachedUserJson(String json) => _prefs.setString(StorageKeys.cachedUser, json);

  Future<void> clearCachedUser() => _prefs.remove(StorageKeys.cachedUser);

  /// How often each Home shortcut (by route) was opened, per role — used to
  /// put a person's most-used shortcuts first. Never leaves the device.
  Map<String, int> shortcutUsage(String role) {
    final raw = _prefs.getString('${StorageKeys.shortcutUsage}.$role');
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  Future<void> setShortcutUsage(String role, Map<String, int> counts) =>
      _prefs.setString('${StorageKeys.shortcutUsage}.$role', jsonEncode(counts));
}
