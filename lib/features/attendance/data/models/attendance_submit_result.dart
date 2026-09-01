/// `POST /api/attendance/student`'s response `data` shape, confirmed
/// against `studentattendanceController.js`'s `createAttendance`.
class AttendanceSubmitFailure {
  final String studentId;
  final String reason;

  const AttendanceSubmitFailure({required this.studentId, required this.reason});

  factory AttendanceSubmitFailure.fromJson(Map<String, dynamic> json) => AttendanceSubmitFailure(
        studentId: json['studentId'] as String? ?? '',
        reason: json['reason'] as String? ?? '',
      );
}

class AttendanceSubmitResult {
  final int savedCount;
  final List<AttendanceSubmitFailure> failed;

  const AttendanceSubmitResult({required this.savedCount, required this.failed});

  factory AttendanceSubmitResult.fromJson(Map<String, dynamic> json) => AttendanceSubmitResult(
        savedCount: (json['saved'] as List).length,
        failed:
            (json['failed'] as List).map((f) => AttendanceSubmitFailure.fromJson(f as Map<String, dynamic>)).toList(),
      );
}
