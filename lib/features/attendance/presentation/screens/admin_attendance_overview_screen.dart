import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../providers/admin_attendance_provider.dart';

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// docs/screens.md "Attendance Overview" (Admin) — school-wide session list
/// for a date, filterable by class/section. Reuses the same
/// `GET /api/attendance/student?date=` endpoint Teacher History uses; an
/// Admin token isn't teacher-scoped server-side, so it naturally returns
/// every session in the school instead of just one teacher's.
class AdminAttendanceOverviewScreen extends StatefulWidget {
  const AdminAttendanceOverviewScreen({super.key});

  @override
  State<AdminAttendanceOverviewScreen> createState() => _AdminAttendanceOverviewScreenState();
}

class _AdminAttendanceOverviewScreenState extends State<AdminAttendanceOverviewScreen> {
  final _classController = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final provider = context.read<AdminAttendanceProvider>();
    Future.microtask(() => provider.loadOverview(date: _formatDate(_date)));
  }

  @override
  void dispose() {
    _classController.dispose();
    super.dispose();
  }

  void _reload(AdminAttendanceProvider provider) =>
      provider.loadOverview(date: _formatDate(_date), className: _classController.text.trim());

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminAttendanceProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Overview')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _classController,
                    decoration: const InputDecoration(labelText: 'Filter by class (optional)'),
                    onSubmitted: (_) => _reload(provider),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(_formatDate(_date)),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _date = picked);
                      _reload(provider);
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (provider.overviewStatus) {
              LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading attendance...'),
              LoadStatus.error => ErrorView(error: provider.overviewError!, onRetry: () => _reload(provider)),
              LoadStatus.success => provider.overviewSessions.isEmpty
                  ? const EmptyStateView(message: 'No attendance submitted on this date', icon: Icons.event_busy_outlined)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: provider.overviewSessions.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final session = provider.overviewSessions[index];
                        return Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${session.className} — ${session.section} · ${session.subject}',
                                        style: Theme.of(context).textTheme.titleSmall,
                                      ),
                                    ),
                                    if (session.locked) const Icon(Icons.lock_outline, size: 18),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    AppStatusChip(label: '${session.presentCount} present', color: Colors.green),
                                    AppStatusChip(
                                      label: '${session.absentCount} absent',
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                    AppStatusChip(label: '${session.lateCount} late', color: Colors.orange),
                                    AppStatusChip(
                                      label: 'of ${session.totalCount}',
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            },
          ),
        ],
      ),
    );
  }
}
