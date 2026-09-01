import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/id_cards/data/repositories/id_card_repository.dart';
import 'package:cloud_lms/features/id_cards/presentation/providers/student_id_card_provider.dart';
import 'package:cloud_lms/features/id_cards/presentation/screens/student_id_card_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockIdCardRepository extends Mock implements IdCardRepository {}

Widget _wrap(StudentIdCardProvider provider) => ChangeNotifierProvider<StudentIdCardProvider>.value(
      value: provider,
      child: const MaterialApp(home: StudentIdCardScreen()),
    );

void main() {
  late _MockIdCardRepository repository;

  setUp(() {
    repository = _MockIdCardRepository();
  });

  testWidgets('shows the Download ID Card action with no data loaded yet', (tester) async {
    final provider = StudentIdCardProvider(repository);

    await tester.pumpWidget(_wrap(provider));

    expect(find.text('Download ID Card'), findsOneWidget);
  });

  testWidgets('tapping Download shows a spinner while loading', (tester) async {
    when(() => repository.generateMyIdCard()).thenAnswer(
      (_) => Future.delayed(const Duration(milliseconds: 50), () => const Result.failure(ServerException('slow'))),
    );
    final provider = StudentIdCardProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.tap(find.text('Download ID Card'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('a failed download shows the error message in a snackbar', (tester) async {
    when(() => repository.generateMyIdCard())
        .thenAnswer((_) async => const Result.failure(ServerException('Student profile not found')));
    final provider = StudentIdCardProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.tap(find.text('Download ID Card'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Student profile not found'), findsOneWidget);
  });
}
