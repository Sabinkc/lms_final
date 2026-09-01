/// `GET /reports/system` response shape, confirmed by reading
/// `Reportcontroller.js`'s `getSystemReport` directly.
///
/// **Real backend security gap found, not fixed** (backend is read-only per
/// this project's methodology — see `docs/local_backend_setup.md`): the
/// handler's `AuditLog.find()` call has **no `schoolId` filter at all**,
/// unlike the other three report endpoints (Academic/Financial/Attendance
/// all scope their queries to `req.admin.schoolId`). Every school's Admin
/// calling this endpoint sees the most recent 200 audit-log entries across
/// the *entire multi-tenant platform*, not just their own school. This app
/// only ever calls it for the logged-in Admin and displays whatever comes
/// back — it doesn't attempt to filter client-side, since [recentLogs]
/// doesn't even carry a `schoolId` field to filter by. Flagged here rather
/// than worked around; should be fixed backend-side (add `{ schoolId }` to
/// the query) before production — same disposition as the Fees ownership
/// gap recorded in `docs/production_roadmap.md` Phase G (`GET /fees/:id`).
class SystemReport {
  final int totalStudents;
  final int totalTeachers;
  final int totalParents;
  final int totalLogs;
  final Map<String, int> actionBreakdown;
  final List<AuditLogEntry> recentLogs;

  const SystemReport({
    required this.totalStudents,
    required this.totalTeachers,
    required this.totalParents,
    required this.totalLogs,
    required this.actionBreakdown,
    required this.recentLogs,
  });

  factory SystemReport.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? const {};
    final actionBreakdown = (json['actionBreakdown'] as Map<String, dynamic>? ?? const {})
        .map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0));
    final logs = (json['logs'] as List? ?? const [])
        .take(20)
        .map((entry) => AuditLogEntry.fromJson(entry as Map<String, dynamic>))
        .toList();
    return SystemReport(
      totalStudents: (summary['totalStudents'] as num?)?.toInt() ?? 0,
      totalTeachers: (summary['totalTeachers'] as num?)?.toInt() ?? 0,
      totalParents: (summary['totalParents'] as num?)?.toInt() ?? 0,
      totalLogs: (summary['totalLogs'] as num?)?.toInt() ?? 0,
      actionBreakdown: actionBreakdown,
      recentLogs: logs,
    );
  }
}

/// Only the first 20 of the server's (already-capped-at-200) `logs` array
/// are kept client-side — this is a "recent activity" preview, not an
/// audit-log browser.
class AuditLogEntry {
  final String action;
  final String user;
  final String category;
  final String status;
  final String? createdAt;

  const AuditLogEntry({
    required this.action,
    required this.user,
    required this.category,
    required this.status,
    required this.createdAt,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) => AuditLogEntry(
        action: json['action'] as String? ?? '',
        user: json['user'] as String? ?? 'System',
        category: json['category'] as String? ?? 'General',
        status: json['status'] as String? ?? 'success',
        createdAt: json['createdAt'] as String?,
      );
}
