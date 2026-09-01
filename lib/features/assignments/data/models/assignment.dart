/// `Assignment` — System A (`/api/assignments`), the user's confirmed
/// choice over the parallel, submission-less System B
/// (`docs/production_roadmap.md` §4 decision #3). Shape confirmed against
/// `assignmentSchema.js`/`assignmentController.js` directly.
class Assignment {
  final String id;
  final String title;
  final String description;
  final String className;
  final String section;
  final String subject;
  final String dueDate;
  final String attachment;
  final String status;
  final String teacherEmployeeId;

  const Assignment({
    required this.id,
    required this.title,
    required this.description,
    required this.className,
    required this.section,
    required this.subject,
    required this.dueDate,
    required this.attachment,
    required this.status,
    required this.teacherEmployeeId,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    final teacher = json['teacherId'];
    return Assignment(
      id: json['_id'] as String? ?? json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      className: json['class'] as String? ?? '',
      section: json['section'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      dueDate: json['dueDate'] as String? ?? '',
      attachment: json['attachment'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      teacherEmployeeId: teacher is Map<String, dynamic> ? teacher['employeeId'] as String? ?? '' : '',
    );
  }
}
