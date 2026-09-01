import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../admin_management/data/models/student.dart';
import '../../../admin_management/data/repositories/student_repository.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/exam.dart';
import '../../data/models/exam_result.dart';
import '../../data/repositories/exam_result_repository.dart';

/// Owns every System B (Results) concern across all three roles that touch
/// it — Admin (publish + class-level view), Student (own results + report
/// card), Parent (child picker + child's results + report card) — kept as
/// one provider rather than three, since every piece reads through the same
/// [ExamResultRepository] and the state shapes are small enough that
/// splitting further would just be ceremony.
class ExamResultProvider extends ChangeNotifier {
  final ExamResultRepository _repository;
  final StudentRepository _studentRepository;

  ExamResultProvider(this._repository, this._studentRepository);

  // ── Admin: publish ───────────────────────────────────────────────────
  LoadStatus _rosterStatus = LoadStatus.initial;
  List<Student> _roster = const [];
  AppException? _rosterError;
  final Map<String, Map<String, int>> _marks = {}; // studentId -> subject -> obtainedMarks
  final Map<String, String> _remarks = {};
  bool _isPublishing = false;
  AppException? _publishError;
  bool _published = false;

  LoadStatus get rosterStatus => _rosterStatus;
  List<Student> get roster => _roster;
  AppException? get rosterError => _rosterError;
  int? markFor(String studentId, String subject) => _marks[studentId]?[subject];
  bool get isPublishing => _isPublishing;
  AppException? get publishError => _publishError;
  bool get published => _published;

  Future<void> loadRosterForExam(Exam exam) async {
    _rosterStatus = LoadStatus.loading;
    _rosterError = null;
    _marks.clear();
    _remarks.clear();
    _published = false;
    notifyListeners();

    final result = await _studentRepository.getStudents(className: exam.className, section: exam.section);
    result.when(
      success: (roster) {
        _roster = roster;
        _rosterStatus = LoadStatus.success;
      },
      failure: (error) {
        _rosterError = error;
        _rosterStatus = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  void setMark(String studentId, String subject, int? marks) {
    final studentMarks = _marks.putIfAbsent(studentId, () => {});
    if (marks == null) {
      studentMarks.remove(subject);
    } else {
      studentMarks[subject] = marks;
    }
    notifyListeners();
  }

  Future<bool> publish(Exam exam) async {
    _isPublishing = true;
    _publishError = null;
    notifyListeners();

    final results = [
      for (final student in _roster)
        if (_marks[student.id]?.isNotEmpty ?? false)
          StudentResultInput(
            studentId: student.id,
            marks: [
              for (final subject in exam.subjects)
                if (_marks[student.id]?[subject.name] != null)
                  ResultMarkInput(
                    subject: subject.name,
                    obtainedMarks: _marks[student.id]![subject.name]!,
                    fullMarks: subject.fullMarks,
                    passMarks: subject.passMarks,
                  ),
            ],
            remarks: _remarks[student.id],
          ),
    ];

    final result = await _repository.publishResults(examId: exam.id, results: results);
    final succeeded = result.isSuccess;
    result.when(
      success: (_) => _published = true,
      failure: (error) => _publishError = error,
    );

    _isPublishing = false;
    notifyListeners();
    return succeeded;
  }

  // ── Admin: class-level results view ──────────────────────────────────
  LoadStatus _classResultsStatus = LoadStatus.initial;
  ClassResultsSummary? _classSummary;
  List<ExamResult> _classResults = const [];
  AppException? _classResultsError;

  LoadStatus get classResultsStatus => _classResultsStatus;
  ClassResultsSummary? get classSummary => _classSummary;
  List<ExamResult> get classResults => _classResults;
  AppException? get classResultsError => _classResultsError;

  Future<void> loadClassResults(String examId) async {
    _classResultsStatus = LoadStatus.loading;
    _classResultsError = null;
    notifyListeners();

    final result = await _repository.getExamResults(examId);
    result.when(
      success: (data) {
        _classSummary = data.$1;
        _classResults = data.$2;
        _classResultsStatus = LoadStatus.success;
      },
      failure: (error) {
        _classResultsError = error;
        _classResultsStatus = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  // ── Student: my results ──────────────────────────────────────────────
  LoadStatus _myResultsStatus = LoadStatus.initial;
  ResultsSummary? _myResultsSummary;
  List<ExamResult> _myResults = const [];
  AppException? _myResultsError;

  LoadStatus get myResultsStatus => _myResultsStatus;
  ResultsSummary? get myResultsSummary => _myResultsSummary;
  List<ExamResult> get myResults => _myResults;
  AppException? get myResultsError => _myResultsError;

  Future<void> loadMyResults() async {
    _myResultsStatus = LoadStatus.loading;
    _myResultsError = null;
    notifyListeners();

    final summaryResult = await _repository.getMyResultsSummary();
    final listResult = await _repository.getMyResults();
    listResult.when(
      success: (results) {
        _myResults = results;
        summaryResult.when(success: (s) => _myResultsSummary = s, failure: (_) {});
        _myResultsStatus = LoadStatus.success;
      },
      failure: (error) {
        _myResultsError = error;
        _myResultsStatus = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  // ── Student: single-exam result (for the per-exam results screen,
  // distinct from `myResults`'s full history list) ─────────────────────
  LoadStatus _myExamResultStatus = LoadStatus.initial;
  ExamResult? _myExamResult;
  AppException? _myExamResultError;

  LoadStatus get myExamResultStatus => _myExamResultStatus;
  ExamResult? get myExamResult => _myExamResult;
  AppException? get myExamResultError => _myExamResultError;

  Future<void> loadMyResultForExam(String examId) async {
    _myExamResultStatus = LoadStatus.loading;
    _myExamResultError = null;
    notifyListeners();

    final result = await _repository.getMyResultForExam(examId);
    result.when(
      success: (r) {
        _myExamResult = r;
        _myExamResultStatus = LoadStatus.success;
      },
      failure: (error) {
        _myExamResultError = error;
        _myExamResultStatus = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  // ── Report card (shared by Student + Parent) ─────────────────────────
  LoadStatus _reportCardStatus = LoadStatus.initial;
  ReportCard? _reportCard;
  AppException? _reportCardError;

  LoadStatus get reportCardStatus => _reportCardStatus;
  ReportCard? get reportCard => _reportCard;
  AppException? get reportCardError => _reportCardError;

  Future<void> loadReportCard({required String examId, required String studentId}) async {
    _reportCardStatus = LoadStatus.loading;
    _reportCardError = null;
    notifyListeners();

    final result = await _repository.getReportCard(examId: examId, studentId: studentId);
    result.when(
      success: (card) {
        _reportCard = card;
        _reportCardStatus = LoadStatus.success;
      },
      failure: (error) {
        _reportCardError = error;
        _reportCardStatus = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  // ── Parent: child picker + child's results ───────────────────────────
  LoadStatus _childrenStatus = LoadStatus.initial;
  List<Student> _children = const [];
  AppException? _childrenError;
  String? _selectedChildId;

  LoadStatus _childResultsStatus = LoadStatus.initial;
  ResultsSummary? _childResultsSummary;
  List<ExamResult> _childResults = const [];
  AppException? _childResultsError;

  LoadStatus get childrenStatus => _childrenStatus;
  List<Student> get children => _children;
  AppException? get childrenError => _childrenError;
  String? get selectedChildId => _selectedChildId;

  LoadStatus get childResultsStatus => _childResultsStatus;
  ResultsSummary? get childResultsSummary => _childResultsSummary;
  List<ExamResult> get childResults => _childResults;
  AppException? get childResultsError => _childResultsError;

  Future<void> loadChildren() async {
    _childrenStatus = LoadStatus.loading;
    _childrenError = null;
    notifyListeners();

    final result = await _repository.getMyChildren();
    await result.when(
      success: (children) async {
        _children = children;
        _childrenStatus = LoadStatus.success;
        notifyListeners();
        if (children.length == 1) await selectChild(children.single.id);
      },
      failure: (error) async {
        _childrenError = error;
        _childrenStatus = LoadStatus.error;
        notifyListeners();
      },
    );
  }

  Future<void> selectChild(String studentId) async {
    _selectedChildId = studentId;
    _childResultsStatus = LoadStatus.loading;
    _childResultsError = null;
    notifyListeners();

    final summaryResult = await _repository.getChildResultsSummary(studentId);
    final listResult = await _repository.getChildResults(studentId);
    listResult.when(
      success: (results) {
        _childResults = results;
        summaryResult.when(success: (s) => _childResultsSummary = s, failure: (_) {});
        _childResultsStatus = LoadStatus.success;
      },
      failure: (error) {
        _childResultsError = error;
        _childResultsStatus = LoadStatus.error;
      },
    );
    notifyListeners();
  }
}
