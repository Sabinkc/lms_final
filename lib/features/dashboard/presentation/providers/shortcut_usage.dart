import '../../../../core/storage/local_prefs_service.dart';

/// Orders a role's Home shortcuts by how often this person opens them
/// (Hick's law: fewer, more relevant choices), keeping at most [limit]
/// tiles with "More" always last so everything stays one tap away.
///
/// Counts are read once per app session, so tiles never move while the
/// person is using Home; new taps take effect from the next launch.
class ShortcutUsage {
  final LocalPrefsService _prefs;
  final Map<String, Map<String, int>> _sessionCounts = {};

  ShortcutUsage(this._prefs);

  static const limit = 8;

  List<T> pick<T>({
    required String role,
    required List<T> all,
    required String Function(T) idOf,
    required bool Function(T) isMore,
  }) {
    final counts = _sessionCounts.putIfAbsent(role, () => _prefs.shortcutUsage(role));
    final more = all.where(isMore).toList();
    final rest = all.where((t) => !isMore(t)).toList();
    final order = {for (var i = 0; i < rest.length; i++) idOf(rest[i]): i};
    rest.sort((a, b) {
      final byUse = (counts[idOf(b)] ?? 0).compareTo(counts[idOf(a)] ?? 0);
      return byUse != 0 ? byUse : order[idOf(a)]!.compareTo(order[idOf(b)]!);
    });
    final room = all.length <= limit ? rest.length : limit - more.length;
    return [...rest.take(room), ...more];
  }

  Future<void> record(String role, String id) {
    final saved = _prefs.shortcutUsage(role);
    saved[id] = (saved[id] ?? 0) + 1;
    return _prefs.setShortcutUsage(role, saved);
  }
}
