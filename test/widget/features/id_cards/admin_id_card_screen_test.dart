import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/student.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/student_repository.dart';
import 'package:cloud_lms/features/id_cards/data/repositories/id_card_repository.dart';
import 'package:cloud_lms/features/id_cards/presentation/providers/admin_id_card_provider.dart';
import 'package:cloud_lms/features/id_cards/presentation/screens/admin_id_card_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

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

Widget _wrap(AdminIdCardProvider provider) => ChangeNotifierProvider<AdminIdCardProvider>.value(
      value: provider,
      child: const MaterialApp(home: AdminIdCardScreen()),
    );

void main() {
  late _MockIdCardRepository idCardRepository;
  late _MockStudentRepository studentRepository;

  setUp(() {
    idCardRepository = _MockIdCardRepository();
    studentRepository = _MockStudentRepository();
    when(() => studentRepository.getStudents()).thenAnswer((_) async => const Result.success([_student1]));
  });

  testWidgets('Generate button is disabled until a student is picked', (tester) async {
    final provider = AdminIdCardProvider(idCardRepository, studentRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('picking a student then a failed generate shows the error in a snackbar', (tester) async {
    when(() => idCardRepository.generateStudentIdCard('s1'))
        .thenAnswer((_) async => const Result.failure(ServerException('Student not found for this school')));
    final provider = AdminIdCardProvider(idCardRepository, studentRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Student'), 'Sam');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sam Student (ADM001)').last);
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);

    await tester.tap(find.text('Generate & Download'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Student not found for this school'), findsOneWidget);
  });
}
