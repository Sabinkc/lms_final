import 'dart:typed_data';

import '../../../../core/error/result.dart';
import '../../../admin_management/data/models/student.dart';
import '../models/fee.dart';

/// `/api/fees` — Admin CRUD is per-student (`feeController.createFee`
/// requires `studentId`, confirmed by reading the controller directly; the
/// `implementation_backlog.md` task name "Per-class fee item form" is
/// imprecise — there is no bulk/per-class creation endpoint, an Admin picks
/// one student per fee, same as picking one student when linking a Parent).
abstract class FeeRepository {
  Future<Result<Fee>> createFee({
    required String studentId,
    required String title,
    String? description,
    required double totalAmount,
    double discountPercent,
    String? dueDate,
    bool isInstallment,
    List<FeeInstallmentInput>? installments,
  });

  /// Admin-only, optionally filtered by `status`.
  Future<Result<List<Fee>>> getFees({String? status});

  Future<Result<Fee>> getFeeById(String id);

  /// Update is intentionally narrow — `updateFee` only accepts
  /// title/description/dueDate/totalAmount, and the latter two are silently
  /// ignored server-side once `isInstallment` is true (see `feeController.js`
  /// `updateFee`'s doc comment: installments aren't editable here at all).
  Future<Result<Fee>> updateFee({
    required String id,
    String? title,
    String? description,
    double? totalAmount,
    String? dueDate,
  });

  Future<Result<void>> deleteFee(String id);

  /// `GET /fees/export`, optionally filtered by `status` — real
  /// backend-generated `.xlsx` blob (`docs/production_roadmap.md` Phase L3,
  /// `implementation_backlog.md` E19), not client-side generation, same
  /// pattern as `StudentRepository.exportStudents()`.
  Future<Result<Uint8List>> exportFees({String? status});

  /// `(summary, paymentQrUrl, fees)` — one call returns all three, matching
  /// `getStudentFees`'s actual response shape rather than splitting it into
  /// three round trips.
  Future<Result<(FeesSummary, String?, List<Fee>)>> getStudentFees(String studentId);

  /// `GET /parents/me`'s populated `students[]` — Parent role entry point.
  /// Duplicated per-feature rather than shared, matching the existing
  /// precedent in `AttendanceRepository`/`ExamResultRepository`.
  Future<Result<List<Student>>> getMyChildren();
}

class FeeInstallmentInput {
  final String? title;
  final double amount;
  final String dueDate;

  const FeeInstallmentInput({this.title, required this.amount, required this.dueDate});
}
