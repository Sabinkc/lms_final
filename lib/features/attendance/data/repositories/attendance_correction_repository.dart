import '../../../../core/error/result.dart';
import '../models/attendance_correction.dart';

/// `/api/attendance/corrections` — confirmed real request/approve/reject
/// workflow (`attendancecorrectionRoutes.js`/`attendancecorrectionController.js`),
/// not a direct edit of a locked `AttendanceSession`/`AttendanceRecord`.
/// `submitCorrection` (Teacher-facing request creation) isn't covered by
/// this repository yet — this app currently only builds the Admin review
/// side (`implementation_backlog.md` E3-F6-T2); the Teacher request UI
/// (E3-F6-T1) is P2 and parked.
abstract class AttendanceCorrectionRepository {
  /// Admin/Superadmin see every correction in the school; a non-admin
  /// caller would only see their own requests (`listCorrections`'s role
  /// check) — not relevant here since this repository is Admin-only.
  Future<Result<List<AttendanceCorrection>>> getCorrections({String? status});

  /// Applies the requested status change to the underlying attendance
  /// record server-side and writes an `AttendanceLog` entry — not
  /// something the client needs to do separately.
  Future<Result<AttendanceCorrection>> approve(String id, {String? reviewNote});

  Future<Result<AttendanceCorrection>> reject(String id, {String? reviewNote});
}
