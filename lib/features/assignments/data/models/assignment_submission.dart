/// `AssignmentSubmission`, confirmed against `assignmentSubmissionSchema.js`.
/// Populated differently by different endpoints — `studentId` is populated
/// (with nested `userId`) only on the Teacher-facing submissions-for-an-
/// assignment list; `assignmentId` is populated (with a few summary fields)
/// only on the Student-facing "my submissions" list. Both are optional here
/// and filled in from whichever shape the calling endpoint actually
/// returned, never guessed.
class SubmissionAttachment {
  final String url;
  final String fileName;
  final String fileType;
  final int fileSize;

  const SubmissionAttachment({
    required this.url,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
  });

  factory SubmissionAttachment.fromJson(Map<String, dynamic> json) => SubmissionAttachment(
        url: json['url'] as String? ?? '',
        fileName: json['fileName'] as String? ?? '',
        fileType: json['fileType'] as String? ?? '',
        fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      );
}

class AssignmentSubmission {
  final String id;
  final String assignmentId;
  final String submissionText;
  final List<SubmissionAttachment> attachments;
  final String submittedAt;
  final num? marks;
  final String remarks;
  final bool graded;

  /// Only populated on the Teacher-facing submissions list.
  final String? studentName;
  final String? studentAdmissionNumber;

  /// Only populated on the Student-facing "my submissions" list.
  final String? assignmentTitle;
  final String? assignmentDueDate;
  final String? assignmentStatus;

  const AssignmentSubmission({
    required this.id,
    required this.assignmentId,
    required this.submissionText,
    required this.attachments,
    required this.submittedAt,
    required this.marks,
    required this.remarks,
    required this.graded,
    this.studentName,
    this.studentAdmissionNumber,
    this.assignmentTitle,
    this.assignmentDueDate,
    this.assignmentStatus,
  });

  factory AssignmentSubmission.fromJson(Map<String, dynamic> json) {
    final studentRef = json['studentId'];
    final assignmentRef = json['assignmentId'];
    final studentUser = studentRef is Map<String, dynamic> ? studentRef['userId'] : null;

    return AssignmentSubmission(
      id: json['_id'] as String? ?? json['id'] as String,
      assignmentId: assignmentRef is Map<String, dynamic>
          ? assignmentRef['_id'] as String? ?? ''
          : assignmentRef as String? ?? '',
      submissionText: json['submissionText'] as String? ?? '',
      attachments: (json['attachments'] as List? ?? const [])
          .map((a) => SubmissionAttachment.fromJson(a as Map<String, dynamic>))
          .toList(),
      submittedAt: json['submittedAt'] as String? ?? '',
      marks: json['marks'] as num?,
      remarks: json['remarks'] as String? ?? '',
      graded: json['gradedAt'] != null,
      studentName: studentUser is Map<String, dynamic> ? studentUser['fullName'] as String? : null,
      studentAdmissionNumber: studentRef is Map<String, dynamic> ? studentRef['admissionNumber'] as String? : null,
      assignmentTitle: assignmentRef is Map<String, dynamic> ? assignmentRef['title'] as String? : null,
      assignmentDueDate: assignmentRef is Map<String, dynamic> ? assignmentRef['dueDate'] as String? : null,
      assignmentStatus: assignmentRef is Map<String, dynamic> ? assignmentRef['status'] as String? : null,
    );
  }
}
