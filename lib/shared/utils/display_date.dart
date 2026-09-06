const _monthNames = [
  '',
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats a backend date/datetime string (often a full ISO timestamp like
/// `2026-09-12T00:00:00.000Z`) as a short human-readable date, e.g.
/// `12 Sep 2026`. Falls back to the raw string unchanged if it isn't a
/// parseable date, so callers never lose data on an unexpected format.
String formatDisplayDate(String raw) {
  final date = DateTime.tryParse(raw);
  if (date == null) return raw;
  return '${date.day} ${_monthNames[date.month]} ${date.year}';
}
