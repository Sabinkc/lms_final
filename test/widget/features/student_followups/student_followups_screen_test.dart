import 'dart:async';

import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/student_followups/data/models/student_followup.dart';
import 'package:cloud_lms/features/student_followups/data/repositories/student_followup_repository.dart';
import 'package:cloud_lms/features/student_followups/presentation/providers/student_followup_provider.dart';
import 'package:cloud_lms/features/student_followups/presentation/screens/student_followups_screen.dart';
import 'package:cloud_lms/shared/widgets/form_sheet.dart';
import 'package:cloud_lms/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockStudentFollowupRepository extends Mock implements StudentFollowupRepository {}

const _followup1 = StudentFollowup(
  id: 'f1',
  studentName: 'Sam Prospect',
  faculty: 'Science',
  email: 'sam@test.dev',
  contactNumber: '9800000000',
  address: 'Kathmandu',
  followUpNote: 'Interested in Class 10 admission',
  visitDate: '2026-08-20T00:00:00.000Z',
  status: 'pending',
  createdByName: 'Alice Admin',
);

Widget _wrap(StudentFollowupProvider provider) => ChangeNotifierProvider<StudentFollowupProvider>.value(
      value: provider,
      child: const MaterialApp(home: StudentFollowupsScreen()),
    );

void main() {
  late _MockStudentFollowupRepository repository;

  setUp(() {
    repository = _MockStudentFollowupRepository();
  });

  testWidgets('loading state shows LoadingView', (tester) async {
    when(() => repository.getFollowups(status: any(named: 'status'), search: any(named: 'search'), limit: any(named: 'limit')))
        .thenAnswer((_) => Completer<Result<List<StudentFollowup>>>().future);
    final provider = StudentFollowupProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.byType(LoadingView), findsOneWidget);
  });

  testWidgets('empty state shows the add-follow-up CTA', (tester) async {
    when(() => repository.getFollowups(status: any(named: 'status'), search: any(named: 'search'), limit: any(named: 'limit')))
        .thenAnswer((_) async => const Result.success([]));
    final provider = StudentFollowupProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('No follow-ups logged yet'), findsOneWidget);
  });

  testWidgets('error state shows ErrorView with a working retry', (tester) async {
    var callCount = 0;
    when(() => repository.getFollowups(status: any(named: 'status'), search: any(named: 'search'), limit: any(named: 'limit')))
        .thenAnswer((_) async {
      callCount++;
      return callCount == 1 ? const Result.failure(NetworkException()) : const Result.success([_followup1]);
    });
    final provider = StudentFollowupProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Network error. Please check your connection.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Sam Prospect'), findsOneWidget);
  });

  testWidgets('success state lists the follow-up with its note', (tester) async {
    when(() => repository.getFollowups(status: any(named: 'status'), search: any(named: 'search'), limit: any(named: 'limit')))
        .thenAnswer((_) async => const Result.success([_followup1]));
    final provider = StudentFollowupProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Sam Prospect'), findsOneWidget);
    expect(find.textContaining('Science'), findsOneWidget);
    expect(find.text('Interested in Class 10 admission'), findsOneWidget);
  });

  testWidgets('add-follow-up flow: FAB -> form -> save calls createFollowup and closes the dialog', (tester) async {
    when(() => repository.getFollowups(status: any(named: 'status'), search: any(named: 'search'), limit: any(named: 'limit')))
        .thenAnswer((_) async => const Result.success([]));
    when(
      () => repository.createFollowup(
        studentName: any(named: 'studentName'),
        faculty: any(named: 'faculty'),
        email: any(named: 'email'),
        contactNumber: any(named: 'contactNumber'),
        address: any(named: 'address'),
        followUpNote: any(named: 'followUpNote'),
        visitDate: any(named: 'visitDate'),
        status: any(named: 'status'),
      ),
    ).thenAnswer((_) async => const Result.success(_followup1));
    final provider = StudentFollowupProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FormSheet, 'Add Follow-up'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Student Name'), 'Sam Prospect');
    await tester.enterText(find.widgetWithText(TextFormField, 'Faculty'), 'Science');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'sam@test.dev');
    await tester.enterText(find.widgetWithText(TextFormField, 'Contact Number'), '9800000000');
    await tester.enterText(find.widgetWithText(TextFormField, 'Address'), 'Kathmandu');
    await tester.enterText(find.widgetWithText(TextFormField, 'Follow-up Needed'), 'Interested in Class 10 admission');

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verify(
      () => repository.createFollowup(
        studentName: 'Sam Prospect',
        faculty: 'Science',
        email: 'sam@test.dev',
        contactNumber: '9800000000',
        address: 'Kathmandu',
        followUpNote: 'Interested in Class 10 admission',
        visitDate: any(named: 'visitDate'),
        status: 'pending',
      ),
    ).called(1);
    expect(find.byType(FormSheet), findsNothing);
  });

  testWidgets('a failed export shows the error message in a snackbar', (tester) async {
    when(() => repository.getFollowups(status: any(named: 'status'), search: any(named: 'search'), limit: any(named: 'limit')))
        .thenAnswer((_) async => const Result.success([]));
    when(() => repository.exportFollowups(status: any(named: 'status'), search: any(named: 'search')))
        .thenAnswer((_) async => const Result.failure(ServerException('Export failed')));
    final provider = StudentFollowupProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Export follow-ups'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Export failed'), findsOneWidget);
  });
}
