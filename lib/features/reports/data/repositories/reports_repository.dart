import '../../../../core/error/result.dart';
import '../models/academic_report.dart';
import '../models/attendance_report.dart';
import '../models/financial_report.dart';
import '../models/system_report.dart';

/// `/api/reports/*` (`protectAdmin`) — four fixed aggregate categories,
/// confirmed by reading `Reportcontroller.js`/`Reportroutes.js` directly.
/// No export/print exists on any of the four handlers (resolves
/// `implementation_backlog.md` E12-F2-T2's "unknown" to "not supported").
/// Only [getAttendanceReport] takes a query filter at all — there is no
/// server-side class filter anywhere in this module; the response's
/// per-category breakdown fields are already grouped instead (see each
/// model's own doc comment).
abstract class ReportsRepository {
  Future<Result<AcademicReport>> getAcademicReport();

  Future<Result<FinancialReport>> getFinancialReport();

  Future<Result<AttendanceReport>> getAttendanceReport({DateTime? startDate, DateTime? endDate});

  Future<Result<SystemReport>> getSystemReport();
}
