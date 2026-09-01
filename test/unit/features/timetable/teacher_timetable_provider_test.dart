import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import 'package:cloud_lms/features/timetable/data/models/teacher_schedule_entry.dart';
import 'package:cloud_lms/features/timetable/data/models/timetable_period.dart';
import 'package:cloud_lms/features/timetable/data/repositories/timetable_repository.dart';
import 'package:cloud_lms/features/timetable/presentation/providers/teacher_timetable_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTimetableRepository extends Mock implements TimetableRepository {}

const _entry1 = TeacherScheduleEntry(
  className: 'Class 10',
  section: 'A',
  type: 'fixed',
  day: 'Monday',
  periods: [
    TimetablePeriod(periodNumber: 1, subject: 'Math', teacherId: 'tch1', teacherName: null, startTime: '10:00 AM', endTime: '11:00 AM', room: '101'),
  ],
);

void main() {
  late _MockTimetableRepository repository;
  late TeacherTimetableProvider provider;

  setUp(() {
    repository = _MockTimetableRepository();
    provider = TeacherTimetableProvider(repository);
  });

  test('loadMySchedule(): success populates entries', () async {
    when(() => repository.getTeacherTimetable()).thenAnswer((_) async => const Result.success([_entry1]));

    await provider.loadMySchedule();

    expect(provider.status, LoadStatus.success);
    expect(provider.entries, [_entry1]);
  });

  test('loadMySchedule(): failure sets error status', () async {
    when(() => repository.getTeacherTimetable()).thenAnswer((_) async => const Result.failure(NetworkException()));

    await provider.loadMySchedule();

    expect(provider.status, LoadStatus.error);
    expect(provider.error, isA<NetworkException>());
  });
}
