import 'dart:typed_data';

import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/student.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/student_repository.dart';
import 'package:cloud_lms/features/id_cards/data/repositories/id_card_repository.dart';
import 'package:cloud_lms/features/id_cards/presentation/providers/admin_id_card_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockIdCardRepository extends Mock implements IdCardRepository {}

class _MockStudentRepository extends Mock implements StudentRepository {}

const _student1 = Student(
  id: 's1',
  fullName: 'Sam Student',
  email: 'sam@test.dev',
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
  late _MockIdCardRepository idCardRepository;
  late _MockStudentRepository studentRepository;
  late AdminIdCardProvider provider;

  setUp(() {
    idCardRepository = _MockIdCardRepository();
    studentRepository = _MockStudentRepository();
    provider = AdminIdCardProvider(idCardRepository, studentRepository);
  });

  test('loadStudentOptions(): populates studentOptions', () async {
    when(() => studentRepository.getStudents()).thenAnswer((_) async => const Result.success([_student1]));

    await provider.loadStudentOptions();

    expect(provider.studentOptions, [_student1]);
  });

  test('generateStudentIdCard(): success returns the PDF bytes', () async {
    final bytes = Uint8List.fromList([37, 80, 68, 70]);
    when(() => idCardRepository.generateStudentIdCard('s1')).thenAnswer((_) async => Result.success(bytes));

    final result = await provider.generateStudentIdCard('s1');

    expect(result, bytes);
    expect(provider.isGenerating, isFalse);
    expect(provider.generateError, isNull);
  });

  test('generateStudentIdCard(): failure surfaces the error and returns null', () async {
    when(() => idCardRepository.generateStudentIdCard('s1'))
        .thenAnswer((_) async => const Result.failure(ServerException('Student not found for this school')));

    final result = await provider.generateStudentIdCard('s1');

    expect(result, isNull);
    expect(provider.generateError?.message, 'Student not found for this school');
  });
}
