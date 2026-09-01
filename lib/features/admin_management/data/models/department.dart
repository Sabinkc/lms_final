/// Shape confirmed by reading `Departmentroutes.js`/`Departmentcontroller.js`
/// directly (`docs/production_roadmap.md` Phase L2, `implementation_backlog.md`
/// E17) — `api_spec.md` §4.14/§5 only confirmed the mount and Mongoose schema,
/// not the controller's response shape. `GET /` populates `headOfDepartmentId`
/// with `{_id, employeeId, userId: {fullName}}`; `POST`/`PUT` return the bare
/// saved document with `headOfDepartmentId` as a raw id string (or `null`) —
/// same dual-shape-ref pattern as `Student.parentId` (`student.dart`).
class Department {
  final String id;
  final String name;
  final String description;
  final String? headOfDepartmentId;
  final String? headOfDepartmentName;
  final List<String> classes;
  final String status;

  const Department({
    required this.id,
    required this.name,
    required this.description,
    required this.headOfDepartmentId,
    required this.headOfDepartmentName,
    required this.classes,
    required this.status,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    final head = json['headOfDepartmentId'];
    String? headId;
    String? headName;
    if (head is Map<String, dynamic>) {
      headId = head['_id'] as String?;
      final user = head['userId'] as Map<String, dynamic>?;
      headName = user?['fullName'] as String? ?? head['employeeId'] as String?;
    } else if (head is String) {
      headId = head;
    }

    return Department(
      id: json['_id'] as String? ?? json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      headOfDepartmentId: headId,
      headOfDepartmentName: headName,
      classes: (json['classes'] as List<dynamic>? ?? const []).map((e) => e as String).toList(),
      status: json['status'] as String? ?? 'active',
    );
  }
}
