import 'dart:typed_data';

import '../../../../core/error/result.dart';
import '../models/bulk_import_result.dart';
import '../models/student.dart';

/// `/api/students`, `protectAdmin`-guarded throughout (confirmed directly
/// against `studentRoutes.js`/`studentController.js` — the best-documented
/// module per `api_spec.md`).
abstract class StudentRepository {
  Future<Result<List<Student>>> getStudents({String? className, String? section});

  /// `GET /students/me` (`protect`) — the caller's own Student profile.
  /// Added for Fees (Phase G): unlike Attendance/Exams, there is no
  /// combined `/fees/me` shortcut, so a Student wanting their own fee list
  /// has to resolve their own `Student._id` first via this call, then pass
  /// it to `FeeRepository.getStudentFees`.
  Future<Result<Student>> getMyProfile();

  /// Either [email] (creates a new login) or [userId] (links an existing
  /// one) must be provided — mirrors the backend's own either/or validation
  /// in `createStudent` rather than re-deriving a separate rule client-side.
  Future<Result<Student>> createStudent({
    required String className,
    required String section,
    String? fullName,
    String? email,
    String? userId,
    String? password,
    String? admissionNumber,
    String? rollNumber,
    String? parentId,
    String? dob,
    String? address,
    String? phone,
  });

  Future<Result<Student>> updateStudent({
    required String id,
    String? admissionNumber,
    String? rollNumber,
    String? className,
    String? section,
    String? parentId,
    String? dob,
    String? address,
    String? phone,
    String? status,
  });

  Future<Result<void>> deleteStudent(String id);

  Future<Result<BulkImportResult>> bulkImport(Uint8List fileBytes, String filename);

  Future<Result<Uint8List>> downloadImportTemplate();

  Future<Result<Uint8List>> exportStudents({String? className, String? section});
}
