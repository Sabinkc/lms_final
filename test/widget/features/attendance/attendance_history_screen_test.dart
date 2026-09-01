import 'dart:async';

import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/attendance/data/models/attendance_session.dart';
import 'package:cloud_lms/features/attendance/data/repositories/attendance_repository.dart';
import 'package:cloud_lms/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:cloud_lms/features/attendance/presentation/screens/attendance_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockAttendanceRepository extends Mock implements AttendanceRepository {}

const _session1 = AttendanceSessionSummary(
  id: 'sess1',
  className: 'Class 10',
  section: 'A',
  subject: 'General',
  date: '2026-08-23',
  presentCount: 8,
  absentCount: 1,
  lateCount: 1,
  totalCount: 10,
  locked: true,
);

Widget _wrap(AttendanceProvider provider) => ChangeNotifierProvider<AttendanceProvider>.value(
      value: provider,
      child: const MaterialApp(home: AttendanceHistoryScreen()),
    );

void main() {
  late _MockAttendanceRepository repository;

  setUp(() {
    repository = _MockAttendanceRepository();
  });

  testWidgets('loading state shows LoadingView', (tester) async {
    when(() => repository.getSessions(date: any(named: 'date')))
        .thenAnswer((_) => Completer<Result<List<AttendanceSessionSummary>>>().future);
    final provider = AttendanceProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('empty state shows a message for a date with nothing submitted', (tester) async {
    when(() => repository.getSessions(date: any(named: 'date'))).thenAnswer((_) async => const Result.success([]));
    final provider = AttendanceProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('No attendance submitted on this date'), findsOneWidget);
  });

  testWidgets('error state shows ErrorView with a working retry', (tester) async {
    var callCount = 0;
    when(() => repository.getSessions(date: any(named: 'date'))).thenAnswer((_) async {
      callCount++;
      return callCount == 1 ? const Result.failure(NetworkException()) : const Result.success([_session1]);
    });
    final provider = AttendanceProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Network error. Please check your connection.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Class 10'), findsOneWidget);
  });

  testWidgets('success state lists session summaries with their counts and lock indicator', (tester) async {
    when(() => repository.getSessions(date: any(named: 'date')))
        .thenAnswer((_) async => const Result.success([_session1]));
    final provider = AttendanceProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Class 10 — A · General'), findsOneWidget);
    expect(find.text('8 present, 1 absent, 1 late of 10'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });
}
