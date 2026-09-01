import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import 'package:cloud_lms/features/timetable/data/models/timetable.dart';
import 'package:cloud_lms/features/timetable/data/models/timetable_day.dart';
import 'package:cloud_lms/features/timetable/data/models/timetable_period.dart';
import 'package:cloud_lms/features/timetable/data/repositories/timetable_repository.dart';
import 'package:cloud_lms/features/timetable/presentation/providers/admin_timetable_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTimetableRepository extends Mock implements TimetableRepository {}

const _timetable1 = Timetable(
  id: 't1',
  className: 'Class 10',
  section: 'A',
  type: 'fixed',
  weekNumber: null,
  year: 2026,
  schedule: [
    TimetableDay(
      day: 'Monday',
      periods: [
        TimetablePeriod(periodNumber: 1, subject: 'Math', teacherId: 'tch1', teacherName: 'Jane Teacher', startTime: '10:00 AM', endTime: '11:00 AM', room: '101'),
      ],
    ),
  ],
);

void main() {
  late _MockTimetableRepository repository;
  late AdminTimetableProvider provider;

  setUp(() {
    repository = _MockTimetableRepository();
    provider = AdminTimetableProvider(repository);
  });

  test('loadTimetable(): a match sets current and success status', () async {
    when(() => repository.getTimetables(className: 'Class 10', section: 'A', type: 'fixed'))
        .thenAnswer((_) async => const Result.success([_timetable1]));

    await provider.loadTimetable('Class 10', 'A');

    expect(provider.status, LoadStatus.success);
    expect(provider.current, _timetable1);
  });

  test('loadTimetable(): no match yet leaves current null with success status (not an error)', () async {
    when(() => repository.getTimetables(className: any(named: 'className'), section: any(named: 'section'), type: any(named: 'type')))
        .thenAnswer((_) async => const Result.success([]));

    await provider.loadTimetable('Class 10', 'B');

    expect(provider.status, LoadStatus.success);
    expect(provider.current, isNull);
  });

  test('loadTimetable(): failure sets error status', () async {
    when(() => repository.getTimetables(className: any(named: 'className'), section: any(named: 'section'), type: any(named: 'type')))
        .thenAnswer((_) async => const Result.failure(NetworkException()));

    await provider.loadTimetable('Class 10', 'A');

    expect(provider.status, LoadStatus.error);
    expect(provider.error, isA<NetworkException>());
  });

  test('saveTimetable(): success stores the saved document and returns true', () async {
    when(
      () => repository.saveTimetable(
        className: any(named: 'className'),
        section: any(named: 'section'),
        schedule: any(named: 'schedule'),
      ),
    ).thenAnswer((_) async => const Result.success(_timetable1));

    final succeeded = await provider.saveTimetable(className: 'Class 10', section: 'A', schedule: const []);

    expect(succeeded, isTrue);
    expect(provider.current, _timetable1);
    expect(provider.isSaving, isFalse);
  });

  test('saveTimetable(): failure returns false and exposes the action error', () async {
    when(
      () => repository.saveTimetable(
        className: any(named: 'className'),
        section: any(named: 'section'),
        schedule: any(named: 'schedule'),
      ),
    ).thenAnswer((_) async => const Result.failure(ValidationException('className, section and schedule are required')));

    final succeeded = await provider.saveTimetable(className: 'Class 10', section: 'A', schedule: const []);

    expect(succeeded, isFalse);
    expect(provider.actionError, isA<ValidationException>());
  });

  test('deleteTimetable(): success clears current', () async {
    when(() => repository.getTimetables(className: 'Class 10', section: 'A', type: 'fixed'))
        .thenAnswer((_) async => const Result.success([_timetable1]));
    await provider.loadTimetable('Class 10', 'A');

    when(() => repository.deleteTimetable('t1')).thenAnswer((_) async => const Result.success(null));

    final succeeded = await provider.deleteTimetable('t1');

    expect(succeeded, isTrue);
    expect(provider.current, isNull);
  });
}
