/// `AttendanceCorrection` as returned by `/api/attendance/corrections`,
/// confirmed against `attendancecorrectionController.js`. **Known gap**: the
/// list/submit/approve/reject responses all return the raw document —
/// `student`/`attendanceSession`/`requestedBy` are bare ObjectId strings,
/// never populated with a name — so a review-queue UI can only show IDs for
/// those, not "Sam Student" the way every other screen in this app does.
/// Flagged here rather than worked around, since populating them would
/// require a backend change this app can't make.
class AttendanceCorrection {
  final String id;
  final String targetType;
  final String? attendanceSessionId;
  final String? studentId;
  final String oldStatus;
  final String newStatus;
  final String reason;
  final String status;
  final String requestedById;
  final String? reviewNote;

  const AttendanceCorrection({
    required this.id,
    required this.targetType,
    required this.attendanceSessionId,
    required this.studentId,
    required this.oldStatus,
    required this.newStatus,
    required this.reason,
    required this.status,
    required this.requestedById,
    required this.reviewNote,
  });

  factory AttendanceCorrection.fromJson(Map<String, dynamic> json) => AttendanceCorrection(
    id: json['_id'] as String? ?? json['id'] as String,
    targetType: json['targetType'] as String? ?? '',
    attendanceSessionId: json['attendanceSession'] as String?,
    studentId: json['student'] as String?,
    oldStatus: json['oldStatus'] as String? ?? '',
    newStatus: json['newStatus'] as String? ?? '',
    reason: json['reason'] as String? ?? '',
    status: json['status'] as String? ?? 'pending',
    requestedById: json['requestedBy'] as String? ?? '',
    reviewNote: json['reviewNote'] as String?,
  );
}
