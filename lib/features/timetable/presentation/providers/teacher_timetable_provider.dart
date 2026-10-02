import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/teacher_schedule_entry.dart';
import '../../data/repositories/timetable_repository.dart';

/// Teacher: View Own Timetable (`docs/production_roadmap.md` Phase L4,
/// `implementation_backlog.md` E16-F2).
class TeacherTimetableProvider extends ChangeNotifier {
  final TimetableRepository _repository;

  TeacherTimetableProvider(this._repository);

  LoadStatus _status = LoadStatus.initial;
  List<TeacherScheduleEntry> _entries = const [];
  AppException? _error;

  LoadStatus get status => _status;
  List<TeacherScheduleEntry> get entries => _entries;
  AppException? get error => _error;

  Future<void> loadMySchedule({bool silent = false}) async {
    // A silent reload (pull-to-refresh) keeps the current data on screen.
    if (!silent || _status != LoadStatus.success) _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _repository.getTeacherTimetable();
    result.when(
      success: (entries) {
        _entries = entries;
        _status = LoadStatus.success;
      },
      failure: (error) {
        _error = error;
        _status = LoadStatus.error;
      },
    );
    notifyListeners();
  }
}
