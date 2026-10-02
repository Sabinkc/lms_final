import 'dart:async';

import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/notices/data/models/notice.dart';
import 'package:cloud_lms/features/notices/data/repositories/notice_repository.dart';
import 'package:cloud_lms/features/notices/presentation/providers/notice_provider.dart';
import 'package:cloud_lms/features/notices/presentation/screens/notice_detail_screen.dart';
import 'package:cloud_lms/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockNoticeRepository extends Mock implements NoticeRepository {}

const _notice1 = Notice(
  id: 'n1',
  title: 'School Holiday',
  description: 'School closed on Friday for a public holiday.',
  audience: 'all',
  isImportant: true,
  expiryDate: null,
  createdByName: 'Admin Person',
  createdAt: '2026-08-24T00:00:00.000Z',
);

Widget _wrap(NoticeProvider provider) => ChangeNotifierProvider<NoticeProvider>.value(
      value: provider,
      child: const MaterialApp(home: NoticeDetailScreen(noticeId: 'n1')),
    );

void main() {
  late _MockNoticeRepository repository;

  setUp(() {
    repository = _MockNoticeRepository();
  });

  testWidgets('loading state shows LoadingView', (tester) async {
    when(() => repository.getNoticeById(any())).thenAnswer((_) => Completer<Result<Notice>>().future);
    final provider = NoticeProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.byType(LoadingView), findsOneWidget);
  });

  testWidgets('error state shows ErrorView with a working retry', (tester) async {
    var callCount = 0;
    when(() => repository.getNoticeById(any())).thenAnswer((_) async {
      callCount++;
      return callCount == 1 ? const Result.failure(NetworkException()) : const Result.success(_notice1);
    });
    final provider = NoticeProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Network error. Please check your connection.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('School Holiday'), findsOneWidget);
  });

  testWidgets('success state shows title, audience, creator, and full description', (tester) async {
    when(() => repository.getNoticeById(any())).thenAnswer((_) async => const Result.success(_notice1));
    final provider = NoticeProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('School Holiday'), findsOneWidget);
    expect(find.text('Everyone'), findsWidgets);
    expect(find.text('Important'), findsOneWidget);
    expect(find.text('Admin Person'), findsOneWidget);
    expect(find.text('24 Aug 2026'), findsOneWidget);
    expect(find.text('School closed on Friday for a public holiday.'), findsOneWidget);
  });
}
