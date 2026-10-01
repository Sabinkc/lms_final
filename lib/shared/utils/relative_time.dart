import 'display_date.dart';

/// Chat/notification-list timestamp: the time for today ("10:24 AM"),
/// "Yesterday", "3 days ago" within a week, then the plain display date.
/// Returns '' for an unparseable value so callers can just hide it.
String formatRelativeTime(String raw, {DateTime? now}) {
  final at = DateTime.tryParse(raw)?.toLocal();
  if (at == null) return '';
  final today = now ?? DateTime.now();
  final days = DateTime(today.year, today.month, today.day).difference(DateTime(at.year, at.month, at.day)).inDays;
  if (days <= 0) {
    final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
    return '$hour:${at.minute.toString().padLeft(2, '0')} ${at.hour < 12 ? 'AM' : 'PM'}';
  }
  if (days == 1) return 'Yesterday';
  if (days < 7) return '$days days ago';
  // A timestamp's calendar day is the viewer's local day (same as the
  // branches above); formatting [raw] directly would show the UTC date and
  // disagree with chat's local-day separators.
  return formatDisplayDate(DateTime(at.year, at.month, at.day).toIso8601String());
}
