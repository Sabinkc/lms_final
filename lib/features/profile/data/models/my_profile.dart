import '../../../auth/data/models/app_role.dart';

/// The signed-in user's own profile, normalised across the four roles'
/// different "me" endpoints (backend `02e637f`):
///
/// * Admin   — `GET /api/admin/profile`: name/email/phone on the document.
/// * Teacher — `GET /api/teachers/me`, Student — `GET /api/students/me`,
///   Parent — `GET /api/parents/me`: name/email on the populated `userId`,
///   contact fields on the role document.
///
/// [details] holds the role-specific, read-only rows (class, employee ID,
/// children…) — only fields that actually have a value.
class MyProfile {
  final AppRole role;

  /// The role document's `_id` (Admin uses it to upload their own photo).
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? address;
  final String? photoUrl;
  final String? schoolName;

  /// Student only.
  final DateTime? dob;

  /// Parent only.
  final String? occupation;

  final List<(String label, String value)> details;

  const MyProfile({
    required this.role,
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.address,
    this.photoUrl,
    this.schoolName,
    this.dob,
    this.occupation,
    this.details = const [],
  });

  factory MyProfile.fromJson(AppRole role, Map<String, dynamic> json) {
    final user = json['userId'] is Map<String, dynamic> ? json['userId'] as Map<String, dynamic> : null;
    final school = json['schoolId'] is Map<String, dynamic> ? json['schoolId'] as Map<String, dynamic> : null;

    return MyProfile(
      role: role,
      id: json['_id'] as String? ?? '',
      fullName: _text(user?['fullName']) ?? _text(json['fullName']) ?? '',
      email: _text(user?['email']) ?? _text(json['email']) ?? '',
      phone: _text(json['phone']),
      address: _text(json['address']),
      photoUrl: _text(json['profileImage']),
      schoolName: _text(school?['name']),
      dob: role == AppRole.student ? DateTime.tryParse(_text(json['dob']) ?? '') : null,
      occupation: role == AppRole.parent ? _text(json['occupation']) : null,
      details: switch (role) {
        AppRole.admin => const [],
        AppRole.teacher => _teacherDetails(json),
        AppRole.student => _studentDetails(json),
        AppRole.parent => _parentDetails(json),
      },
    );
  }

  /// Parents have no photo field in the backend schema — an upload would be
  /// accepted but silently dropped — so the app doesn't offer one.
  bool get canChangePhoto => role != AppRole.parent;

  /// Admin's backend rule is 8; the other three roles accept 6.
  int get minPasswordLength => role == AppRole.admin ? 8 : 6;

  static List<(String, String)> _teacherDetails(Map<String, dynamic> json) {
    final subjects = (json['subjects'] as List?)
        ?.map((s) => s is Map ? _text(s['name']) : _text(s))
        .whereType<String>()
        .join(', ');
    final experience = json['experience'];
    return _rows([
      ('Employee ID', _text(json['employeeId'])),
      ('Department', _text(json['department'])),
      ('Subjects', subjects),
      ('Qualification', _text(json['qualification'])),
      ('Experience', experience is num && experience > 0 ? '$experience year${experience == 1 ? '' : 's'}' : null),
      ('Joined', _date(json['joiningDate'])),
    ]);
  }

  static List<(String, String)> _studentDetails(Map<String, dynamic> json) {
    final className = _text(json['class']);
    final section = _text(json['section']);
    final parent = json['parentId'] is Map ? _text((json['parentId'] as Map)['fullName']) : null;
    return _rows([
      ('Class', className == null ? null : (section == null ? className : '$className – $section')),
      ('Roll number', _text(json['rollNumber'])),
      ('Admission number', _text(json['admissionNumber'])),
      ('Student ID', _text(json['studentIdCode'])),
      ('Gender', _text(json['gender'])),
      ('Blood group', _text(json['bloodGroup'])),
      ('Parent / Guardian', parent ?? _text(json['guardianName'])),
    ]);
  }

  static List<(String, String)> _parentDetails(Map<String, dynamic> json) {
    final children = (json['students'] as List?)
        ?.map((s) => s is Map && s['userId'] is Map ? _text((s['userId'] as Map)['fullName']) : null)
        .whereType<String>()
        .join(', ');
    return _rows([('Children', children)]);
  }

  static List<(String, String)> _rows(List<(String, String?)> rows) => [
    for (final (label, value) in rows)
      if (value != null && value.isNotEmpty) (label, value),
  ];

  static String? _text(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _date(Object? value) {
    final parsed = DateTime.tryParse(_text(value) ?? '');
    return parsed == null ? null : formatDate(parsed);
  }

  /// `2026-09-04` → `4 Sep 2026`.
  static String formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final local = date.toLocal();
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }
}
