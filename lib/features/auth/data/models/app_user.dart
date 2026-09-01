import 'app_role.dart';

/// Deliberately minimal — just enough to resolve role-based navigation.
/// The full profile shape (per-role fields confirmed in docs/api_spec.md
/// §5) belongs to the Profile/Admin-management **features**, not this
/// foundation pass.
class AppUser {
  final String id;
  final String fullName;
  final String email;
  final AppRole role;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['_id'] as String? ?? json['id'] as String,
        fullName: json['fullName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: AppRole.fromBackendString(json['role'] as String),
      );

  /// Round-trips with [fromJson] — used to cache the session's user locally
  /// (see `LocalPrefsService.cachedUserJson`), not to talk to the backend.
  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'role': role.name,
      };
}
