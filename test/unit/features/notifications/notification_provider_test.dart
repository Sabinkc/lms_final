import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import 'package:cloud_lms/features/notifications/data/models/app_notification.dart';
import 'package:cloud_lms/features/notifications/data/repositories/notification_repository.dart';
import 'package:cloud_lms/features/notifications/presentation/providers/notification_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotificationRepository extends Mock implements NotificationRepository {}

const _n1 = AppNotification(
  id: 'n1',
  title: 'New Assignment',
  message: 'Algebra Homework was posted',
  type: 'assignment',
  isRead: false,
  refId: 'a1',
  refModel: 'Assignment',
  createdAt: '2026-08-25T00:00:00.000Z',
);

const _n2 = AppNotification(
  id: 'n2',
  title: 'Welcome',
  message: 'Your account was created',
  type: 'general',
  isRead: false,
  refId: null,
  refModel: null,
  createdAt: '2026-08-24T00:00:00.000Z',
);

void main() {
  late _MockNotificationRepository repository;
  late NotificationProvider provider;

  setUp(() {
    repository = _MockNotificationRepository();
    provider = NotificationProvider(repository);
  });

  test('loadNotifications(): success populates the list and unread count', () async {
    when(() => repository.getNotifications(limit: any(named: 'limit'))).thenAnswer((_) async => const Result.success((2, [_n1, _n2])));

    await provider.loadNotifications();

    expect(provider.status, LoadStatus.success);
    expect(provider.notifications, [_n1, _n2]);
    expect(provider.unreadCount, 2);
  });

  test('loadNotifications(): failure sets error status', () async {
    when(() => repository.getNotifications(limit: any(named: 'limit'))).thenAnswer((_) async => const Result.failure(NetworkException()));

    await provider.loadNotifications();

    expect(provider.status, LoadStatus.error);
  });

  test('markRead(): optimistically flips isRead and decrements the unread count before the request resolves', () async {
    when(() => repository.getNotifications(limit: any(named: 'limit'))).thenAnswer((_) async => const Result.success((2, [_n1, _n2])));
    await provider.loadNotifications();
    when(() => repository.markRead(any())).thenAnswer((_) async => const Result.success(null));

    await provider.markRead('n1');

    expect(provider.notifications.firstWhere((n) => n.id == 'n1').isRead, isTrue);
    expect(provider.unreadCount, 1);
    verify(() => repository.markRead('n1')).called(1);
  });

  test('markRead(): a already-read notification is a no-op, never calls the repository', () async {
    const readNotification = AppNotification(
      id: 'n3',
      title: 'Old',
      message: 'Already seen',
      type: 'general',
      isRead: true,
      refId: null,
      refModel: null,
      createdAt: '2026-08-20T00:00:00.000Z',
    );
    when(() => repository.getNotifications(limit: any(named: 'limit'))).thenAnswer((_) async => const Result.success((0, [readNotification])));
    await provider.loadNotifications();

    await provider.markRead('n3');

    verifyNever(() => repository.markRead(any()));
  });

  test('markAllRead(): flips every notification to read and zeroes the unread count', () async {
    when(() => repository.getNotifications(limit: any(named: 'limit'))).thenAnswer((_) async => const Result.success((2, [_n1, _n2])));
    await provider.loadNotifications();
    when(() => repository.markAllRead()).thenAnswer((_) async => const Result.success(null));

    await provider.markAllRead();

    expect(provider.notifications.every((n) => n.isRead), isTrue);
    expect(provider.unreadCount, 0);
    verify(() => repository.markAllRead()).called(1);
  });
}
