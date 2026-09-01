import 'dart:typed_data';

import '../../../../core/error/result.dart';
import '../models/student_followup.dart';

/// `/api/admin/student-followups`, `protectAdmin`-guarded throughout
/// (confirmed by reading `Studentfollowuproutes.js` directly).
abstract class StudentFollowupRepository {
  Future<Result<List<StudentFollowup>>> getFollowups({String? status, String? faculty, String? search, int? limit});

  Future<Result<StudentFollowup>> createFollowup({
    required String studentName,
    required String faculty,
    required String email,
    required String contactNumber,
    required String address,
    required String followUpNote,
    String? visitDate,
    String? status,
  });

  Future<Result<StudentFollowup>> updateFollowup({
    required String id,
    String? studentName,
    String? faculty,
    String? email,
    String? contactNumber,
    String? address,
    String? followUpNote,
    String? visitDate,
    String? status,
  });

  Future<Result<void>> deleteFollowup(String id);

  /// `GET /export`, accepts the same `status`/`faculty`/`search` filters as
  /// [getFollowups] — real backend-generated `.xlsx` blob, same shape as
  /// `FeeRepository.exportFees()`.
  Future<Result<Uint8List>> exportFollowups({String? status, String? faculty, String? search});
}
