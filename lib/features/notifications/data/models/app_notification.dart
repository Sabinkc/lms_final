/// Shape confirmed by reading `notificationSchema.js`/
/// `notificationController.js` directly. `refModel` is a polymorphic-
/// reference discriminator (`Fee|Attendance|AttendanceSession|
/// AttendanceRecord|AttendanceCorrection|Assignment|Exam|Result|
/// Subscription|null`) used client-side to decide where a tap should
/// navigate — see `notification_route.dart`. Note `refModel` has **no**
/// `"Payroll"` entry despite `type` including `"payroll"` — confirmed by
/// reading the schema directly, not an oversight in this model: a payroll
/// notification (`payrollController.js`'s `notifyStaff`) is actually
/// created with `type: "general"` and no `refId`/`refModel` at all, so it
/// was never reachable via this polymorphic path to begin with.
class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String? refId;
  final String? refModel;
  final String createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.refId,
    required this.refModel,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['_id'] as String? ?? json['id'] as String,
        title: json['title'] as String? ?? '',
        message: json['message'] as String? ?? '',
        type: json['type'] as String? ?? 'general',
        isRead: json['isRead'] as bool? ?? false,
        refId: json['refId'] as String?,
        refModel: json['refModel'] as String?,
        createdAt: json['createdAt'] as String? ?? '',
      );
}
