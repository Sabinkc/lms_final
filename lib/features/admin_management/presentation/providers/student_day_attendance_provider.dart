import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../attendance/data/models/day_attendance_record.dart';
import '../../../attendance/data/repositories/attendance_repository.dart';
import '../../data/models/student.dart';
import 'academic_structure_provider.dart' show LoadStatus;

/// A student's attendance on the selected day, as shown on the Admin
/// Students screen. `notMarked` = no attendance taken for them that day.
enum DayStatus { present, absent, late, leave, notMarked }

/// Backs the Admin Students screen's date picker, per-student status pills
/// and Present/Absent/Late totals.
///
/// The day endpoint's rows carry no student id (see [DayAttendanceRecord]),
/// so rows are matched to a [Student] by full name within their class and
/// section. A student with several sessions that day (one per subject) gets
/// one combined status: absent if absent from any, else late if late to
/// any, else on leave, else present.
class StudentDayAttendanceProvider extends ChangeNotifier {
  final AttendanceRepository _attendanceRepository;

  StudentDayAttendanceProvider(this._attendanceRepository);

  DateTime _date = _today();
  LoadStatus _status = LoadStatus.initial;
  List<DayAttendanceRecord> _records = const [];
  AppException? _error;

  DateTime get date => _date;
  LoadStatus get status => _status;
  AppException? get error => _error;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static String _iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> load({DateTime? date}) async {
    if (date != null) _date = DateTime(date.year, date.month, date.day);
    final requested = _date;
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _attendanceRepository.getDayRecords(date: _iso(requested));
    if (requested != _date) return; // a newer date was picked meanwhile
    result.when(
      success: (records) {
        _records = records;
        _status = LoadStatus.success;
      },
      failure: (error) {
        _records = const [];
        _error = error;
        _status = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  /// `null` until the day's records have loaded.
  DayStatus? statusFor(Student student) {
    if (_status != LoadStatus.success) return null;
    final name = student.fullName.trim().toLowerCase();
    final classKey = '${student.className} ${student.section}'.trim().toLowerCase();
    final statuses = {
      for (final r in _records)
        if (r.studentName.trim().toLowerCase() == name && r.className.trim().toLowerCase() == classKey) r.status,
    };
    if (statuses.isEmpty) return DayStatus.notMarked;
    if (statuses.contains('absent')) return DayStatus.absent;
    if (statuses.contains('late')) return DayStatus.late;
    if (statuses.contains('leave')) return DayStatus.leave;
    return DayStatus.present;
  }
}
