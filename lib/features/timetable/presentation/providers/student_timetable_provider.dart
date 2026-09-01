import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/my_timetable.dart';
import '../../data/repositories/timetable_repository.dart';

/// Student: View Own Timetable (`docs/production_roadmap.md` Phase L4,
/// `implementation_backlog.md` E16-F2). Parent is deliberately excluded —
/// no Timetable route exists in Parent's web route list
/// (`docs/frontend_analysis.md` §2).
class StudentTimetableProvider extends ChangeNotifier {
  final TimetableRepository _repository;

  StudentTimetableProvider(this._repository);

  LoadStatus _status = LoadStatus.initial;
  MyTimetable? _timetable;
  AppException? _error;

  LoadStatus get status => _status;
  MyTimetable? get timetable => _timetable;
  AppException? get error => _error;

  Future<void> loadMyTimetable() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _repository.getMyTimetable();
    result.when(
      success: (timetable) {
        _timetable = timetable;
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
