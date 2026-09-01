import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/parent.dart';
import 'package:cloud_lms/features/admin_management/data/models/student.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/parent_repository.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/student_repository.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/academic_structure_provider.dart'
    show LoadStatus;
import 'package:cloud_lms/features/admin_management/presentation/providers/parent_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockParentRepository extends Mock implements ParentRepository {}

class _MockStudentRepository extends Mock implements StudentRepository {}

const _parent1 = Parent(
  id: 'p1',
  fullName: 'Pat Parent',
  email: 'pat@school.test',
  occupation: 'Engineer',
  address: '',
  phone: '',
  status: 'active',
  children: [],
);

const _student1 = Student(
  id: 's1',
  fullName: 'Sam Student',
  email: 'sam@school.test',
  admissionNumber: 'ADM001',
  rollNumber: '1',
  className: 'Class 10',
  section: 'A',
  parentId: null,
  dob: '',
  address: '',
  phone: '',
  status: 'active',
);

void main() {
  late _MockParentRepository parentRepository;
  late _MockStudentRepository studentRepository;
  late ParentProvider provider;

  setUp(() {
    parentRepository = _MockParentRepository();
    studentRepository = _MockStudentRepository();
    provider = ParentProvider(parentRepository, studentRepository);
  });

  test('loadParents(): success populates parents and sets status', () async {
    when(() => parentRepository.getParents()).thenAnswer((_) async => const Result.success([_parent1]));

    await provider.loadParents();

    expect(provider.status, LoadStatus.success);
    expect(provider.parents, [_parent1]);
  });

  test('loadParents(): failure sets error status and surfaces the error', () async {
    when(() => parentRepository.getParents()).thenAnswer((_) async => const Result.failure(NetworkException()));

    await provider.loadParents();

    expect(provider.status, LoadStatus.error);
    expect(provider.error, isA<NetworkException>());
  });

  test('loadStudentOptions(): success populates studentOptions', () async {
    when(() => studentRepository.getStudents(className: any(named: 'className')))
        .thenAnswer((_) async => const Result.success([_student1]));

    await provider.loadStudentOptions();

    expect(provider.studentOptions, [_student1]);
  });

  test('createParent(): success appends to the parents list and returns true', () async {
    when(() => parentRepository.createParent(
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          occupation: any(named: 'occupation'),
          address: any(named: 'address'),
          phone: any(named: 'phone'),
          studentIds: any(named: 'studentIds'),
        )).thenAnswer((_) async => const Result.success(_parent1));

    final succeeded = await provider.createParent(fullName: 'Pat Parent', email: 'pat@school.test');

    expect(succeeded, isTrue);
    expect(provider.parents, [_parent1]);
  });

  test('updateParent(): success replaces the matching parent in place', () async {
    when(() => parentRepository.getParents()).thenAnswer((_) async => const Result.success([_parent1]));
    await provider.loadParents();

    const updated = Parent(
      id: 'p1',
      fullName: 'Pat Parent',
      email: 'pat@school.test',
      occupation: 'Doctor',
      address: '',
      phone: '',
      status: 'active',
      children: [],
    );
    when(() => parentRepository.updateParent(
          id: any(named: 'id'),
          occupation: any(named: 'occupation'),
          address: any(named: 'address'),
          phone: any(named: 'phone'),
          status: any(named: 'status'),
          studentIds: any(named: 'studentIds'),
        )).thenAnswer((_) async => const Result.success(updated));

    final succeeded = await provider.updateParent(id: 'p1', occupation: 'Doctor');

    expect(succeeded, isTrue);
    expect(provider.parents.single.occupation, 'Doctor');
  });

  test('deleteParent(): success removes it from the parents list', () async {
    when(() => parentRepository.getParents()).thenAnswer((_) async => const Result.success([_parent1]));
    await provider.loadParents();
    when(() => parentRepository.deleteParent(any())).thenAnswer((_) async => const Result.success(null));

    final succeeded = await provider.deleteParent('p1');

    expect(succeeded, isTrue);
    expect(provider.parents, isEmpty);
  });
}
