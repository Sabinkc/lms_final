/// `GET /group-chats/eligible-targets` (Teacher-only) — the classes/sections
/// a Teacher is actually assigned to, for the create-group class/section
/// picker. Confirmed by reading `groupChatController.js`'s
/// `getEligibleTargets` directly: scoped to `Section.teachers` containing
/// the caller, unlike Assignments/Attendance which let a Teacher act on any
/// class/section in the school — group-chat creation is the one place this
/// backend actually enforces the "assigned sections only" rule.
class EligibleTarget {
  final String classId;
  final String className;
  final bool hasSections;
  final List<EligibleSection> sections;

  const EligibleTarget({required this.classId, required this.className, required this.hasSections, required this.sections});

  factory EligibleTarget.fromJson(Map<String, dynamic> json) => EligibleTarget(
        classId: json['classId'] as String,
        className: json['className'] as String? ?? '',
        hasSections: json['hasSections'] as bool? ?? false,
        sections: (json['sections'] as List? ?? const [])
            .map((s) => EligibleSection.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

class EligibleSection {
  final String id;
  final String name;

  const EligibleSection({required this.id, required this.name});

  factory EligibleSection.fromJson(Map<String, dynamic> json) =>
      EligibleSection(id: json['_id'] as String, name: json['name'] as String? ?? '');
}
