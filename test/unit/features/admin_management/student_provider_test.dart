import 'dart:typed_data';

import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/academic_class.dart';
import 'package:cloud_lms/features/admin_management/data/models/bulk_import_result.dart';
import 'package:cloud_lms/features/admin_management/data/models/student.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/class_repository.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/section_repository.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/student_repository.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/academic_structure_provider.dart'
    show LoadStatus;
import 'package:cloud_lms/features/admin_management/presentation/providers/student_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStudentRepository extends Mock implements StudentRepository {}

class _MockClassRepository extends Mock implements ClassRepository {}

class _MockSectionRepository extends Mock implements SectionRepository {}

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
  late _MockStudentRepository studentRepository;
  late _MockClassRepository classRepository;
  late _MockSectionRepository sectionRepository;
  late StudentProvider provider;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    studentRepository = _MockStudentRepository();
    classRepository = _MockClassRepository();
    sectionRepository = _MockSectionRepository();
    provider = StudentProvider(studentRepository, classRepository, sectionRepository);
  });

  test('loadStudents(): success populates students and sets status', () async {
    when(() => studentRepository.getStudents(className: any(named: 'className')))
        .thenAnswer((_) async => const Result.success([_student1]));

    await provider.loadStudents();

    expect(provider.status, LoadStatus.success);
    expect(provider.students, [_student1]);
  });

  test('loadStudents(): failure sets error status and surfaces the error', () async {
    when(() => studentRepository.getStudents(className: any(named: 'className')))
        .thenAnswer((_) async => const Result.failure(NetworkException()));

    await provider.loadStudents();

    expect(provider.status, LoadStatus.error);
    expect(provider.error, isA<NetworkException>());
  });

  test('createStudent(): success appends to the students list and returns true', () async {
    when(() => studentRepository.createStudent(
          className: any(named: 'className'),
          section: any(named: 'section'),
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          userId: any(named: 'userId'),
          password: any(named: 'password'),
          admissionNumber: any(named: 'admissionNumber'),
          rollNumber: any(named: 'rollNumber'),
          parentId: any(named: 'parentId'),
          dob: any(named: 'dob'),
          address: any(named: 'address'),
          phone: any(named: 'phone'),
        )).thenAnswer((_) async => const Result.success(_student1));

    final succeeded = await provider.createStudent(className: 'Class 10', section: 'A', fullName: 'Sam Student');

    expect(succeeded, isTrue);
    expect(provider.students, [_student1]);
  });

  test('deleteStudent(): success removes it from the students list', () async {
    when(() => studentRepository.getStudents(className: any(named: 'className')))
        .thenAnswer((_) async => const Result.success([_student1]));
    await provider.loadStudents();
    when(() => studentRepository.deleteStudent(any())).thenAnswer((_) async => const Result.success(null));

    final succeeded = await provider.deleteStudent('s1');

    expect(succeeded, isTrue);
    expect(provider.students, isEmpty);
  });

  test('loadClassOptions(): success populates classOptions', () async {
    const class1 = AcademicClass(id: 'c1', name: 'Class 10', description: '', status: 'active');
    when(() => classRepository.getClasses()).thenAnswer((_) async => const Result.success([class1]));

    await provider.loadClassOptions();

    expect(provider.classOptions, [class1]);
  });

  test('bulkImport(): success stores the summary and reloads the student list', () async {
    when(() => studentRepository.bulkImport(any(), any())).thenAnswer(
      (_) async => const Result.success(BulkImportResult(createdCount: 1, failed: [], totalRows: 1)),
    );
    when(() => studentRepository.getStudents(className: any(named: 'className')))
        .thenAnswer((_) async => const Result.success([_student1]));

    final succeeded = await provider.bulkImport(Uint8List.fromList([1, 2, 3]), 'students.xlsx');

    expect(succeeded, isTrue);
    expect(provider.lastImportResult?.createdCount, 1);
    expect(provider.students, [_student1]);
  });

  test('bulkImport(): failure surfaces the error without reloading', () async {
    when(() => studentRepository.bulkImport(any(), any()))
        .thenAnswer((_) async => const Result.failure(ServerException()));

    final succeeded = await provider.bulkImport(Uint8List.fromList([1, 2, 3]), 'students.xlsx');

    expect(succeeded, isFalse);
    expect(provider.importError, isA<ServerException>());
    verifyNever(() => studentRepository.getStudents(className: any(named: 'className')));
  });

  test('exportStudents(): success returns the bytes', () async {
    when(() => studentRepository.exportStudents(className: any(named: 'className')))
        .thenAnswer((_) async => Result.success(Uint8List.fromList([1, 2, 3])));

    final bytes = await provider.exportStudents();

    expect(bytes, [1, 2, 3]);
  });
}
