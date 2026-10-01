import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/student.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/student_day_attendance_provider.dart';
import 'package:cloud_lms/features/attendance/data/models/day_attendance_record.dart';
import 'package:cloud_lms/features/attendance/data/repositories/attendance_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAttendanceRepository extends Mock implements AttendanceRepository {}

Student _s(String name, String cls, String section) => Student(
      id: name,
      fullName: name,
      email: '',
      admissionNumber: '',
      rollNumber: '',
      className: cls,
      section: section,
      parentId: null,
      dob: '',
      address: '',
      phone: '',
      status: 'active',
    );

DayAttendanceRecord _r(String name, String cls, String status) =>
    DayAttendanceRecord(date: '2026-09-05', status: status, studentName: name, className: cls);

void main() {
  test('combines several sessions into one status and only matches the same class+section', () async {
    final repository = _MockAttendanceRepository();
    when(() => repository.getDayRecords(date: '2026-09-05', className: any(named: 'className')))
        .thenAnswer((_) async => Result.success([
              _r('Sam', 'Class 10 A', 'present'),
              _r('Sam', 'Class 10 A', 'late'),
              _r('Amy', 'Class 10 A', 'present'),
              _r('Amy', 'Class 10 A', 'absent'),
              _r('Tom', 'Class 10 A', 'present'),
              _r('Tom', 'Class 9 B', 'absent'), // a different Tom
            ]));
    final provider = StudentDayAttendanceProvider(repository);

    expect(provider.statusFor(_s('Sam', 'Class 10', 'A')), isNull); // not loaded yet
    await provider.load(date: DateTime(2026, 9, 5));

    expect(provider.statusFor(_s('Sam', 'Class 10', 'A')), DayStatus.late);
    expect(provider.statusFor(_s('Amy', 'Class 10', 'A')), DayStatus.absent);
    expect(provider.statusFor(_s('Tom', 'Class 10', 'A')), DayStatus.present);
    expect(provider.statusFor(_s('Nobody', 'Class 10', 'A')), DayStatus.notMarked);
  });
}
