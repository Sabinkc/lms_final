/// Shape confirmed by reading `classRoutes.js`/`Classcontroller.js` directly
/// (docs/production_roadmap.md Phase B step 1 — `api_spec.md` hadn't
/// deep-dived this route file). `POST/PUT /api/classes` return this shape
/// bare (no `sections`); `GET /api/classes` embeds a `sections` array per
/// class, but that's not modeled here — sections are fetched separately via
/// `SectionRepository` scoped to a `classId`, matching the backend's own
/// `/api/classes/:classId/sections` nesting.
class AcademicClass {
  final String id;
  final String name;
  final String description;
  final String status;

  const AcademicClass({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
  });

  factory AcademicClass.fromJson(Map<String, dynamic> json) => AcademicClass(
        id: json['_id'] as String? ?? json['id'] as String,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        status: json['status'] as String? ?? 'active',
      );
}
