import '../../../../core/error/result.dart';
import '../models/exam.dart';

/// `/api/exams` — Exam CRUD/scheduling only, confirmed directly against
/// `examRoutes.js`/`examController.js`. Results (`/api/exams/publish-results`,
/// `/api/exams/subject-marks`, `/api/exams/my-result/:examId`) are
/// deliberately **not** covered here — this app builds against System B
/// (the separate `Result` collection, `/api/results/*`), see
/// `ExamResultRepository` and `docs/production_roadmap.md` Phase F.
abstract class ExamRepository {
  Future<Result<List<Exam>>> getExamsAsAdmin();

  Future<Result<List<Exam>>> getMyExams();

  Future<Result<Exam>> createExam({
    required String title,
    required String className,
    String? section,
    required List<ExamSubject> subjects,
    required String examDate,
  });

  Future<Result<Exam>> updateExam({
    required String id,
    String? title,
    String? className,
    String? section,
    List<ExamSubject>? subjects,
    String? examDate,
    String? status,
  });

  Future<Result<void>> deleteExam(String id);
}
