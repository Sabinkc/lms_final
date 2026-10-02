import '../../../../core/error/app_exception.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../../../admin_management/data/models/student.dart';
import '../models/day_attendance_record.dart';
import '../models/attendance_session.dart';
import '../models/attendance_submit_result.dart';
import '../models/student_attendance_history.dart';
import '../models/teacher_section.dart';
import 'attendance_repository.dart';

class AttendanceRepositoryHttp implements AttendanceRepository {
  final ApiClient _apiClient;

  AttendanceRepositoryHttp(this._apiClient);

  @override
  Future<Result<List<TeacherSection>>> getMySections() async {
    try {
      final sections = await _apiClient.get<List<TeacherSection>>(
        '/sections/my/teacher',
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => TeacherSection.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(sections);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<List<Student>>> getSectionRoster(String sectionId) async {
    try {
      final students = await _apiClient.get<List<Student>>(
        '/sections/$sectionId/students',
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => Student.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(students);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<AttendanceSubmitResult>> markAttendance({
    required String sectionId,
    required String date,
    String? subject,
    required List<AttendanceRecordInput> records,
  }) async {
    try {
      final result = await _apiClient.post<AttendanceSubmitResult>(
        '/attendance/student',
        data: {
          'sectionId': sectionId,
          'date': date,
          if (subject != null && subject.isNotEmpty) 'subject': subject,
          'records': [
            for (final r in records)
              {
                'studentId': r.studentId,
                'status': r.status.apiValue,
                if (r.remarks != null && r.remarks!.isNotEmpty) 'remarks': r.remarks,
              },
          ],
        },
        parse: (data) =>
            AttendanceSubmitResult.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(result);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<List<AttendanceSessionSummary>>> getSessions({
    required String date,
    String? className,
    String? section,
    String? subject,
  }) async {
    try {
      final sessions = await _apiClient.get<List<AttendanceSessionSummary>>(
        '/attendance/student',
        queryParameters: {
          'date': date,
          if (className != null && className.isNotEmpty) 'class': className,
          if (section != null && section.isNotEmpty) 'section': section,
          if (subject != null && subject.isNotEmpty) 'subject': subject,
        },
        parse: (data) {
          final rows = ((data as Map<String, dynamic>)['data'] as List).cast<Map<String, dynamic>>();
          // Real session documents carry counts; what the live API returns
          // is per-student rows (see AttendanceSessionSummary's doc), which
          // get grouped per class.
          if (rows.isEmpty || rows.first.containsKey('presentCount')) {
            return rows.map(AttendanceSessionSummary.fromJson).toList();
          }
          return AttendanceSessionSummary.fromDayRecords(rows.map(DayAttendanceRecord.fromJson).toList());
        },
      );
      return Result.success(sessions);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<String>> getMyStudentId() async {
    try {
      final id = await _apiClient.get<String>(
        '/attendance/me',
        parse: (data) => ((data as Map<String, dynamic>)['data'] as Map<String, dynamic>)['_id'] as String,
      );
      return Result.success(id);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<List<Student>>> getMyChildren() async {
    try {
      final children = await _apiClient.get<List<Student>>(
        '/parents/me',
        parse: (data) {
          final students =
              (((data as Map<String, dynamic>)['data'] as Map<String, dynamic>)['students'] as List?) ?? const [];
          return students.map((s) => Student.fromJson(s as Map<String, dynamic>)).toList();
        },
      );
      return Result.success(children);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<StudentAttendanceHistory>> getStudentAttendanceHistory({
    required String studentId,
    String? month,
    String? year,
  }) async {
    try {
      final history = await _apiClient.get<StudentAttendanceHistory>(
        '/attendance/student/$studentId',
        queryParameters: {if (month != null) 'month': month, if (year != null) 'year': year},
        parse: (data) => StudentAttendanceHistory.fromJson(data as Map<String, dynamic>),
      );
      return Result.success(history);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<List<DayAttendanceRecord>>> getDayRecords({required String date, String? className}) async {
    try {
      final records = await _apiClient.get<List<DayAttendanceRecord>>(
        '/attendance/student',
        queryParameters: {
          'date': date,
          if (className != null && className.isNotEmpty) 'class': className,
          // The endpoint paginates; ask for everything in one page.
          'limit': 1000,
        },
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => DayAttendanceRecord.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(records);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
