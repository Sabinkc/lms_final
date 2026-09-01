import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/timetable.dart';
import '../../data/models/timetable_day.dart';
import '../../data/repositories/timetable_repository.dart';

/// Admin: Manage Timetable (`docs/production_roadmap.md` Phase L4,
/// `implementation_backlog.md` E16-F1). One class+section's `fixed`
/// timetable at a time — [loadTimetable] resolves whichever single document
/// matches, since `saveTimetable` is an upsert keyed on exactly that
/// (class, section, type) combination.
class AdminTimetableProvider extends ChangeNotifier {
  final TimetableRepository _repository;

  AdminTimetableProvider(this._repository);

  LoadStatus _status = LoadStatus.initial;
  Timetable? _current;
  AppException? _error;

  bool _isSaving = false;
  AppException? _actionError;

  LoadStatus get status => _status;
  Timetable? get current => _current;
  AppException? get error => _error;

  bool get isSaving => _isSaving;
  AppException? get actionError => _actionError;

  Future<void> loadTimetable(String className, String section) async {
    _status = LoadStatus.loading;
    _error = null;
    _current = null;
    notifyListeners();

    final result = await _repository.getTimetables(className: className, section: section, type: 'fixed');
    result.when(
      success: (timetables) {
        _current = timetables.isEmpty ? null : timetables.first;
        _status = LoadStatus.success;
      },
      failure: (error) {
        _error = error;
        _status = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<bool> saveTimetable({
    required String className,
    required String section,
    required List<TimetableDayInput> schedule,
  }) async {
    _isSaving = true;
    _actionError = null;
    notifyListeners();

    final result = await _repository.saveTimetable(className: className, section: section, schedule: schedule);
    final succeeded = result.isSuccess;
    result.when(
      success: (saved) => _current = saved,
      failure: (error) => _actionError = error,
    );

    _isSaving = false;
    notifyListeners();
    return succeeded;
  }

  Future<bool> deleteTimetable(String id) async {
    _actionError = null;

    final result = await _repository.deleteTimetable(id);
    final succeeded = result.isSuccess;
    result.when(
      success: (_) => _current = null,
      failure: (error) => _actionError = error,
    );

    notifyListeners();
    return succeeded;
  }
}
