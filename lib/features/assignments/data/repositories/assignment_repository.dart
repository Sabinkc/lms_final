import 'dart:typed_data';

import '../../../../core/error/result.dart';
import '../models/assignment.dart';
import '../models/assignment_submission.dart';

class SubmissionFile {
  final Uint8List bytes;
  final String filename;

  const SubmissionFile({required this.bytes, required this.filename});
}

/// `/api/assignments` — System A, `protect`-guarded throughout (the
/// controller resolves Teacher/Student/Parent/Admin identity from the token
/// itself, so one endpoint serves every role differently server-side).
/// Confirmed directly against `assignmentRoutes.js`/`assignmentController.js`.
abstract class AssignmentRepository {
  /// Role-scoped entirely server-side on the same call: a Teacher sees only
  /// their own assignments, a Student sees their own class's active ones, a
  /// Parent sees the union of all their children's classes' active ones, an
  /// Admin sees every assignment in the school.
  Future<Result<List<Assignment>>> getAssignments();

  Future<Result<Assignment>> getAssignmentById(String id);

  /// [className]/[section] are submitted as plain strings, not [sectionId] —
  /// deliberately: the backend's `sectionId` path gates on the teacher
  /// actually being a member of `Section.teachers`
  /// (`Section.service.js`'s `assertTeacherInSection`), which nothing in
  /// Phase B populates yet. The class/section-string path has no such gate,
  /// matching how Students are created (`admin_management`'s pattern).
  Future<Result<Assignment>> createAssignment({
    required String title,
    required String description,
    required String className,
    required String section,
    required String subject,
    required String dueDate,
  });

  Future<Result<Assignment>> updateAssignment({
    required String id,
    String? title,
    String? description,
    String? subject,
    String? dueDate,
    String? status,
  });

  /// Also deletes every submission for this assignment server-side
  /// (`deleteAssignment`) — not something the client needs to do separately.
  Future<Result<void>> deleteAssignment(String id);

  /// Confirmed rule (`submitAssignment`): a first submission is blocked once
  /// [Assignment.dueDate] has passed, but a **resubmission** is allowed any
  /// time before grading regardless of the due date — until
  /// `AssignmentSubmission.gradedAt` is set, at which point the backend
  /// 409s. [files] only replace previously-uploaded attachments when
  /// non-empty; a text-only resubmit preserves the prior files.
  Future<Result<AssignmentSubmission>> submitAssignment({
    required String assignmentId,
    String? submissionText,
    List<SubmissionFile> files = const [],
  });

  Future<Result<List<AssignmentSubmission>>> getMySubmissions();

  Future<Result<List<AssignmentSubmission>>> getSubmissionsForAssignment(String assignmentId);

  Future<Result<AssignmentSubmission>> gradeSubmission({
    required String submissionId,
    required num marks,
    String? remarks,
  });
}
