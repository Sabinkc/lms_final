/// Shape confirmed by reading `Studentfollowuproutes.js`/
/// `Studentfollowupcontroller.js` directly (`docs/production_roadmap.md`
/// Phase L5, `implementation_backlog.md` E18) — a CRM-style log of
/// prospective/at-risk student visits, not a Student-record feature despite
/// the name. `createdBy` carries the same dual-shape-ref parsing as
/// `Department.headOfDepartmentId`: populated `{_id, fullName, email}` on
/// `GET` (`Admin` has `fullName`/`email` directly, unlike `Teacher`'s
/// nested `userId`), bare id string on create/update (not re-populated
/// after `.create()`/`.findOneAndUpdate()`).
class StudentFollowup {
  final String id;
  final String studentName;
  final String faculty;
  final String email;
  final String contactNumber;
  final String address;
  final String followUpNote;
  final String? visitDate;
  final String status;
  final String? createdByName;

  const StudentFollowup({
    required this.id,
    required this.studentName,
    required this.faculty,
    required this.email,
    required this.contactNumber,
    required this.address,
    required this.followUpNote,
    required this.visitDate,
    required this.status,
    required this.createdByName,
  });

  factory StudentFollowup.fromJson(Map<String, dynamic> json) {
    final createdBy = json['createdBy'];
    final createdByName = createdBy is Map<String, dynamic> ? createdBy['fullName'] as String? : null;

    return StudentFollowup(
      id: json['_id'] as String? ?? json['id'] as String,
      studentName: json['studentName'] as String? ?? '',
      faculty: json['faculty'] as String? ?? '',
      email: json['email'] as String? ?? '',
      contactNumber: json['contactNumber'] as String? ?? '',
      address: json['address'] as String? ?? '',
      followUpNote: json['followUpNote'] as String? ?? '',
      visitDate: json['visitDate'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdByName: createdByName,
    );
  }
}
