import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/exam.dart';
import '../../data/repositories/exam_repository.dart';

/// Exam scheduling only (create/edit/delete/list) — mirrors
/// `AssignmentProvider`'s shape. Results (System B) live in
/// [ExamResultProvider] instead, a deliberate split matching the backend's
/// own separation between `/api/exams` and `/api/results`.
class ExamProvider extends ChangeNotifier {
  final ExamRepository _repository;

  ExamProvider(this._repository);

  LoadStatus _status = LoadStatus.initial;
  List<Exam> _exams = const [];
  AppException? _error;

  bool _isSaving = false;
  AppException? _actionError;

  LoadStatus get status => _status;
  List<Exam> get exams => _exams;
  AppException? get error => _error;

  bool get isSaving => _isSaving;
  AppException? get actionError => _actionError;

  Future<void> loadExamsAsAdmin() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _repository.getExamsAsAdmin();
    result.when(
      success: (exams) {
        _exams = exams;
        _status = LoadStatus.success;
      },
      failure: (error) {
        _error = error;
        _status = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<void> loadMyExams() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _repository.getMyExams();
    result.when(
      success: (exams) {
        _exams = exams;
        _status = LoadStatus.success;
      },
      failure: (error) {
        _error = error;
        _status = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<bool> createExam({
    required String title,
    required String className,
    String? section,
    required List<ExamSubject> subjects,
    required String examDate,
  }) async {
    _isSaving = true;
    _actionError = null;
    notifyListeners();

    final result = await _repository.createExam(
      title: title,
      className: className,
      section: section,
      subjects: subjects,
      examDate: examDate,
    );
    final succeeded = result.isSuccess;
    result.when(
      success: (created) => _exams = [..._exams, created],
      failure: (error) => _actionError = error,
    );

    _isSaving = false;
    notifyListeners();
    return succeeded;
  }

  Future<bool> deleteExam(String id) async {
    _actionError = null;

    final result = await _repository.deleteExam(id);
    final succeeded = result.isSuccess;
    result.when(
      success: (_) => _exams = _exams.where((e) => e.id != id).toList(),
      failure: (error) => _actionError = error,
    );

    notifyListeners();
    return succeeded;
  }
}
