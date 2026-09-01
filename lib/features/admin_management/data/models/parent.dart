import 'student.dart';

/// Shape confirmed by reading `parentRoutes.js`/`parentController.js`
/// directly. `students` comes back **fully populated** (each a complete
/// `Student` document with its own nested `userId`) on every Admin-facing
/// endpoint (`createParent`/`getAllParents`/`getParentById`/`updateParent`
/// all populate it the same way) — never just an array of ids — so
/// [children] reuses [Student.fromJson] rather than a separate lightweight
/// type.
class Parent {
  final String id;
  final String fullName;
  final String email;
  final String occupation;
  final String address;
  final String phone;
  final String status;
  final List<Student> children;

  const Parent({
    required this.id,
    required this.fullName,
    required this.email,
    required this.occupation,
    required this.address,
    required this.phone,
    required this.status,
    required this.children,
  });

  factory Parent.fromJson(Map<String, dynamic> json) {
    final user = json['userId'] as Map<String, dynamic>?;
    final studentsJson = json['students'] as List? ?? const [];
    return Parent(
      id: json['_id'] as String? ?? json['id'] as String,
      fullName: user?['fullName'] as String? ?? '',
      email: user?['email'] as String? ?? json['email'] as String? ?? '',
      occupation: json['occupation'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      children: studentsJson
          .whereType<Map<String, dynamic>>()
          .map((s) => Student.fromJson(s))
          .toList(),
    );
  }
}
