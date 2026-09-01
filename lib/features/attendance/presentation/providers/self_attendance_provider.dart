import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../admin_management/data/models/student.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/student_attendance_history.dart';
import '../../data/repositories/attendance_repository.dart';

/// Backs both Student "My Attendance" and Parent "Child's Attendance" —
/// one provider, not two, since both screens are the same
/// history-for-a-studentId view, just differing in how that id is resolved
/// (the caller's own profile vs. a picked child). Kept separate from the
/// Teacher-facing [AttendanceProvider] and Admin-facing
/// [AdminAttendanceProvider] since its role/error states are distinct even
/// though it shares the same [AttendanceRepository].
class SelfAttendanceProvider extends ChangeNotifier {
  final AttendanceRepository _repository;

  SelfAttendanceProvider(this._repository);

  LoadStatus _childrenStatus = LoadStatus.initial;
  List<Student> _children = const [];
  AppException? _childrenError;
  String? _selectedChildId;

  LoadStatus _historyStatus = LoadStatus.initial;
  StudentAttendanceHistory? _history;
  AppException? _historyError;

  LoadStatus get childrenStatus => _childrenStatus;
  List<Student> get children => _children;
  AppException? get childrenError => _childrenError;
  String? get selectedChildId => _selectedChildId;

  LoadStatus get historyStatus => _historyStatus;
  StudentAttendanceHistory? get history => _history;
  AppException? get historyError => _historyError;

  /// Student role entry point: resolves the caller's own `Student._id` via
  /// `GET /api/attendance/me`, then loads that student's history directly —
  /// no picker needed, a Student only ever has one attendance record set
  /// (their own).
  Future<void> loadOwnHistory({String? month, String? year}) async {
    _historyStatus = LoadStatus.loading;
    _historyError = null;
    notifyListeners();

    final idResult = await _repository.getMyStudentId();
    await idResult.when(
      success: (id) => _loadHistoryFor(id, month: month, year: year),
      failure: (error) async {
        _historyError = error;
        _historyStatus = LoadStatus.error;
        notifyListeners();
      },
    );
  }

  /// Parent role entry point: loads the linked-children picker. Auto-selects
  /// and loads history immediately when there's exactly one child — the
  /// common case — so a Parent with one child doesn't have to make a
  /// pointless selection.
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

  Future<void> selectChild(String studentId, {String? month, String? year}) async {
    _selectedChildId = studentId;
    await _loadHistoryFor(studentId, month: month, year: year);
  }

  Future<void> _loadHistoryFor(String studentId, {String? month, String? year}) async {
    _historyStatus = LoadStatus.loading;
    _historyError = null;
    notifyListeners();

    final result = await _repository.getStudentAttendanceHistory(studentId: studentId, month: month, year: year);
    result.when(
      success: (history) {
        _history = history;
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
