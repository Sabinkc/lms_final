import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../../shared/widgets/tinted_stat_tile.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/attendance_session.dart';
import '../providers/admin_attendance_provider.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/readable_color.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';

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

  Future<void> _pickDate(AdminAttendanceProvider provider) async {
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
  }

  void _shiftDay(AdminAttendanceProvider provider, int delta) {
    final next = _date.add(Duration(days: delta));
    if (next.isAfter(DateTime.now())) return;
    setState(() => _date = next);
    _reload(provider);
  }

  Future<void> _refresh() async {
    await context.read<AdminAttendanceProvider>().loadOverview(
      date: _formatDate(_date),
      className: _classController.text.trim(),
      silent: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminAttendanceProvider>();
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(_date, now);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'Attendance Overview'),
        body: PullToRefresh(
          onRefresh: _refresh,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  children: [
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              tooltip: 'Previous day',
                              onPressed: () => _shiftDay(provider, -1),
                            ),
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                onTap: () => _pickDate(provider),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.calendar_today_outlined,
                                            size: 16,
                                            color: context.readable(AppColors.primary),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _prettyDate(_date),
                                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        isToday ? 'Today · school-wide' : 'School-wide',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              tooltip: 'Next day',
                              onPressed: isToday ? null : () => _shiftDay(provider, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _classController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Filter by class name',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerLow,
                        border: OutlineInputBorder(borderRadius: AppRadius.button, borderSide: BorderSide.none),
                      ),
                      onSubmitted: (_) => _reload(provider),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: switch (provider.overviewStatus) {
                  LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading attendance...'),
                  LoadStatus.error => ErrorView(error: provider.overviewError!, onRetry: () => _reload(provider)),
                  LoadStatus.success =>
                    provider.overviewSessions.isEmpty
                        ? const EmptyStateView(
                            message: 'No attendance submitted on this date',
                            icon: Icons.event_busy_outlined,
                          )
                        : _buildSessions(context, provider.overviewSessions),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessions(BuildContext context, List<AttendanceSessionSummary> sessions) {
    final present = sessions.fold<int>(0, (sum, s) => sum + s.presentCount);
    final absent = sessions.fold<int>(0, (sum, s) => sum + s.absentCount);
    final late = sessions.fold<int>(0, (sum, s) => sum + s.lateCount);
    final total = sessions.fold<int>(0, (sum, s) => sum + s.totalCount);
    String pct(int n) => total == 0 ? '0%' : '${(n * 100 / total).toStringAsFixed(1)}%';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: TintedStatTile(
                icon: Icons.fact_check_outlined,
                label: 'Sessions',
                value: '${sessions.length}',
                caption: _students(total),
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TintedStatTile(
                icon: Icons.how_to_reg_outlined,
                label: 'Present',
                value: pct(present + late),
                caption: _students(present + late),
                color: _presentGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TintedStatTile(
                icon: Icons.person_off_outlined,
                label: 'Absent',
                value: pct(absent),
                caption: _students(absent),
                color: AppColors.danger,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TintedStatTile(
                icon: Icons.alarm_outlined,
                label: 'Late',
                value: pct(late),
                caption: _students(late),
                color: _lateOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('Section Logs', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            AppStatusPill(label: '${sessions.length}', color: AppColors.info),
          ],
        ),
        const SizedBox(height: 10),
        for (final session in sessions) ...[_SessionCard(session: session), const SizedBox(height: 10)],
      ],
    );
  }
}

String _students(int n) => '$n student${n == 1 ? '' : 's'}';

const _presentGreen = Color(0xFF16A34A);
const _lateOrange = Color(0xFFEA580C);

/// Sections below this attended share are flagged for follow-up.
const _flagThreshold = 0.85;

String _prettyDate(DateTime d) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
}

class _SessionCard extends StatelessWidget {
  final AttendanceSessionSummary session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attended = session.presentCount + session.lateCount;
    final rate = session.totalCount == 0 ? 0.0 : attended / session.totalCount;
    final flagged = session.totalCount > 0 && rate < _flagThreshold;
    final rateColor = flagged ? _lateOrange : _presentGreen;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (flagged) Container(width: 5, color: _lateOrange),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.title,
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              if (session.subject.isNotEmpty)
                                Text(
                                  session.subject,
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              const SizedBox(height: 6),
                              if (flagged)
                                const AppStatusPill(
                                  label: 'Flagged (<85%)',
                                  icon: Icons.warning_amber_rounded,
                                  color: _lateOrange,
                                )
                              else if (session.locked)
                                const AppStatusPill(label: 'Locked', icon: Icons.lock_outline, color: AppColors.info)
                              else
                                const AppStatusPill(
                                  label: 'Submitted',
                                  icon: Icons.check_circle_outline,
                                  color: _presentGreen,
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${(rate * 100).toStringAsFixed(1)}%',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: context.readable(rateColor),
                              ),
                            ),
                            Text(_students(session.totalCount), style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.xl4),
                      child: LinearProgressIndicator(
                        value: rate,
                        minHeight: 6,
                        color: rateColor,
                        backgroundColor: rateColor.withValues(alpha: 0.12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        AppStatusPill(label: '${session.presentCount} Present', color: _presentGreen),
                        AppStatusPill(label: '${session.absentCount} Absent', color: AppColors.danger),
                        AppStatusPill(label: '${session.lateCount} Late', color: _lateOrange),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
