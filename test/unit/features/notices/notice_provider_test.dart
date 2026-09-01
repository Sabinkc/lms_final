import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/academic_structure_provider.dart'
    show LoadStatus;
import 'package:cloud_lms/features/notices/data/models/notice.dart';
import 'package:cloud_lms/features/notices/data/repositories/notice_repository.dart';
import 'package:cloud_lms/features/notices/presentation/providers/notice_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockNoticeRepository extends Mock implements NoticeRepository {}

const _notice1 = Notice(
  id: 'n1',
  title: 'School Holiday',
  description: 'School closed on Friday',
  audience: 'all',
  isImportant: true,
  expiryDate: null,
  createdByName: 'Admin Person',
  createdAt: '2026-08-24T00:00:00.000Z',
);

void main() {
  late _MockNoticeRepository repository;
  late NoticeProvider provider;

  setUp(() {
    repository = _MockNoticeRepository();
    provider = NoticeProvider(repository);
  });

  test('loadNoticesAsAdmin(): success populates notices and sets status', () async {
    when(() => repository.getNoticesAsAdmin(audience: any(named: 'audience')))
        .thenAnswer((_) async => const Result.success([_notice1]));

    await provider.loadNoticesAsAdmin();

    expect(provider.status, LoadStatus.success);
    expect(provider.notices, [_notice1]);
  });

  test('loadMyNotices(): success populates notices and sets status', () async {
    when(() => repository.getMyNotices()).thenAnswer((_) async => const Result.success([_notice1]));

    await provider.loadMyNotices();

    expect(provider.status, LoadStatus.success);
    expect(provider.notices, [_notice1]);
  });

  test('loadMyNotices(): failure sets error status', () async {
    when(() => repository.getMyNotices()).thenAnswer((_) async => const Result.failure(NetworkException()));

    await provider.loadMyNotices();

    expect(provider.status, LoadStatus.error);
    expect(provider.error, isA<NetworkException>());
  });

  test('loadNoticeDetail(): success populates currentNotice', () async {
    when(() => repository.getNoticeById(any())).thenAnswer((_) async => const Result.success(_notice1));

    await provider.loadNoticeDetail('n1');

    expect(provider.detailStatus, LoadStatus.success);
    expect(provider.currentNotice, _notice1);
  });

  test('createNotice(): success prepends to the notices list and returns true', () async {
    when(() => repository.createNotice(
          title: any(named: 'title'),
          description: any(named: 'description'),
          audience: any(named: 'audience'),
          isImportant: any(named: 'isImportant'),
          expiryDate: any(named: 'expiryDate'),
        )).thenAnswer((_) async => const Result.success(_notice1));

    final succeeded = await provider.createNotice(title: 'School Holiday', description: 'School closed on Friday');

    expect(succeeded, isTrue);
    expect(provider.notices, [_notice1]);
  });

  test('deleteNotice(): success removes it from the notices list', () async {
    when(() => repository.getMyNotices()).thenAnswer((_) async => const Result.success([_notice1]));
    await provider.loadMyNotices();
    when(() => repository.deleteNotice(any())).thenAnswer((_) async => const Result.success(null));

    final succeeded = await provider.deleteNotice('n1');

    expect(succeeded, isTrue);
    expect(provider.notices, isEmpty);
  });
}
