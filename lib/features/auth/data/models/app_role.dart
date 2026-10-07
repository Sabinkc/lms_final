/// The 4 roles this mobile app targets (docs/product_requirements.md §3).
///
/// The confirmed backend `User.role` enum actually has more values —
/// `superadmin`, `hr`, `staff`, `receptionist` also exist server-side
/// (docs/api_spec.md §3) — but whether any of those belong in mobile scope
/// is an open **product decision**, not resolved by this codebase
/// (docs/product_requirements.md §3, docs/gap_analysis.md). Deliberately
/// not modeled here so a role check can never silently "succeed" for an
/// actor type nobody decided should have a mobile UI yet.
enum AppRole {
  admin,
  teacher,
  student,
  parent;

  /// Backend role strings are lowercase and match these names exactly
  /// (docs/api_spec.md §3's `userSchema.js` enum) — no translation table
  /// needed, but kept as an explicit factory so a future mismatch throws
  /// here instead of deep inside a JSON parser.
  static AppRole fromBackendString(String value) => AppRole.values.firstWhere(
    (role) => role.name == value,
    orElse: () => throw ArgumentError.value(value, 'value', 'Unknown or out-of-scope role'),
  );
}
