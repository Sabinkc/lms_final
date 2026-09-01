import '../../../../core/error/result.dart';
import '../models/teacher.dart';

/// `/api/teachers`, `protectAdmin`-guarded throughout (confirmed directly
/// against `teacherRoutes.js`/`teacherController.js`).
abstract class TeacherRepository {
  Future<Result<List<Teacher>>> getTeachers();

  /// Creating a Teacher also creates their linked `User` login and, per
  /// `teacherController.js`'s `createTeacher`, always sends a
  /// welcome-credentials email server-side regardless of whether [password]
  /// is supplied (a random one is generated when it isn't) — this resolves
  /// `implementation_backlog.md` E2-F2-T5's previously-unconfirmed question.
  Future<Result<Teacher>> createTeacher({
    required String fullName,
    required String email,
    required String employeeId,
    required String department,
    String? password,
    String? designation,
    String? qualification,
    List<String>? subjects,
    int? experience,
    double? salary,
    String? address,
    String? phone,
    String? bankAccountNumber,
  });

  Future<Result<Teacher>> updateTeacher({
    required String id,
    String? employeeId,
    String? department,
    String? designation,
    String? qualification,
    List<String>? subjects,
    int? experience,
    double? salary,
    String? address,
    String? phone,
    String? bankAccountNumber,
    String? status,
  });

  /// Also deletes the linked `User` account server-side (`deleteTeacher`) —
  /// not something the client needs to do separately.
  Future<Result<void>> deleteTeacher(String id);
}
