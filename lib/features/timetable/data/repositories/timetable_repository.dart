import '../../../../core/error/result.dart';
import '../models/my_timetable.dart';
import '../models/teacher_schedule_entry.dart';
import '../models/timetable.dart';
import '../models/timetable_day.dart';

/// `/api/timetable`, confirmed by reading `timetableRoutes.js`/
/// `timetableController.js` directly (`docs/production_roadmap.md` Phase L4,
/// `implementation_backlog.md` E16) — three genuinely different response
/// shapes for three different callers (Admin's raw document, Student's `/my`
/// today+full-week shell, Teacher's `/teacher` flattened own-periods list),
/// not one shape reused three ways.
abstract class TimetableRepository {
  /// Admin only. `type`/`weekNumber`/`year` narrow a `dynamic` timetable to
  /// one specific week; omitted, the backend returns every matching
  /// `fixed`+`dynamic` document for the class/section.
  Future<Result<List<Timetable>>> getTimetables({
    String? className,
    String? section,
    String? type,
    int? weekNumber,
    int? year,
  });

  /// Admin only. This is an **upsert**, not a separate create/update pair —
  /// `createTimetable`'s own `findOneAndUpdate({..filter}, .., {upsert:
  /// true})` confirms there is no dedicated `PUT`/edit route; saving again
  /// for the same (class, section, type, weekNumber, year) replaces the
  /// existing schedule in place.
  Future<Result<Timetable>> saveTimetable({
    required String className,
    required String section,
    String type,
    int? weekNumber,
    int? year,
    required List<TimetableDayInput> schedule,
  });

  Future<Result<void>> deleteTimetable(String id);

  /// Student only. Never fails with "not found" — see [MyTimetable.empty].
  Future<Result<MyTimetable>> getMyTimetable();

  /// Teacher only.
  Future<Result<List<TeacherScheduleEntry>>> getTeacherTimetable();
}
