import '../../../../core/error/result.dart';
import '../../../admin_management/data/models/student.dart';
import '../models/exam_result.dart';

class ResultMarkInput {
  final String subject;
  final int obtainedMarks;
  final int fullMarks;
  final int passMarks;

  const ResultMarkInput({
    required this.subject,
    required this.obtainedMarks,
    required this.fullMarks,
    required this.passMarks,
  });
}

class StudentResultInput {
  final String studentId;
  final List<ResultMarkInput> marks;
  final String? remarks;

  const StudentResultInput({required this.studentId, required this.marks, this.remarks});
}

/// `/api/results` — System B, the user's confirmed choice over the
/// parallel `Exam.results[]`-based System A (`docs/production_roadmap.md`
/// Phase F). Confirmed directly against `resultRoutes.js`/
/// `resultController.js`.
abstract class ExamResultRepository {
  Future<Result<void>> publishResults({
    required String examId,
    required List<StudentResultInput> results,
  });

  /// Admin: every published result for one exam, with rank + a class-level
  /// summary (pass/fail counts, average %, grade distribution).
  Future<Result<(ClassResultsSummary, List<ExamResult>)>> getExamResults(String examId);

  Future<Result<ResultsSummary>> getMyResultsSummary();

  Future<Result<List<ExamResult>>> getMyResults();

  Future<Result<ExamResult>> getMyResultForExam(String examId);

  Future<Result<ReportCard>> getReportCard({required String examId, required String studentId});

  /// Parent: linked children, reused from `GET /api/parents/me` the same
  /// way `AttendanceRepository.getMyChildren` does — a second, independent
  /// read of the same endpoint rather than importing Attendance's
  /// repository into this unrelated feature.
  Future<Result<List<Student>>> getMyChildren();

  Future<Result<ResultsSummary>> getChildResultsSummary(String studentId);

  Future<Result<List<ExamResult>>> getChildResults(String studentId);
}
