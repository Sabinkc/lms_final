import '../../../../core/error/app_exception.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../models/my_timetable.dart';
import '../models/teacher_schedule_entry.dart';
import '../models/timetable.dart';
import '../models/timetable_day.dart';
import 'timetable_repository.dart';

class TimetableRepositoryHttp implements TimetableRepository {
  final ApiClient _apiClient;

  TimetableRepositoryHttp(this._apiClient);

  @override
  Future<Result<List<Timetable>>> getTimetables({
    String? className,
    String? section,
    String? type,
    int? weekNumber,
    int? year,
  }) async {
    try {
      final timetables = await _apiClient.get<List<Timetable>>(
        '/timetable',
        queryParameters: {
          if (className != null) 'className': className,
          if (section != null) 'section': section,
          if (type != null) 'type': type,
          if (weekNumber != null) 'weekNumber': weekNumber,
          if (year != null) 'year': year,
        },
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => Timetable.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(timetables);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<Timetable>> saveTimetable({
    required String className,
    required String section,
    String type = 'fixed',
    int? weekNumber,
    int? year,
    required List<TimetableDayInput> schedule,
  }) async {
    try {
      final saved = await _apiClient.post<Timetable>(
        '/timetable',
        data: {
          'className': className,
          'section': section,
          'type': type,
          if (weekNumber != null) 'weekNumber': weekNumber,
          if (year != null) 'year': year,
          'schedule': schedule.map((d) => d.toJson()).toList(),
        },
        parse: (data) => Timetable.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(saved);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<void>> deleteTimetable(String id) async {
    try {
      await _apiClient.delete<void>('/timetable/$id');
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<MyTimetable>> getMyTimetable() async {
    try {
      final timetable = await _apiClient.get<MyTimetable>(
        '/timetable/my',
        parse: (data) => MyTimetable.fromJson(data as Map<String, dynamic>),
      );
      return Result.success(timetable);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<List<TeacherScheduleEntry>>> getTeacherTimetable() async {
    try {
      final entries = await _apiClient.get<List<TeacherScheduleEntry>>(
        '/timetable/teacher',
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => TeacherScheduleEntry.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(entries);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
