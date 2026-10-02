import 'dart:async';

import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/academic_class.dart';
import 'package:cloud_lms/features/admin_management/data/models/department.dart';
import 'package:cloud_lms/features/admin_management/data/models/teacher.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/class_repository.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/department_repository.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/teacher_repository.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import 'package:cloud_lms/features/admin_management/presentation/providers/department_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDepartmentRepository extends Mock implements DepartmentRepository {}

class _MockTeacherRepository extends Mock implements TeacherRepository {}

class _MockClassRepository extends Mock implements ClassRepository {}

const _department1 = Department(
  id: 'd1',
  name: 'Science',
  description: 'STEM subjects',
  headOfDepartmentId: 't1',
  headOfDepartmentName: 'Jane Teacher',
  classes: ['Class 10'],
  status: 'active',
);

const _teacher1 = Teacher(
  id: 't1',
  fullName: 'Jane Teacher',
  email: 'jane@test.dev',
  employeeId: 'EMP001',
  department: 'Science',
  designation: 'Senior Teacher',
  qualification: 'M.Sc.',
  subjects: ['Physics'],
  experience: 5,
  salary: 50000,
  address: '',
  phone: '',
  bankAccountNumber: '',
  status: 'active',
);

const _class1 = AcademicClass(id: 'c1', name: 'Class 10', description: 'Grade 10', status: 'active');

void main() {
  late _MockDepartmentRepository departmentRepository;
  late _MockTeacherRepository teacherRepository;
  late _MockClassRepository classRepository;
  late DepartmentProvider provider;

  setUp(() {
    departmentRepository = _MockDepartmentRepository();
    teacherRepository = _MockTeacherRepository();
    classRepository = _MockClassRepository();
    provider = DepartmentProvider(departmentRepository, teacherRepository, classRepository);
  });

  test('loadDepartments(silent: true) keeps the loaded list on screen while reloading', () async {
    when(() => departmentRepository.getDepartments()).thenAnswer((_) async => const Result.success([_department1]));
    await provider.loadDepartments();

    final pending = Completer<Result<List<Department>>>();
    when(() => departmentRepository.getDepartments()).thenAnswer((_) => pending.future);
    final reload = provider.loadDepartments(silent: true);

    expect(provider.status, LoadStatus.success);
    expect(provider.departments, [_department1]);

    pending.complete(const Result.success([]));
    await reload;
    expect(provider.departments, isEmpty);
  });

  test('loadDepartments() without silent shows loading again', () async {
    when(() => departmentRepository.getDepartments()).thenAnswer((_) async => const Result.success([_department1]));
    await provider.loadDepartments();

    final pending = Completer<Result<List<Department>>>();
    when(() => departmentRepository.getDepartments()).thenAnswer((_) => pending.future);
    final reload = provider.loadDepartments();

    expect(provider.status, LoadStatus.loading);
    pending.complete(const Result.success([_department1]));
    await reload;
  });

  test('loadDepartments(): success populates departments and sets status', () async {
    when(() => departmentRepository.getDepartments()).thenAnswer((_) async => const Result.success([_department1]));

    await provider.loadDepartments();

    expect(provider.status, LoadStatus.success);
    expect(provider.departments, [_department1]);
  });

  test('loadDepartments(): failure sets error status', () async {
    when(() => departmentRepository.getDepartments()).thenAnswer((_) async => const Result.failure(NetworkException()));

    await provider.loadDepartments();

    expect(provider.status, LoadStatus.error);
    expect(provider.error, isA<NetworkException>());
  });

  test('loadOptions(): populates teacherOptions and classOptions from both repositories', () async {
    when(() => teacherRepository.getTeachers()).thenAnswer((_) async => const Result.success([_teacher1]));
    when(() => classRepository.getClasses()).thenAnswer((_) async => const Result.success([_class1]));

    await provider.loadOptions();

    expect(provider.teacherOptions, [_teacher1]);
    expect(provider.classOptions, [_class1]);
  });

  test('createDepartment(): success appends to the list and returns true', () async {
    when(
      () => departmentRepository.createDepartment(
        name: any(named: 'name'),
        description: any(named: 'description'),
        headOfDepartmentId: any(named: 'headOfDepartmentId'),
        classes: any(named: 'classes'),
      ),
    ).thenAnswer((_) async => const Result.success(_department1));

    final succeeded = await provider.createDepartment(name: 'Science', headOfDepartmentId: 't1', classes: ['Class 10']);

    expect(succeeded, isTrue);
    expect(provider.departments, [_department1]);
    expect(provider.isSaving, isFalse);
  });

  test('createDepartment(): failure returns false and exposes the action error without touching the list', () async {
    when(
      () => departmentRepository.createDepartment(
        name: any(named: 'name'),
        description: any(named: 'description'),
        headOfDepartmentId: any(named: 'headOfDepartmentId'),
        classes: any(named: 'classes'),
      ),
    ).thenAnswer((_) async => const Result.failure(ValidationException('name is required')));

    final succeeded = await provider.createDepartment(name: '');

    expect(succeeded, isFalse);
    expect(provider.departments, isEmpty);
    expect(provider.actionError, isA<ValidationException>());
  });

  test('updateDepartment(): success replaces the matching department in the list', () async {
    const updated = Department(
      id: 'd1',
      name: 'Science & Math',
      description: 'STEM subjects',
      headOfDepartmentId: 't1',
      headOfDepartmentName: 'Jane Teacher',
      classes: ['Class 10'],
      status: 'active',
    );
    when(() => departmentRepository.getDepartments()).thenAnswer((_) async => const Result.success([_department1]));
    await provider.loadDepartments();

    when(
      () => departmentRepository.updateDepartment(
        id: any(named: 'id'),
        name: any(named: 'name'),
        description: any(named: 'description'),
        headOfDepartmentId: any(named: 'headOfDepartmentId'),
        classes: any(named: 'classes'),
        status: any(named: 'status'),
      ),
    ).thenAnswer((_) async => const Result.success(updated));

    final succeeded = await provider.updateDepartment(id: 'd1', name: 'Science & Math');

    expect(succeeded, isTrue);
    expect(provider.departments.single.name, 'Science & Math');
  });

  test('deleteDepartment(): success removes the department from the list', () async {
    when(() => departmentRepository.getDepartments()).thenAnswer((_) async => const Result.success([_department1]));
    await provider.loadDepartments();

    when(() => departmentRepository.deleteDepartment('d1')).thenAnswer((_) async => const Result.success(null));

    final succeeded = await provider.deleteDepartment('d1');

    expect(succeeded, isTrue);
    expect(provider.departments, isEmpty);
  });

  test('deleteDepartment(): failure keeps the department and exposes the action error', () async {
    when(() => departmentRepository.getDepartments()).thenAnswer((_) async => const Result.success([_department1]));
    await provider.loadDepartments();

    when(() => departmentRepository.deleteDepartment('d1'))
        .thenAnswer((_) async => const Result.failure(ServerException('Department not found')));

    final succeeded = await provider.deleteDepartment('d1');

    expect(succeeded, isFalse);
    expect(provider.departments, [_department1]);
    expect(provider.actionError?.message, 'Department not found');
  });
}
