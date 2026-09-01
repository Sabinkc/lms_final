import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/assignment.dart';
import '../../data/models/assignment_submission.dart';
import '../../data/repositories/assignment_repository.dart';

/// One provider for the whole Assignments feature rather than split by
/// role, unlike Attendance — `GET /api/assignments` is genuinely one
/// endpoint shared by every role (server-side scoping handles the
/// difference), so there's no natural Teacher-state/Admin-state split the
/// way Attendance had. Role-specific actions (create/update/delete/grade
/// vs. submit) still only make sense from their own role's screen, but they
/// all read and write through this same list.
class AssignmentProvider extends ChangeNotifier {
  final AssignmentRepository _repository;

  AssignmentProvider(this._repository);

  LoadStatus _status = LoadStatus.initial;
  List<Assignment> _assignments = const [];
  AppException? _error;

  LoadStatus _detailStatus = LoadStatus.initial;
  Assignment? _currentAssignment;
  AppException? _detailError;

  bool _isSaving = false;
  AppException? _actionError;

  LoadStatus _submissionsStatus = LoadStatus.initial;
  List<AssignmentSubmission> _submissions = const [];
  AppException? _submissionsError;

  bool _isSubmitting = false;
  AppException? _submitError;

  final Set<String> _gradingIds = {};
  AppException? _gradeError;

  LoadStatus get status => _status;
  List<Assignment> get assignments => _assignments;
  AppException? get error => _error;

  LoadStatus get detailStatus => _detailStatus;
  Assignment? get currentAssignment => _currentAssignment;
  AppException? get detailError => _detailError;

  bool get isSaving => _isSaving;
  AppException? get actionError => _actionError;

  LoadStatus get submissionsStatus => _submissionsStatus;
  List<AssignmentSubmission> get submissions => _submissions;
  AppException? get submissionsError => _submissionsError;

  bool get isSubmitting => _isSubmitting;
  AppException? get submitError => _submitError;

  bool isGrading(String submissionId) => _gradingIds.contains(submissionId);
  AppException? get gradeError => _gradeError;

  Future<void> loadAssignments() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _repository.getAssignments();
    result.when(
      success: (assignments) {
        _assignments = assignments;
        _status = LoadStatus.success;
      },
      failure: (error) {
        _error = error;
        _status = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<void> loadAssignmentDetail(String id) async {
    _detailStatus = LoadStatus.loading;
    _detailError = null;
    notifyListeners();

    final result = await _repository.getAssignmentById(id);
    result.when(
      success: (assignment) {
        _currentAssignment = assignment;
        _detailStatus = LoadStatus.success;
      },
      failure: (error) {
        _detailError = error;
        _detailStatus = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<bool> createAssignment({
    required String title,
    required String description,
    required String className,
    required String section,
    required String subject,
    required String dueDate,
  }) async {
    _isSaving = true;
    _actionError = null;
    notifyListeners();

    final result = await _repository.createAssignment(
      title: title,
      description: description,
      className: className,
      section: section,
      subject: subject,
      dueDate: dueDate,
    );
    final succeeded = result.isSuccess;
    result.when(
      success: (created) => _assignments = [..._assignments, created],
      failure: (error) => _actionError = error,
    );

    _isSaving = false;
    notifyListeners();
    return succeeded;
  }

  Future<bool> updateAssignment({
    required String id,
    String? title,
    String? description,
    String? subject,
    String? dueDate,
    String? status,
  }) async {
    _isSaving = true;
    _actionError = null;
    notifyListeners();

    final result = await _repository.updateAssignment(
      id: id,
      title: title,
      description: description,
      subject: subject,
      dueDate: dueDate,
      status: status,
    );
    final succeeded = result.isSuccess;
    result.when(
      success: (updated) {
        _assignments = [for (final a in _assignments) if (a.id == updated.id) updated else a];
        if (_currentAssignment?.id == updated.id) _currentAssignment = updated;
      },
      failure: (error) => _actionError = error,
    );

    _isSaving = false;
    notifyListeners();
    return succeeded;
  }

  Future<bool> deleteAssignment(String id) async {
    _actionError = null;

    final result = await _repository.deleteAssignment(id);
    final succeeded = result.isSuccess;
    result.when(
      success: (_) {
        _assignments = _assignments.where((a) => a.id != id).toList();
        if (_currentAssignment?.id == id) _currentAssignment = null;
      },
      failure: (error) => _actionError = error,
    );

    notifyListeners();
    return succeeded;
  }

  Future<bool> submitAssignment({
    required String assignmentId,
    String? submissionText,
    List<SubmissionFile> files = const [],
  }) async {
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    final result = await _repository.submitAssignment(
      assignmentId: assignmentId,
      submissionText: submissionText,
      files: files,
    );
    final succeeded = result.isSuccess;
    result.when(
      success: (_) {},
      failure: (error) => _submitError = error,
    );

    _isSubmitting = false;
    notifyListeners();
    return succeeded;
  }

  Future<void> loadMySubmissions() async {
    _submissionsStatus = LoadStatus.loading;
    _submissionsError = null;
    notifyListeners();

    final result = await _repository.getMySubmissions();
    result.when(
      success: (submissions) {
        _submissions = submissions;
        _submissionsStatus = LoadStatus.success;
      },
      failure: (error) {
        _submissionsError = error;
        _submissionsStatus = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<void> loadSubmissionsForAssignment(String assignmentId) async {
    _submissionsStatus = LoadStatus.loading;
    _submissionsError = null;
    notifyListeners();

    final result = await _repository.getSubmissionsForAssignment(assignmentId);
    result.when(
      success: (submissions) {
        _submissions = submissions;
        _submissionsStatus = LoadStatus.success;
      },
      failure: (error) {
        _submissionsError = error;
        _submissionsStatus = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<bool> gradeSubmission({required String submissionId, required num marks, String? remarks}) async {
    _gradingIds.add(submissionId);
    _gradeError = null;
    notifyListeners();

    final result = await _repository.gradeSubmission(submissionId: submissionId, marks: marks, remarks: remarks);
    final succeeded = result.isSuccess;
    result.when(
      success: (updated) => _submissions = [for (final s in _submissions) if (s.id == updated.id) updated else s],
      failure: (error) => _gradeError = error,
    );

    _gradingIds.remove(submissionId);
    notifyListeners();
    return succeeded;
  }
}
