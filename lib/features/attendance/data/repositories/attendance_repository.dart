import '../../../../core/error/result.dart';
import '../../../admin_management/data/models/student.dart';
import '../models/day_attendance_record.dart';
import '../models/attendance_session.dart';
import '../models/attendance_status.dart';
import '../models/attendance_submit_result.dart';
import '../models/student_attendance_history.dart';
import '../models/teacher_section.dart';

class AttendanceRecordInput {
  final String studentId;
  final AttendanceStatus status;
  final String? remarks;

  const AttendanceRecordInput({required this.studentId, required this.status, this.remarks});
}

/// `/api/attendance/student` (create/read) + `/api/sections/my/*`
/// (roster-picking), `protectAdmin`+`eitherAuth`-guarded per-route —
/// confirmed directly against `studentattendanceRoutes.js`/
/// `studentattendanceController.js` and `sectionRoutes.js`.
abstract class AttendanceRepository {
  /// Every active section in the school — a Teacher may mark attendance for
  /// any of them (`studentattendanceController.js`'s `createAttendance`
  /// comment: "Any teacher in this school may mark attendance for any
  /// section/class in that school. No Section.teachers assignment
  /// required."), not just ones they're formally assigned to.
  Future<Result<List<TeacherSection>>> getMySections();

  Future<Result<List<Student>>> getSectionRoster(String sectionId);

  /// Locks immediately on success — confirmed no Teacher-facing edit path
  /// exists afterward (`implementation_backlog.md` E3-F1-T4).
  Future<Result<AttendanceSubmitResult>> markAttendance({
    required String sectionId,
    required String date,
    String? subject,
    required List<AttendanceRecordInput> records,
  });

  /// `date` is a required backend filter (`studentattendanceController.js`'s
  /// `getAttendanceByDate` 400s without it) — this is "sessions submitted on
  /// this date," not an open-ended history. Scoping is entirely
  /// server-side and role-based on the same endpoint: a Teacher token sees
  /// only their own sessions, an Admin token sees every session in the
  /// school (filterable by [className]/[section]/[subject]) — this one
  /// method backs both Teacher History and Admin Overview, which is why it
  /// isn't named "getMySessions".
  Future<Result<List<AttendanceSessionSummary>>> getSessions({
    required String date,
    String? className,
    String? section,
    String? subject,
  });

  /// `GET /api/attendance/me` resolves the caller's own actor profile —
  /// for a Student caller, that's their own `Student` document. Returns its
  /// `_id`, the id the rest of this API expects (not the `User._id` the
  /// login session carries).
  Future<Result<String>> getMyStudentId();

  /// `GET /api/parents/me`'s `students[]`, fully populated — reuses the
  /// admin_management `Student` model since it's the exact same populated
  /// shape `Parent.students` returns there (confirmed: both endpoints share
  /// `.populate({path: 'students', populate: {path: 'userId', ...}})`).
  Future<Result<List<Student>>> getMyChildren();

  /// Backs both Student "My Attendance" and Parent "Child's Attendance" —
  /// confirmed authorized for the student themselves, their linked parent,
  /// any teacher in the school, or an admin
  /// (`Attendance.service.js`'s `isAuthorizedForStudent`).
  Future<Result<StudentAttendanceHistory>> getStudentAttendanceHistory({
    required String studentId,
    String? month,
    String? year,
  });

  /// Every student's attendance rows for [date] (`YYYY-MM-DD`), optionally
  /// narrowed to one class — backs the Admin Students screen's per-day
  /// statuses. See [DayAttendanceRecord] for the shape.
  Future<Result<List<DayAttendanceRecord>>> getDayRecords({required String date, String? className});
}
