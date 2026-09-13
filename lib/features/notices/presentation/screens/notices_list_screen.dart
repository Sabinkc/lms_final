import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../../auth/data/models/app_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/notice.dart';
import '../providers/notice_provider.dart';
import 'notice_form_dialog.dart';

/// docs/screens.md's Notices module. Admin-only creation for v1
/// (`docs/production_roadmap.md` §4 decision #2 — the backend's
/// `createdByModel` enum never included Teacher) — everyone else gets a
/// read-only list via the audience-filtered `GET /api/notices/my`.
class NoticesListScreen extends StatefulWidget {
  const NoticesListScreen({super.key});

  @override
  State<NoticesListScreen> createState() => _NoticesListScreenState();
}

class _NoticesListScreenState extends State<NoticesListScreen> {
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NoticeProvider>();
    final role = context.watch<AuthProvider>().role;
    final isAdmin = role == AppRole.admin;

    return Scaffold(
      appBar: AppBar(title: const Text('Notices')),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => showNoticeFormDialog(context, provider),
              tooltip: 'Add Notice',
              child: const Icon(Icons.add),
            )
          : null,
      body: switch (provider.status) {
        LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading notices...'),
        LoadStatus.error => ErrorView(
            error: provider.error!,
            onRetry: () => isAdmin ? provider.loadNoticesAsAdmin() : provider.loadMyNotices(),
          ),
        LoadStatus.success => provider.notices.isEmpty
            ? EmptyStateView(
                message: 'No notices yet',
                icon: Icons.campaign_outlined,
                actionLabel: isAdmin ? 'Add Notice' : null,
                onAction: isAdmin ? () => showNoticeFormDialog(context, provider) : null,
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                itemCount: provider.notices.length + 1,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Total Notices: ${provider.notices.length}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    );
                  }
                  final notice = provider.notices[index - 1];
                  final scheme = Theme.of(context).colorScheme;
                  final tint = notice.isImportant ? scheme.error : scheme.primary;
                  final isNew = _isRecent(notice.createdAt);
                  return Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: tint.withValues(alpha: 0.14),
                        child: Icon(
                          notice.isImportant ? Icons.priority_high : Icons.campaign_outlined,
                          color: tint,
                          size: 20,
                        ),
                      ),
                      title: Text(notice.title, style: Theme.of(context).textTheme.titleSmall),
                      subtitle: Text('Audience: ${notice.audience}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isNew) ...[
                            const AppStatusChip(label: 'New', color: Colors.green),
                            if (isAdmin) const SizedBox(width: 4),
                          ],
                          if (isAdmin) _AdminRowActions(notice: notice, provider: provider),
                        ],
                      ),
                      onTap: () => context.push(AppRoutes.noticeDetail(notice.id)),
                    ),
                  );
                },
              ),
      },
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

class _AdminRowActions extends StatelessWidget {
  final Notice notice;
  final NoticeProvider provider;

  const _AdminRowActions({required this.notice, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Edit',
          onPressed: () => showNoticeFormDialog(context, provider, existing: notice),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete',
          onPressed: () => _confirmDelete(context, provider, notice),
        ),
      ],
    );
  }
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

  final succeeded = await provider.deleteNotice(notice.id);
  if (!succeeded && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.actionError?.message ?? 'Failed to delete notice')),
    );
  }
}
