import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/academic_class.dart';
import 'package:cloud_lms/features/admin_management/data/models/class_section.dart';
import 'package:cloud_lms/features/admin_management/data/models/student.dart';
import 'package:cloud_lms/features/admin_management/data/models/teacher.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/class_repository.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/section_repository.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/student_repository.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/teacher_repository.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/student_profile_provider.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/student_provider.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/teacher_provider.dart';
import 'package:cloud_lms/features/admin_management/presentation/screens/student_profile_screen.dart';
import 'package:cloud_lms/features/attendance/data/models/student_attendance_history.dart';
import 'package:cloud_lms/features/attendance/data/repositories/attendance_repository.dart';
import 'package:cloud_lms/features/fees/data/models/fee.dart';
import 'package:cloud_lms/features/fees/data/repositories/fee_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockClassRepository extends Mock implements ClassRepository {}

class _MockSectionRepository extends Mock implements SectionRepository {}

class _MockStudentRepository extends Mock implements StudentRepository {}

class _MockTeacherRepository extends Mock implements TeacherRepository {}

class _MockAttendanceRepository extends Mock implements AttendanceRepository {}

class _MockFeeRepository extends Mock implements FeeRepository {}

const _student = Student(
  id: 's1',
  fullName: 'Sam Student',
  email: 'sam@school.test',
  admissionNumber: 'ADM001',
  rollNumber: '12',
  className: 'Class 10',
  section: 'A',
  parentId: 'p1',
  dob: '',
  address: '',
  phone: '',
  status: 'active',
  gender: 'male',
  parentName: 'Pat Parent',
);

void main() {
  testWidgets('shows real profile, section teacher, attendance and fees; no placeholder rows', (tester) async {
    final classRepository = _MockClassRepository();
    final sectionRepository = _MockSectionRepository();
    final studentRepository = _MockStudentRepository();
    final teacherRepository = _MockTeacherRepository();
    final attendanceRepository = _MockAttendanceRepository();
    final feeRepository = _MockFeeRepository();

    when(() => studentRepository.getStudents(className: any(named: 'className'), section: any(named: 'section')))
        .thenAnswer((_) async => const Result.success([_student]));
    when(() => classRepository.getClasses()).thenAnswer((_) async =>
        const Result.success([AcademicClass(id: 'c1', name: 'Class 10', description: '', status: 'active')]));
    when(() => sectionRepository.getSections('c1')).thenAnswer((_) async => const Result.success([
          ClassSection(id: 'sa', name: 'A', classId: 'c1', status: 'active', teacherIds: ['t1']),
        ]));
    when(() => teacherRepository.getTeachers()).thenAnswer((_) async => const Result.success([
          Teacher(
            id: 't1',
            fullName: 'Ben Teacher',
            email: '',
            employeeId: '',
            department: '',
            designation: '',
            qualification: '',
            subjects: [],
            experience: 0,
            salary: 0,
            address: '',
            phone: '',
            bankAccountNumber: '',
            status: 'active',
          ),
        ]));
    when(() => attendanceRepository.getStudentAttendanceHistory(studentId: 's1')).thenAnswer((_) async =>
        const Result.success(StudentAttendanceHistory(
          studentName: 'Sam Student',
          summary: AttendanceHistorySummary(present: 9, absent: 1, late: 0, leave: 0, halfDay: 0, total: 10, percentage: 90),
          records: [
            AttendanceRecordDetail(
              id: 'r1',
              status: 'present',
              remarks: '',
              date: '2026-09-05',
              subject: 'General',
              className: 'Class 10',
              section: 'A',
            ),
          ],
        )));
    when(() => feeRepository.getStudentFees('s1')).thenAnswer((_) async => const Result.success((
          FeesSummary(total: 1, pending: 1, partial: 0, paid: 0, totalDue: 5000),
          null,
          [
            Fee(
              id: 'f1',
              studentId: 's1',
              studentName: null,
              admissionNumber: null,
              className: null,
              section: null,
              title: 'Tuition Fee',
              description: '',
              totalAmount: 5000,
              discountPercent: 0,
              discountAmount: 0,
              paidAmount: 0,
              remainingAmount: 5000,
              dueDate: '2026-10-05T00:00:00.000Z',
              isInstallment: false,
              installments: [],
              status: 'pending',
            ),
          ],
        )));

    await tester.binding.setSurfaceSize(const Size(420, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: StudentProvider(studentRepository, classRepository, sectionRepository)),
        ChangeNotifierProvider.value(value: TeacherProvider(teacherRepository)),
        ChangeNotifierProvider.value(
          value: StudentProfileProvider(attendanceRepository, feeRepository, classRepository, sectionRepository),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(routes: [GoRoute(path: '/', builder: (_, __) => const StudentProfileScreen(studentId: 's1'))]),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Sam Student'), findsWidgets);
    expect(find.text('Class 10  •  Section A'), findsOneWidget);
    expect(find.text('Student ID: ADM001'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Pat Parent (p1)'), findsNothing);
    expect(find.text('Pat Parent'), findsOneWidget);
    expect(find.text('Ben Teacher'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    // Blank fields don't get rows.
    expect(find.text('Blood Group'), findsNothing);
    expect(find.text('Date of Birth'), findsNothing);

    await tester.tap(find.text('Attendance'));
    await tester.pumpAndSettle();
    expect(find.text('90%'), findsOneWidget);
    expect(find.text('5 Sep 2026'), findsOneWidget);

    await tester.tap(find.text('Fees'));
    await tester.pumpAndSettle();
    expect(find.text('Tuition Fee'), findsOneWidget);
    expect(find.text('Rs. 5,000'), findsWidgets);
  });
}
