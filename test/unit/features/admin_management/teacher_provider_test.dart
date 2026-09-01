import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/teacher.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/teacher_repository.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/academic_structure_provider.dart'
    show LoadStatus;
import 'package:cloud_lms/features/admin_management/presentation/providers/teacher_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTeacherRepository extends Mock implements TeacherRepository {}

const _teacher1 = Teacher(
  id: 't1',
  fullName: 'Jane Teacher',
  email: 'jane@school.test',
  employeeId: 'EMP001',
  department: 'Science',
  designation: 'Lecturer',
  qualification: '',
  subjects: [],
  experience: 0,
  salary: 0,
  address: '',
  phone: '',
  bankAccountNumber: '',
  status: 'active',
);

void main() {
  late _MockTeacherRepository repository;
  late TeacherProvider provider;

  setUp(() {
    repository = _MockTeacherRepository();
    provider = TeacherProvider(repository);
  });

  test('loadTeachers(): success populates teachers and sets status', () async {
    when(() => repository.getTeachers()).thenAnswer((_) async => const Result.success([_teacher1]));

    await provider.loadTeachers();

    expect(provider.status, LoadStatus.success);
    expect(provider.teachers, [_teacher1]);
  });

  test('loadTeachers(): failure sets error status and surfaces the error', () async {
    when(() => repository.getTeachers()).thenAnswer((_) async => const Result.failure(NetworkException()));

    await provider.loadTeachers();

    expect(provider.status, LoadStatus.error);
    expect(provider.error, isA<NetworkException>());
  });

  test('createTeacher(): success appends to the teachers list and returns true', () async {
    when(() => repository.createTeacher(
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          employeeId: any(named: 'employeeId'),
          department: any(named: 'department'),
          password: any(named: 'password'),
          designation: any(named: 'designation'),
          qualification: any(named: 'qualification'),
          subjects: any(named: 'subjects'),
          experience: any(named: 'experience'),
          salary: any(named: 'salary'),
          address: any(named: 'address'),
          phone: any(named: 'phone'),
          bankAccountNumber: any(named: 'bankAccountNumber'),
        )).thenAnswer((_) async => const Result.success(_teacher1));

    final succeeded = await provider.createTeacher(
      fullName: 'Jane Teacher',
      email: 'jane@school.test',
      employeeId: 'EMP001',
      department: 'Science',
    );

    expect(succeeded, isTrue);
    expect(provider.teachers, [_teacher1]);
  });

  test('updateTeacher(): success replaces the matching teacher in place', () async {
    provider = TeacherProvider(repository);
    when(() => repository.getTeachers()).thenAnswer((_) async => const Result.success([_teacher1]));
    await provider.loadTeachers();

    const updated = Teacher(
      id: 't1',
      fullName: 'Jane Teacher',
      email: 'jane@school.test',
      employeeId: 'EMP001',
      department: 'Mathematics',
      designation: 'Lecturer',
      qualification: '',
      subjects: [],
      experience: 0,
      salary: 0,
      address: '',
      phone: '',
      bankAccountNumber: '',
      status: 'active',
    );
    when(() => repository.updateTeacher(
          id: any(named: 'id'),
          employeeId: any(named: 'employeeId'),
          department: any(named: 'department'),
          designation: any(named: 'designation'),
          qualification: any(named: 'qualification'),
          subjects: any(named: 'subjects'),
          experience: any(named: 'experience'),
          salary: any(named: 'salary'),
          address: any(named: 'address'),
          phone: any(named: 'phone'),
          bankAccountNumber: any(named: 'bankAccountNumber'),
          status: any(named: 'status'),
        )).thenAnswer((_) async => const Result.success(updated));

    final succeeded = await provider.updateTeacher(id: 't1', department: 'Mathematics');

    expect(succeeded, isTrue);
    expect(provider.teachers.single.department, 'Mathematics');
  });

  test('deleteTeacher(): success removes it from the teachers list', () async {
    when(() => repository.getTeachers()).thenAnswer((_) async => const Result.success([_teacher1]));
    await provider.loadTeachers();
    when(() => repository.deleteTeacher(any())).thenAnswer((_) async => const Result.success(null));

    final succeeded = await provider.deleteTeacher('t1');

    expect(succeeded, isTrue);
    expect(provider.teachers, isEmpty);
  });
}
