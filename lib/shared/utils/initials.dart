/// First-plus-last-name initials (e.g. "Sam Student" -> "SS"), used for
/// avatar placeholders wherever this app has no student/staff photo.
String initialsFor(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
}
