import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../admin_management/data/models/student.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/attendance_session.dart';
import '../../data/models/attendance_status.dart';
import '../../data/models/attendance_submit_result.dart';
import '../../data/models/teacher_section.dart';
import '../../data/repositories/attendance_repository.dart';

/// Owns both Mark Attendance and Attendance History state — kept together
/// (not two providers) because they're one cohesive Teacher flow reading the
/// same repository, mirroring `AcademicStructureProvider`'s
/// Classes+Sections pairing.
class AttendanceProvider extends ChangeNotifier {
  final AttendanceRepository _repository;

  AttendanceProvider(this._repository);

  LoadStatus _sectionsStatus = LoadStatus.initial;
  List<TeacherSection> _sections = const [];
  AppException? _sectionsError;

  LoadStatus _rosterStatus = LoadStatus.initial;
  List<Student> _roster = const [];
  AppException? _rosterError;
  final Map<String, AttendanceStatus> _statuses = {};
  final Map<String, String> _remarks = {};

  bool _isSubmitting = false;
  AppException? _submitError;
  AttendanceSubmitResult? _lastSubmitResult;

  LoadStatus _historyStatus = LoadStatus.initial;
  List<AttendanceSessionSummary> _historySessions = const [];
  AppException? _historyError;

  LoadStatus get sectionsStatus => _sectionsStatus;
  List<TeacherSection> get sections => _sections;
  AppException? get sectionsError => _sectionsError;

  LoadStatus get rosterStatus => _rosterStatus;
  List<Student> get roster => _roster;
  AppException? get rosterError => _rosterError;
  AttendanceStatus statusFor(String studentId) => _statuses[studentId] ?? AttendanceStatus.present;
  String remarksFor(String studentId) => _remarks[studentId] ?? '';

  bool get isSubmitting => _isSubmitting;
  AppException? get submitError => _submitError;
  AttendanceSubmitResult? get lastSubmitResult => _lastSubmitResult;

  LoadStatus get historyStatus => _historyStatus;
  List<AttendanceSessionSummary> get historySessions => _historySessions;
  AppException? get historyError => _historyError;

  Future<void> loadMySections() async {
    _sectionsStatus = LoadStatus.loading;
    _sectionsError = null;
    notifyListeners();

    final result = await _repository.getMySections();
    result.when(
      success: (sections) {
        _sections = sections;
        _sectionsStatus = LoadStatus.success;
      },
      failure: (error) {
        _sectionsError = error;
        _sectionsStatus = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<void> loadRoster(String sectionId) async {
    _rosterStatus = LoadStatus.loading;
    _rosterError = null;
    _statuses.clear();
    _remarks.clear();
    _lastSubmitResult = null;
    _submitError = null;
    notifyListeners();

    final result = await _repository.getSectionRoster(sectionId);
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

  void setStatus(String studentId, AttendanceStatus status) {
    _statuses[studentId] = status;
    notifyListeners();
  }

  void setRemarks(String studentId, String remarks) {
    _remarks[studentId] = remarks;
  }

  Future<bool> submit({required String sectionId, required String date, String? subject}) async {
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    final result = await _repository.markAttendance(
      sectionId: sectionId,
      date: date,
      subject: subject,
      records: [
        for (final student in _roster)
          AttendanceRecordInput(
            studentId: student.id,
            status: statusFor(student.id),
            remarks: _remarks[student.id],
          ),
      ],
    );
    final succeeded = result.isSuccess;
    result.when(
      success: (submitResult) => _lastSubmitResult = submitResult,
      failure: (error) => _submitError = error,
    );

    _isSubmitting = false;
    notifyListeners();
    return succeeded;
  }

  Future<void> loadHistory(String date) async {
    _historyStatus = LoadStatus.loading;
    _historyError = null;
    notifyListeners();

    final result = await _repository.getSessions(date: date);
    result.when(
      success: (sessions) {
        _historySessions = sessions;
        _historyStatus = LoadStatus.success;
      },
      failure: (error) {
        _historyError = error;
        _historyStatus = LoadStatus.error;
      },
    );
    notifyListeners();
  }
}
