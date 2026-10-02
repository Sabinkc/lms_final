/// "pending" -> "Pending"; safe on an empty string (server values like a
/// fee status can arrive empty, and indexing `[0]` would throw).
String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
