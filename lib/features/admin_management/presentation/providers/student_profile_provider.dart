import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../attendance/data/models/student_attendance_history.dart';
import '../../../attendance/data/repositories/attendance_repository.dart';
import '../../../fees/data/models/fee.dart';
import '../../../fees/data/repositories/fee_repository.dart';
import '../../data/models/student.dart';
import '../../data/repositories/class_repository.dart';
import '../../data/repositories/section_repository.dart';
import 'academic_structure_provider.dart' show LoadStatus;

/// Per-student data for the Admin Student Profile screen that isn't on the
/// [Student] record itself: attendance history, fees, and the teachers
/// assigned to the student's section. Each loads independently so one
/// failing (or being slow) doesn't blank the others.
///
/// Uses the repositories directly rather than `AcademicStructureProvider`,
/// whose single "currently selected class" sections state backs the Class
/// Details screen that may sit underneath this one in the navigation stack.
class StudentProfileProvider extends ChangeNotifier {
  final AttendanceRepository _attendanceRepository;
  final FeeRepository _feeRepository;
  final ClassRepository _classRepository;
  final SectionRepository _sectionRepository;

  StudentProfileProvider(
    this._attendanceRepository,
    this._feeRepository,
    this._classRepository,
    this._sectionRepository,
  );

  String? _studentId;

  LoadStatus _attendanceStatus = LoadStatus.initial;
  StudentAttendanceHistory? _attendance;
  AppException? _attendanceError;

  LoadStatus _feesStatus = LoadStatus.initial;
  FeesSummary? _feesSummary;
  List<Fee> _fees = const [];
  AppException? _feesError;

  /// `null` until resolved; empty when the section has none (or the
  /// student's class/section can't be matched to a real one).
  List<String>? _sectionTeacherIds;

  String? get studentId => _studentId;
  LoadStatus get attendanceStatus => _attendanceStatus;
  StudentAttendanceHistory? get attendance => _attendance;
  AppException? get attendanceError => _attendanceError;
  LoadStatus get feesStatus => _feesStatus;
  FeesSummary? get feesSummary => _feesSummary;
  List<Fee> get fees => _fees;
  AppException? get feesError => _feesError;
  List<String>? get sectionTeacherIds => _sectionTeacherIds;

  /// Resets everything for [student] and loads all three in parallel.
  Future<void> load(Student student) async {
    _studentId = student.id;
    _attendance = null;
    _feesSummary = null;
    _fees = const [];
    _sectionTeacherIds = null;
    await Future.wait([loadAttendance(), loadFees(), _loadSectionTeachers(student)]);
  }

  Future<void> loadAttendance() async {
    final id = _studentId;
    if (id == null) return;
    _attendanceStatus = LoadStatus.loading;
    _attendanceError = null;
    notifyListeners();

    final result = await _attendanceRepository.getStudentAttendanceHistory(studentId: id);
    if (id != _studentId) return;
    result.when(
      success: (history) {
        _attendance = history;
        _attendanceStatus = LoadStatus.success;
      },
      failure: (error) {
        _attendanceError = error;
        _attendanceStatus = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<void> loadFees() async {
    final id = _studentId;
    if (id == null) return;
    _feesStatus = LoadStatus.loading;
    _feesError = null;
    notifyListeners();

    final result = await _feeRepository.getStudentFees(id);
    if (id != _studentId) return;
    result.when(
      success: (data) {
        final (summary, _, fees) = data;
        _feesSummary = summary;
        _fees = fees;
        _feesStatus = LoadStatus.success;
      },
      failure: (error) {
        _feesError = error;
        _feesStatus = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  /// Student `class`/`section` are free-text names, not refs, so this
  /// matches them by name against the real classes and sections.
  Future<void> _loadSectionTeachers(Student student) async {
    final id = student.id;
    List<String> found = const [];
    final classes = await _classRepository.getClasses();
    final classMatch = classes.when(
      success: (list) => list.where((c) => c.name == student.className).firstOrNull,
      failure: (_) => null,
    );
    if (classMatch != null) {
      final sections = await _sectionRepository.getSections(classMatch.id);
      found = sections.when(
        success: (list) => list.where((s) => s.name == student.section).firstOrNull?.teacherIds ?? const [],
        failure: (_) => const [],
      );
    }
    if (id != _studentId) return;
    _sectionTeacherIds = found;
    notifyListeners();
  }
}
