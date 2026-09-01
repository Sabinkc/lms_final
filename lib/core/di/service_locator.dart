import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/admin_management/data/repositories/class_repository.dart';
import '../../features/admin_management/data/repositories/class_repository_http.dart';
import '../../features/admin_management/data/repositories/department_repository.dart';
import '../../features/admin_management/data/repositories/department_repository_http.dart';
import '../../features/admin_management/data/repositories/parent_repository.dart';
import '../../features/admin_management/data/repositories/parent_repository_http.dart';
import '../../features/admin_management/data/repositories/section_repository.dart';
import '../../features/admin_management/data/repositories/section_repository_http.dart';
import '../../features/admin_management/data/repositories/student_repository.dart';
import '../../features/admin_management/data/repositories/student_repository_http.dart';
import '../../features/admin_management/data/repositories/teacher_repository.dart';
import '../../features/admin_management/data/repositories/teacher_repository_http.dart';
import '../../features/admin_management/presentation/providers/academic_structure_provider.dart';
import '../../features/admin_management/presentation/providers/department_provider.dart';
import '../../features/admin_management/presentation/providers/parent_provider.dart';
import '../../features/admin_management/presentation/providers/student_provider.dart';
import '../../features/admin_management/presentation/providers/teacher_provider.dart';
import '../../features/assignments/data/repositories/assignment_repository.dart';
import '../../features/assignments/data/repositories/assignment_repository_http.dart';
import '../../features/assignments/presentation/providers/assignment_provider.dart';
import '../../features/attendance/data/repositories/attendance_correction_repository.dart';
import '../../features/attendance/data/repositories/attendance_correction_repository_http.dart';
import '../../features/attendance/data/repositories/attendance_repository.dart';
import '../../features/attendance/data/repositories/attendance_repository_http.dart';
import '../../features/attendance/presentation/providers/admin_attendance_provider.dart';
import '../../features/attendance/presentation/providers/attendance_provider.dart';
import '../../features/attendance/presentation/providers/self_attendance_provider.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/backup/data/repositories/backup_repository.dart';
import '../../features/backup/data/repositories/backup_repository_http.dart';
import '../../features/backup/presentation/providers/backup_provider.dart';
import '../../features/chat/data/repositories/chat_repository.dart';
import '../../features/chat/data/repositories/chat_repository_http.dart';
import '../../features/chat/presentation/providers/chat_provider.dart';
import '../../features/exams/data/repositories/exam_repository.dart';
import '../../features/exams/data/repositories/exam_repository_http.dart';
import '../../features/exams/data/repositories/exam_result_repository.dart';
import '../../features/exams/data/repositories/exam_result_repository_http.dart';
import '../../features/exams/presentation/providers/exam_provider.dart';
import '../../features/exams/presentation/providers/exam_result_provider.dart';
import '../../features/fees/data/repositories/fee_repository.dart';
import '../../features/fees/data/repositories/fee_repository_http.dart';
import '../../features/fees/data/repositories/payment_repository.dart';
import '../../features/fees/data/repositories/payment_repository_http.dart';
import '../../features/fees/presentation/providers/fee_provider.dart';
import '../../features/fees/presentation/providers/self_fee_provider.dart';
import '../../features/id_cards/data/repositories/id_card_repository.dart';
import '../../features/id_cards/data/repositories/id_card_repository_http.dart';
import '../../features/id_cards/presentation/providers/admin_id_card_provider.dart';
import '../../features/id_cards/presentation/providers/student_id_card_provider.dart';
import '../../features/notices/data/repositories/notice_repository.dart';
import '../../features/notices/data/repositories/notice_repository_http.dart';
import '../../features/notices/presentation/providers/notice_provider.dart';
import '../../features/notifications/data/repositories/notification_repository.dart';
import '../../features/notifications/data/repositories/notification_repository_http.dart';
import '../../features/notifications/presentation/providers/notification_provider.dart';
import '../../features/payroll/data/repositories/payroll_repository.dart';
import '../../features/payroll/data/repositories/payroll_repository_http.dart';
import '../../features/payroll/presentation/providers/my_payslips_provider.dart';
import '../../features/payroll/presentation/providers/payroll_provider.dart';
import '../../features/reports/data/repositories/reports_repository.dart';
import '../../features/reports/data/repositories/reports_repository_http.dart';
import '../../features/reports/presentation/providers/reports_provider.dart';
import '../../features/student_followups/data/repositories/student_followup_repository.dart';
import '../../features/student_followups/data/repositories/student_followup_repository_http.dart';
import '../../features/student_followups/presentation/providers/student_followup_provider.dart';
import '../../features/timetable/data/repositories/timetable_repository.dart';
import '../../features/timetable/data/repositories/timetable_repository_http.dart';
import '../../features/timetable/presentation/providers/admin_timetable_provider.dart';
import '../../features/timetable/presentation/providers/student_timetable_provider.dart';
import '../../features/timetable/presentation/providers/teacher_timetable_provider.dart';
import '../../features/auth/data/repositories/auth_repository_http.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../config/env.dart';
import '../network/api_client.dart';
import '../realtime/realtime_service.dart';
import '../storage/local_prefs_service.dart';
import '../storage/secure_storage_service.dart';

/// The single composition root (docs/architecture.md §5). Every repository
/// and every feature provider is constructed exactly once, here — nothing
/// else in the app should call a constructor for one of these types
/// directly. Widgets get providers via `MultiProvider` in `lib/app.dart`
/// (built by reading straight out of [sl]); repositories get their
/// dependencies (like [ApiClient]) injected through this same registry.
///
/// Swapping which `AuthRepository` implementation is wired is a single
/// line — see the registration below. Nothing in `features/auth/
/// presentation` changes when that line flips (docs/architecture.md §5).
final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator(EnvConfig env) async {
  // ── Core / infrastructure ────────────────────────────────────────────
  sl.registerSingleton<EnvConfig>(env);

  final sharedPrefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPrefs);
  sl.registerLazySingleton<LocalPrefsService>(() => LocalPrefsService(sl()));

  sl.registerLazySingleton<FlutterSecureStorage>(() => const FlutterSecureStorage());
  sl.registerLazySingleton<SecureStorageService>(() => SecureStorageService(sl()));

  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(env: sl(), secureStorage: sl()),
  );

  sl.registerLazySingleton<RealtimeService>(() => SocketIoRealtimeService(sl()));

  // ── Feature: Auth ─────────────────────────────────────────────────────
  // Real backend, as of docs/production_roadmap.md Phase A. See
  // docs/local_backend_setup.md for what this is wired against locally.
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryHttp(sl(), sl(), sl()));

  sl.registerLazySingleton<AuthProvider>(() => AuthProvider(sl()));

  // ── Feature: Admin Management (Phase B) ─────────────────────────────────
  sl.registerLazySingleton<ClassRepository>(() => ClassRepositoryHttp(sl()));
  sl.registerLazySingleton<SectionRepository>(() => SectionRepositoryHttp(sl()));
  sl.registerFactory<AcademicStructureProvider>(() => AcademicStructureProvider(sl(), sl()));

  sl.registerLazySingleton<TeacherRepository>(() => TeacherRepositoryHttp(sl()));
  sl.registerFactory<TeacherProvider>(() => TeacherProvider(sl()));

  sl.registerLazySingleton<StudentRepository>(() => StudentRepositoryHttp(sl()));
  sl.registerFactory<StudentProvider>(() => StudentProvider(sl(), sl(), sl()));

  sl.registerLazySingleton<ParentRepository>(() => ParentRepositoryHttp(sl()));
  sl.registerFactory<ParentProvider>(() => ParentProvider(sl(), sl()));

  sl.registerLazySingleton<DepartmentRepository>(() => DepartmentRepositoryHttp(sl()));
  sl.registerFactory<DepartmentProvider>(() => DepartmentProvider(sl(), sl(), sl()));

  // ── Feature: Attendance (Phase C) ───────────────────────────────────────
  sl.registerLazySingleton<AttendanceRepository>(() => AttendanceRepositoryHttp(sl()));
  sl.registerFactory<AttendanceProvider>(() => AttendanceProvider(sl()));

  sl.registerLazySingleton<AttendanceCorrectionRepository>(() => AttendanceCorrectionRepositoryHttp(sl()));
  sl.registerFactory<AdminAttendanceProvider>(() => AdminAttendanceProvider(sl(), sl()));

  sl.registerFactory<SelfAttendanceProvider>(() => SelfAttendanceProvider(sl()));

  // ── Feature: Assignments (Phase D, System A) ────────────────────────────
  sl.registerLazySingleton<AssignmentRepository>(() => AssignmentRepositoryHttp(sl()));
  sl.registerFactory<AssignmentProvider>(() => AssignmentProvider(sl()));

  // ── Feature: Notices (Phase E, Admin-only creation) ─────────────────────
  sl.registerLazySingleton<NoticeRepository>(() => NoticeRepositoryHttp(sl()));
  sl.registerFactory<NoticeProvider>(() => NoticeProvider(sl()));

  // ── Feature: Exams & Results (Phase F, System B) ────────────────────────
  sl.registerLazySingleton<ExamRepository>(() => ExamRepositoryHttp(sl()));
  sl.registerFactory<ExamProvider>(() => ExamProvider(sl()));

  sl.registerLazySingleton<ExamResultRepository>(() => ExamResultRepositoryHttp(sl()));
  sl.registerFactory<ExamResultProvider>(() => ExamResultProvider(sl(), sl()));

  // ── Feature: Fees & Payments (Phase G) ──────────────────────────────────
  sl.registerLazySingleton<FeeRepository>(() => FeeRepositoryHttp(sl()));
  sl.registerLazySingleton<PaymentRepository>(() => PaymentRepositoryHttp(sl()));
  sl.registerFactory<FeeProvider>(() => FeeProvider(sl(), sl(), sl()));
  sl.registerFactory<SelfFeeProvider>(() => SelfFeeProvider(sl(), sl(), sl()));

  // ── Feature: Payroll (Phase G) ───────────────────────────────────────────
  sl.registerLazySingleton<PayrollRepository>(() => PayrollRepositoryHttp(sl()));
  sl.registerFactory<PayrollProvider>(() => PayrollProvider(sl(), sl()));
  sl.registerFactory<MyPayslipsProvider>(() => MyPayslipsProvider(sl()));

  // ── Feature: Chat (Phase H) ──────────────────────────────────────────────
  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryHttp(sl()));
  sl.registerFactory<ChatProvider>(() => ChatProvider(sl(), sl(), sl()));

  // ── Feature: Notifications (Phase I) ─────────────────────────────────────
  sl.registerLazySingleton<NotificationRepository>(() => NotificationRepositoryHttp(sl()));
  sl.registerFactory<NotificationProvider>(() => NotificationProvider(sl()));

  // ── Feature: Reports (Phase J) ───────────────────────────────────────────
  sl.registerLazySingleton<ReportsRepository>(() => ReportsRepositoryHttp(sl()));
  sl.registerFactory<ReportsProvider>(() => ReportsProvider(sl()));

  // ── Feature: Backup (Phase L1) ───────────────────────────────────────────
  sl.registerLazySingleton<BackupRepository>(() => BackupRepositoryHttp(sl()));
  sl.registerFactory<BackupProvider>(() => BackupProvider(sl()));

  // ── Feature: Timetable (Phase L4) ────────────────────────────────────────
  sl.registerLazySingleton<TimetableRepository>(() => TimetableRepositoryHttp(sl()));
  sl.registerFactory<AdminTimetableProvider>(() => AdminTimetableProvider(sl()));
  sl.registerFactory<TeacherTimetableProvider>(() => TeacherTimetableProvider(sl()));
  sl.registerFactory<StudentTimetableProvider>(() => StudentTimetableProvider(sl()));

  // ── Feature: Student Follow-ups (Phase L5) ───────────────────────────────
  sl.registerLazySingleton<StudentFollowupRepository>(() => StudentFollowupRepositoryHttp(sl()));
  sl.registerFactory<StudentFollowupProvider>(() => StudentFollowupProvider(sl()));

  // ── Feature: ID Cards (Phase L6) ─────────────────────────────────────────
  sl.registerLazySingleton<IdCardRepository>(() => IdCardRepositoryHttp(sl()));
  sl.registerFactory<AdminIdCardProvider>(() => AdminIdCardProvider(sl(), sl()));
  sl.registerFactory<StudentIdCardProvider>(() => StudentIdCardProvider(sl()));
}

/// Test-only: drops every registration so each test file starts from a
/// clean container instead of leaking state between tests.
Future<void> resetServiceLocator() => sl.reset();
