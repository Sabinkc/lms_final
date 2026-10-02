import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/progress_overlay.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/utils/display_date.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/filter_chip_bar.dart';
import '../../../../shared/widgets/page_hero_card.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../../auth/data/models/app_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/notice.dart';
import '../providers/notice_provider.dart';
import 'notice_form_dialog.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/readable_color.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';

/// docs/screens.md's Notices module. Admin-only creation for v1
/// (`docs/production_roadmap.md` §4 decision #2 — the backend's
/// `createdByModel` enum never included Teacher) — everyone else gets a
/// read-only list via the audience-filtered `GET /api/notices/my`.
///
/// Restyled 2026-10-01 to a reference the user supplied (`LMS UI/WhatsApp
/// Image ... 4.22.36 PM.jpeg`): "Stay Informed" hero with the total, filter
/// chips with counts, and cards with a colored icon tile, category tag,
/// title, 2-line preview, date and a "New" badge. See [_Category] for how
/// its categories map onto real notice fields. The reference's date pill is
/// omitted — notices have no date filter in the API, and a bare date would
/// only show today.
class NoticesListScreen extends StatefulWidget {
  const NoticesListScreen({super.key});

  @override
  State<NoticesListScreen> createState() => _NoticesListScreenState();
}

/// A notice's category chip / tag. Notices have no category field — only an
/// `audience` and an `isImportant` flag — so the reference's Academic /
/// Administrative / Events chips became "Urgent" (important notices) plus
/// one chip per real audience.
enum _Category { urgent, all, students, teachers, parents, admins }

_Category _categoryOf(Notice n) => n.isImportant
    ? _Category.urgent
    : switch (n.audience.toLowerCase()) {
        'students' => _Category.students,
        'teachers' => _Category.teachers,
        'parents' => _Category.parents,
        'admins' => _Category.admins,
        _ => _Category.all,
      };

(String label, IconData icon, Color color) _categoryStyle(_Category c) => switch (c) {
  _Category.urgent => ('Urgent', Icons.error_rounded, const Color(0xFFE11D48)),
  _Category.all => ('Everyone', Icons.campaign_rounded, const Color(0xFF2F80FF)),
  _Category.students => ('Students', Icons.school_rounded, const Color(0xFF7C3AED)),
  _Category.teachers => ('Teachers', Icons.co_present_rounded, AppColors.primary),
  _Category.parents => ('Parents', Icons.family_restroom_rounded, const Color(0xFFF2600C)),
  _Category.admins => ('Admins', Icons.admin_panel_settings_rounded, const Color(0xFF0EA5B7)),
};

class _NoticesListScreenState extends State<NoticesListScreen> {
  /// `null` = All.
  _Category? _filter;

  @override
  void initState() {
    super.initState();
    // Role is read inside the microtask, not captured here synchronously —
    // same reasoning as `AssignmentDetailScreen.initState`: `AuthProvider`'s
    // own restore-session call is async too, and reading `.role` too early
    // would silently pick the wrong branch.
    final provider = context.read<NoticeProvider>();
    final authProvider = context.read<AuthProvider>();
    Future.microtask(() {
      if (authProvider.role == AppRole.admin) {
        provider.loadNoticesAsAdmin();
      } else {
        provider.loadMyNotices();
      }
    });
  }

  Future<void> _refresh() async {
    final provider = context.read<NoticeProvider>();
    await (context.read<AuthProvider>().role == AppRole.admin
        ? provider.loadNoticesAsAdmin(silent: true)
        : provider.loadMyNotices(silent: true));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NoticeProvider>();
    final role = context.watch<AuthProvider>().role;
    final isAdmin = role == AppRole.admin;

    final notices = provider.notices;
    final counts = <_Category, int>{};
    for (final n in notices) {
      counts.update(_categoryOf(n), (c) => c + 1, ifAbsent: () => 1);
    }
    // Only categories that actually have notices get a chip.
    final chips = [
      for (final c in _Category.values)
        if ((counts[c] ?? 0) > 0) c,
    ];
    final filter = chips.contains(_filter) ? _filter : null;
    final visible = filter == null ? notices : notices.where((n) => _categoryOf(n) == filter).toList();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'Notices'),
        floatingActionButton: isAdmin
            ? FloatingActionButton(
                onPressed: () => showNoticeFormDialog(context, provider),
                tooltip: 'Add Notice',
                child: const Icon(Icons.add),
              )
            : null,
        body: PullToRefresh(
          onRefresh: _refresh,
          child: switch (provider.status) {
            LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading notices...'),
            LoadStatus.error => ErrorView(
              error: provider.error!,
              onRetry: () => isAdmin ? provider.loadNoticesAsAdmin() : provider.loadMyNotices(),
            ),
            LoadStatus.success =>
              notices.isEmpty
                  ? EmptyStateView(
                      message: 'No notices yet',
                      icon: Icons.campaign_outlined,
                      actionLabel: isAdmin ? 'Add Notice' : null,
                      onAction: isAdmin ? () => showNoticeFormDialog(context, provider) : null,
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                      children: [
                        PageHeroCard(
                          icon: Icons.campaign_rounded,
                          title: 'Stay Informed',
                          subtitle: 'The latest notices, announcements and important updates from your institution.',
                          color: const Color(0xFF2F80FF),
                          figure: '${notices.length}',
                        ),
                        const SizedBox(height: 14),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              AppFilterChip(
                                label: 'All',
                                count: notices.length,
                                selected: filter == null,
                                onTap: () => setState(() => _filter = null),
                              ),
                              for (final c in chips) ...[
                                const SizedBox(width: 8),
                                AppFilterChip(
                                  label: _categoryStyle(c).$1,
                                  icon: _categoryStyle(c).$2,
                                  count: counts[c]!,
                                  selected: filter == c,
                                  onTap: () => setState(() => _filter = c),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        for (final notice in visible) ...[
                          _NoticeCard(notice: notice, provider: provider, isAdmin: isAdmin),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
          },
        ),
      ),
    );
  }
}

/// "Stay Informed" hero from the reference: big megaphone, blurb, and a
/// Total Notices card. [total] is the loaded list's real length.
class _NoticeCard extends StatelessWidget {
  final Notice notice;
  final NoticeProvider provider;
  final bool isAdmin;

  const _NoticeCard({required this.notice, required this.provider, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, icon, color) = _categoryStyle(_categoryOf(notice));
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.noticeDetail(notice.id)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Icon(icon, color: context.readable(color), size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppStatusChip(label: label, color: color),
                        const Spacer(),
                        if (_isRecent(notice.createdAt)) const AppStatusChip(label: 'New', color: AppColors.primary),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(notice.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    if (notice.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(notice.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: muted),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 14, color: muted?.color),
                        const SizedBox(width: 4),
                        Text(formatDisplayDate(notice.createdAt), style: muted),
                        if (notice.createdByName.isNotEmpty) ...[
                          Text('  •  ', style: muted),
                          Flexible(
                            child: Text(
                              notice.createdByName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (isAdmin)
                PopupMenuButton<String>(
                  tooltip: 'Notice actions',
                  icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurfaceVariant),
                  onSelected: (value) => value == 'edit'
                      ? showNoticeFormDialog(context, provider, existing: notice)
                      : _confirmDelete(context, provider, notice),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 20, right: 8),
                  child: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "New" if posted within the last 3 days — purely a client-side heuristic
/// on the existing `createdAt` field, no new data.
bool _isRecent(String createdAt) {
  final parsed = DateTime.tryParse(createdAt);
  if (parsed == null) return false;
  return DateTime.now().difference(parsed) < const Duration(days: 3);
}

Future<void> _confirmDelete(BuildContext context, NoticeProvider provider, Notice notice) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete notice?'),
      content: Text('This will permanently delete "${notice.title}". This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Theme.of(dialogContext).colorScheme.error),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  final succeeded = await runWithProgress(context, () => provider.deleteNotice(notice.id), message: 'Deleting…');
  if (!succeeded && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(provider.actionError?.message ?? 'Failed to delete notice')));
  }
}
