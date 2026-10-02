import 'dart:async';

import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/class_section.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/class_repository.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/section_repository.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/academic_structure_provider.dart';
import 'package:cloud_lms/features/admin_management/presentation/screens/sections_list_screen.dart';
import 'package:cloud_lms/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockClassRepository extends Mock implements ClassRepository {}

class _MockSectionRepository extends Mock implements SectionRepository {}

const _section1 = ClassSection(id: 's1', name: 'A', classId: 'c1', status: 'active', studentCount: 5);

Widget _wrap(AcademicStructureProvider provider, {String classId = 'c1'}) =>
    ChangeNotifierProvider<AcademicStructureProvider>.value(
      value: provider,
      child: MaterialApp(home: SectionsListScreen(classId: classId)),
    );

void main() {
  late _MockClassRepository classRepository;
  late _MockSectionRepository sectionRepository;

  setUp(() {
    classRepository = _MockClassRepository();
    sectionRepository = _MockSectionRepository();
  });

  testWidgets('loading state shows LoadingView', (tester) async {
    when(() => sectionRepository.getSections(any())).thenAnswer((_) => Completer<Result<List<ClassSection>>>().future);
    final provider = AcademicStructureProvider(classRepository, sectionRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.byType(LoadingView), findsOneWidget);
  });

  testWidgets('empty state shows the CTA', (tester) async {
    when(() => sectionRepository.getSections(any())).thenAnswer((_) async => const Result.success([]));
    final provider = AcademicStructureProvider(classRepository, sectionRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('No sections set up yet'), findsOneWidget);
    expect(find.text('Add Section'), findsWidgets);
  });

  testWidgets('error state shows ErrorView with a working retry', (tester) async {
    var callCount = 0;
    when(() => sectionRepository.getSections(any())).thenAnswer((_) async {
      callCount++;
      return callCount == 1 ? const Result.failure(NetworkException()) : const Result.success([_section1]);
    });
    final provider = AcademicStructureProvider(classRepository, sectionRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Network error. Please check your connection.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('success state lists sections with student counts', (tester) async {
    const section2 = ClassSection(id: 's2', name: 'B', classId: 'c1', status: 'active', studentCount: 0);
    when(() => sectionRepository.getSections(any())).thenAnswer((_) async => const Result.success([_section1, section2]));
    final provider = AcademicStructureProvider(classRepository, sectionRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('A'), findsOneWidget);
    expect(find.text('5 students'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('0 students'), findsOneWidget);
  });

  testWidgets('add-section flow: FAB -> form -> save calls createSection and closes the dialog', (tester) async {
    when(() => sectionRepository.getSections(any())).thenAnswer((_) async => const Result.success([]));
    when(() => sectionRepository.createSection(classId: any(named: 'classId'), name: any(named: 'name')))
        .thenAnswer((_) async => const Result.success(_section1));
    final provider = AcademicStructureProvider(classRepository, sectionRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AlertDialog, 'Add Section'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'A');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verify(() => sectionRepository.createSection(classId: 'c1', name: 'A')).called(1);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
