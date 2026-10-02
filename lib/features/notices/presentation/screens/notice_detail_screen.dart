import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/utils/display_date.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../providers/notice_provider.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/readable_color.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';

/// docs/screens.md's Notice Detail — read-only for every role (Admin's
/// edit/delete live on the list screen's row actions, not here).
class NoticeDetailScreen extends StatefulWidget {
  final String noticeId;

  const NoticeDetailScreen({super.key, required this.noticeId});

  @override
  State<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends State<NoticeDetailScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<NoticeProvider>();
    Future.microtask(() => provider.loadNoticeDetail(widget.noticeId));
  }

  Future<void> _refresh() async {
    await context.read<NoticeProvider>().loadNoticeDetail(widget.noticeId, silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NoticeProvider>();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'Notice'),
        body: PullToRefresh(
          onRefresh: _refresh,
          child: switch (provider.detailStatus) {
            LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading notice...'),
            LoadStatus.error => ErrorView(
              error: provider.detailError!,
              onRetry: () => provider.loadNoticeDetail(widget.noticeId),
            ),
            LoadStatus.success => Builder(
              builder: (context) {
                final notice = provider.currentNotice!;
                final theme = Theme.of(context);
                final audience = _audienceStyle(notice.audience);
                final expiry = DateTime.tryParse(notice.expiryDate ?? '');
                final expired = expiry != null && expiry.isBefore(DateTime.now());
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                if (notice.isImportant)
                                  AppStatusPill(
                                    label: 'Important',
                                    icon: Icons.error_rounded,
                                    color: theme.colorScheme.error,
                                  ),
                                AppStatusPill(label: audience.label, icon: audience.icon, color: audience.color),
                                if (expired)
                                  AppStatusPill(
                                    label: 'Expired',
                                    icon: Icons.event_busy_outlined,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              notice.title,
                              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, height: 1.25),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                              ),
                              child: Column(
                                children: [
                                  if (notice.createdByName.isNotEmpty)
                                    _MetaRow(
                                      icon: Icons.person_outline,
                                      color: AppColors.primary,
                                      label: 'Posted by',
                                      value: notice.createdByName,
                                    ),
                                  _MetaRow(
                                    icon: audience.icon,
                                    color: audience.color,
                                    label: 'Audience',
                                    value: audience.label,
                                  ),
                                  _MetaRow(
                                    icon: Icons.event_outlined,
                                    color: const Color(0xFFEA580C),
                                    label: 'Published',
                                    value: formatDisplayDate(notice.createdAt),
                                  ),
                                  if (notice.expiryDate != null && notice.expiryDate!.isNotEmpty)
                                    _MetaRow(
                                      icon: Icons.event_busy_outlined,
                                      color: theme.colorScheme.error,
                                      label: 'Expires',
                                      value: formatDisplayDate(notice.expiryDate!),
                                    ),
                                ],
                              ),
                            ),
                            const Divider(height: 32),
                            Text(notice.description, style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          },
        ),
      ),
    );
  }
}

/// Same audience labels/colours as the Notices list chips.
({String label, IconData icon, Color color}) _audienceStyle(String audience) => switch (audience.toLowerCase()) {
  'students' => (label: 'Students', icon: Icons.school_rounded, color: const Color(0xFF7C3AED)),
  'teachers' => (label: 'Teachers', icon: Icons.co_present_rounded, color: AppColors.primary),
  'parents' => (label: 'Parents', icon: Icons.family_restroom_rounded, color: const Color(0xFFF2600C)),
  'admins' => (label: 'Admins', icon: Icons.admin_panel_settings_rounded, color: const Color(0xFF0EA5B7)),
  _ => (label: 'Everyone', icon: Icons.campaign_rounded, color: const Color(0xFF2F80FF)),
};

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _MetaRow({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, size: 15, color: context.readable(color)),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 84,
            child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
