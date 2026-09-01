import 'package:cloud_lms/core/router/app_routes.dart';
import 'package:cloud_lms/features/auth/data/models/app_role.dart';
import 'package:cloud_lms/features/notifications/data/models/app_notification.dart';
import 'package:cloud_lms/features/notifications/presentation/notification_route.dart';
import 'package:flutter_test/flutter_test.dart';

AppNotification _withRef(String? refModel, String? refId) => AppNotification(
      id: 'n1',
      title: 't',
      message: 'm',
      type: 'general',
      isRead: false,
      refId: refId,
      refModel: refModel,
      createdAt: '2026-08-25T00:00:00.000Z',
    );

void main() {
  test('Assignment deep-links to its own detail route', () {
    expect(routeForNotification(_withRef('Assignment', 'a1'), AppRole.student), AppRoutes.assignmentDetail('a1'));
  });

  test('Assignment with no refId falls back to the list', () {
    expect(routeForNotification(_withRef('Assignment', null), AppRole.student), AppRoutes.assignments);
  });

  test('Exam and Result both route to the shared exams list', () {
    expect(routeForNotification(_withRef('Exam', 'e1'), AppRole.student), AppRoutes.exams);
    expect(routeForNotification(_withRef('Result', 'r1'), AppRole.parent), AppRoutes.exams);
  });

  test('Fee routes to the role-appropriate fees screen, and is null for Teacher (no Fees screen)', () {
    expect(routeForNotification(_withRef('Fee', 'f1'), AppRole.admin), AppRoutes.adminFees);
    expect(routeForNotification(_withRef('Fee', 'f1'), AppRole.student), AppRoutes.studentFees);
    expect(routeForNotification(_withRef('Fee', 'f1'), AppRole.parent), AppRoutes.parentFees);
    expect(routeForNotification(_withRef('Fee', 'f1'), AppRole.teacher), isNull);
  });

  test('Attendance variants route to the role-appropriate attendance screen', () {
    expect(routeForNotification(_withRef('Attendance', null), AppRole.admin), AppRoutes.adminAttendanceOverview);
    expect(routeForNotification(_withRef('AttendanceSession', null), AppRole.teacher), AppRoutes.teacherAttendanceHistory);
    expect(routeForNotification(_withRef('AttendanceRecord', null), AppRole.student), AppRoutes.studentMyAttendance);
    expect(routeForNotification(_withRef('AttendanceRecord', null), AppRole.parent), AppRoutes.parentChildAttendance);
  });

  test('AttendanceCorrection routes only for Admin, null for everyone else', () {
    expect(routeForNotification(_withRef('AttendanceCorrection', null), AppRole.admin), AppRoutes.adminAttendanceCorrections);
    expect(routeForNotification(_withRef('AttendanceCorrection', null), AppRole.teacher), isNull);
  });

  test('Subscription and null refModel have nothing to navigate to', () {
    expect(routeForNotification(_withRef('Subscription', 's1'), AppRole.admin), isNull);
    expect(routeForNotification(_withRef(null, null), AppRole.admin), isNull);
  });
}
