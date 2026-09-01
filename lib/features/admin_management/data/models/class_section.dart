/// Shape confirmed by reading `sectionRoutes.js`/`Sectioncontroller.js`
/// directly (docs/production_roadmap.md Phase B step 1). `studentCount` is
/// only present on the list endpoint (`GET /api/classes/:classId/sections`,
/// server-computed via aggregation) — absent on create/update responses,
/// where it defaults to 0 (correct: a just-created/renamed section has
/// whatever count it already had, and this model is only ever fresh-built
/// from a just-created section, never used to overwrite a known count).
class ClassSection {
  final String id;
  final String name;
  final String classId;
  final String status;
  final int studentCount;

  const ClassSection({
    required this.id,
    required this.name,
    required this.classId,
    required this.status,
    this.studentCount = 0,
  });

  factory ClassSection.fromJson(Map<String, dynamic> json) => ClassSection(
        id: json['_id'] as String? ?? json['id'] as String,
        name: json['name'] as String? ?? '',
        classId: json['classId'] as String? ?? '',
        status: json['status'] as String? ?? 'active',
        studentCount: json['studentCount'] as int? ?? 0,
      );
}
