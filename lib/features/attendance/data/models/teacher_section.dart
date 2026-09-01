/// `GET /api/sections/my/teacher`'s response shape, confirmed by reading
/// `Sectioncontroller.js`'s `getMySections` directly — it returns **every**
/// active section in the school, not ones this teacher is specifically
/// assigned to (`attendenceRoutes.js`/`studentattendanceController.js`
/// confirm "any teacher in this school may mark attendance for any
/// section"), with `classId` populated to `{_id, name}` rather than a bare
/// id — a different shape from `admin_management`'s `ClassSection`, which is
/// why this is its own small model instead of reusing that one.
class TeacherSection {
  final String id;
  final String name;
  final String classId;
  final String className;

  const TeacherSection({
    required this.id,
    required this.name,
    required this.classId,
    required this.className,
  });

  factory TeacherSection.fromJson(Map<String, dynamic> json) {
    final classRef = json['classId'];
    return TeacherSection(
      id: json['_id'] as String? ?? json['id'] as String,
      name: json['name'] as String? ?? '',
      classId: classRef is Map<String, dynamic> ? classRef['_id'] as String? ?? '' : classRef as String? ?? '',
      className: classRef is Map<String, dynamic> ? classRef['name'] as String? ?? '' : '',
    );
  }
}
