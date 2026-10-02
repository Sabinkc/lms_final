import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/self_attendance_provider.dart';
import '../widgets/attendance_history_body.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';

/// docs/screens.md "My Attendance" (Student) — own history + summary
/// percentage. `GET /api/attendance/me` resolves the caller's own
/// `Student._id` first (confirmed via `attendenceRoutes.js`), then loads
/// that student's history — no month filter UI yet (backend supports one,
/// see `AttendanceRepository.getStudentAttendanceHistory`, but the default
/// all-time view covers the P1 scope for now).
class MyAttendanceScreen extends StatefulWidget {
  const MyAttendanceScreen({super.key});

  @override
  State<MyAttendanceScreen> createState() => _MyAttendanceScreenState();
}

class _MyAttendanceScreenState extends State<MyAttendanceScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<SelfAttendanceProvider>();
    Future.microtask(() => provider.loadOwnHistory());
  }

  Future<void> _refresh() async {
    await context.read<SelfAttendanceProvider>().loadOwnHistory(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SelfAttendanceProvider>();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'My Attendance'),
        body: PullToRefresh(
          onRefresh: _refresh,
          child: AttendanceHistoryBody(
            status: provider.historyStatus,
            history: provider.history,
            error: provider.historyError,
            onRetry: () => provider.loadOwnHistory(),
          ),
        ),
      ),
    );
  }
}
