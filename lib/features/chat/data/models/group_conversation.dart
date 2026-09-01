/// Shape confirmed by reading `GroupConversationSchema.js`/
/// `groupChatController.js` directly. `teachers`/`members` come back as
/// bare id arrays on `GET /` (`getMyGroups` only populates `teachers` down
/// to `{employeeId}`, no name) — full `Student` docs for `members` are only
/// populated on `GET /:id` (`getGroupById`), which is why that endpoint
/// returns a separate `(GroupConversation, List<Student>)` pair rather than
/// folding member details into this model.
class GroupConversation {
  final String id;
  final String name;
  final String classId;
  final String className;
  final String? sectionId;
  final String? sectionName;
  final List<String> teacherIds;
  final List<String> memberIds;
  final String? lastMessageAt;
  final String lastMessagePreview;
  final String status;

  const GroupConversation({
    required this.id,
    required this.name,
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
    required this.teacherIds,
    required this.memberIds,
    required this.lastMessageAt,
    required this.lastMessagePreview,
    required this.status,
  });

  factory GroupConversation.fromJson(Map<String, dynamic> json) {
    List<String> idsOf(String key) => (json[key] as List? ?? const [])
        .map((e) => e is Map<String, dynamic> ? e['_id'] as String : e as String)
        .toList();
    String? idOf(String key) {
      final value = json[key];
      return value is Map<String, dynamic> ? value['_id'] as String? : value as String?;
    }

    return GroupConversation(
      id: json['_id'] as String? ?? json['id'] as String,
      name: json['name'] as String? ?? '',
      classId: idOf('classId') ?? '',
      className: json['className'] as String? ?? '',
      sectionId: idOf('sectionId'),
      sectionName: json['sectionName'] as String?,
      teacherIds: idsOf('teachers'),
      memberIds: idsOf('members'),
      lastMessageAt: json['lastMessageAt'] as String?,
      lastMessagePreview: json['lastMessagePreview'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
    );
  }
}
