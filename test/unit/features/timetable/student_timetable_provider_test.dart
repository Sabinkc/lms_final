import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import 'package:cloud_lms/features/timetable/data/models/my_timetable.dart';
import 'package:cloud_lms/features/timetable/data/models/timetable_day.dart';
import 'package:cloud_lms/features/timetable/data/repositories/timetable_repository.dart';
import 'package:cloud_lms/features/timetable/presentation/providers/student_timetable_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTimetableRepository extends Mock implements TimetableRepository {}

const _myTimetable = MyTimetable(
  empty: false,
  type: 'fixed',
  weekNumber: null,
  today: 'Monday',
  todaySchedule: TimetableDay(day: 'Monday', periods: []),
  fullSchedule: [],
);

void main() {
  late _MockTimetableRepository repository;
  late StudentTimetableProvider provider;

  setUp(() {
    repository = _MockTimetableRepository();
    provider = StudentTimetableProvider(repository);
  });

  test('loadMyTimetable(): success populates the timetable', () async {
    when(() => repository.getMyTimetable()).thenAnswer((_) async => const Result.success(_myTimetable));

    await provider.loadMyTimetable();

    expect(provider.status, LoadStatus.success);
    expect(provider.timetable, _myTimetable);
  });

  test('loadMyTimetable(): failure sets error status', () async {
    when(() => repository.getMyTimetable()).thenAnswer((_) async => const Result.failure(NetworkException()));

    await provider.loadMyTimetable();

    expect(provider.status, LoadStatus.error);
    expect(provider.error, isA<NetworkException>());
  });
}
