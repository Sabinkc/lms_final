import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/utils/relative_time.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/filter_chip_bar.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../../auth/data/models/app_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/group_conversation.dart';
import '../providers/chat_provider.dart';
import 'create_group_dialog.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/readable_color.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';

/// docs/production_roadmap.md Phase H — one shared list for Teacher and
/// Student (`GET /group-chats` is role-scoped server-side: a Teacher's own
/// groups vs. groups a Student is a member of, same as
/// `AssignmentsListScreen`'s one-shared-list reasoning). Parent/Admin never
/// route here at all — the backend rejects their sockets outright and has
/// no chat data model for either (`api_spec.md` §7).
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _classFilter;

  // Captured once, not read again in dispose(): by teardown time (e.g. a
  // full-tree unmount on logout, or a test's pumpWidget-away) the element
  // providing ChatProvider may already be deactivated, and
  // `context.read`/`Provider.of` inside `dispose()` throws "Looking up a
  // deactivated widget's ancestor is unsafe" in that case — this is exactly
  // the pattern Flutter's own assertion message recommends instead.
  ChatProvider? _provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<ChatProvider>();
  }

  @override
  void initState() {
    super.initState();
    final provider = context.read<ChatProvider>();
    Future.microtask(() => provider.loadGroups());
  }

  @override
  void dispose() {
    // The socket connection is only needed while some Chat screen is on
    // screen — this fires once the whole Chat section (list + any pushed
    // thread) is popped, not on every rebuild, since `dispose` only runs
    // when the widget is actually removed from the tree.
    _provider?.disconnectRealtime();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await context.read<ChatProvider>().loadGroups(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final isTeacher = context.watch<AuthProvider>().role == AppRole.teacher;
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? provider.groups
        : provider.groups
              .where((g) => g.name.toLowerCase().contains(query) || g.className.toLowerCase().contains(query))
              .toList();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(
          title: 'Chat',
          actions: [
            if (isTeacher)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton.icon(
                  key: const Key('newGroupAppBarButton'),
                  onPressed: () => showCreateGroupDialog(context, provider),
                  icon: const Icon(Icons.group_add, size: 18),
                  label: const Text('New Group'),
                ),
              ),
          ],
        ),
        body: PullToRefresh(
          onRefresh: _refresh,
          child: switch (provider.groupsStatus) {
            LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading conversations...'),
            LoadStatus.error => ErrorView(error: provider.groupsError!, onRetry: () => provider.loadGroups()),
            LoadStatus.success =>
              provider.groups.isEmpty
                  ? EmptyStateView(
                      message: isTeacher ? 'No groups yet — create one for your class' : 'No group conversations yet',
                      icon: Icons.chat_bubble_outline,
                      actionLabel: isTeacher ? 'New Group' : null,
                      onAction: isTeacher ? () => showCreateGroupDialog(context, provider) : null,
                    )
                  : _buildList(context, provider, filtered),
          },
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, ChatProvider provider, List<GroupConversation> searched) {
    final classCounts = <String, int>{};
    for (final g in provider.groups) {
      if (g.className.isNotEmpty) classCounts[g.className] = (classCounts[g.className] ?? 0) + 1;
    }
    final classFilter = classCounts.containsKey(_classFilter) ? _classFilter : null;
    final visible = [
      for (final g in searched)
        if (classFilter == null || g.className == classFilter) g,
    ];
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            hintText: 'Search conversations or classes...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: scheme.surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: AppRadius.button, borderSide: BorderSide.none),
          ),
        ),
        if (classCounts.length > 1) ...[
          const SizedBox(height: 12),
          AppFilterChipBar<String?>(
            options: [null, ...classCounts.keys],
            selected: classFilter,
            labelBuilder: (c) => c ?? 'All',
            countBuilder: (c) => c == null ? provider.groups.length : classCounts[c]!,
            onSelected: (c) => setState(() => _classFilter = c),
          ),
        ],
        const SizedBox(height: 14),
        if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 32),
            child: EmptyStateView(message: 'No conversations match your search', icon: Icons.search_off),
          ),
        for (final group in visible) ...[_GroupTile(group: group), const SizedBox(height: 10)],
      ],
    );
  }
}

class _GroupTile extends StatelessWidget {
  final GroupConversation group;

  const _GroupTile({required this.group});

  /// A stable tint per group so the list isn't one flat color.
  static const _palette = [
    Color(0xFF0B6E4F),
    Color(0xFF4F46E5),
    Color(0xFFEA580C),
    Color(0xFF0891B2),
    Color(0xFFDB2777),
    Color(0xFF7C3AED),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _palette[group.id.hashCode.abs() % _palette.length];
    final memberCount = group.memberIds.length + group.teacherIds.length;
    final when = group.lastMessageAt == null ? '' : formatRelativeTime(group.lastMessageAt!);
    final subtitle = [
      if (group.className.isNotEmpty) group.className,
      if (group.sectionName != null && group.sectionName!.isNotEmpty) 'Section ${group.sectionName}',
    ].join(' · ');

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.chatThread(group.id), extra: group),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(Icons.forum_outlined, color: context.readable(color)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (when.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            when,
                            style: theme.textTheme.labelSmall?.copyWith(color: context.readable(AppColors.primary)),
                          ),
                        ],
                      ],
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.lastMessagePreview.isEmpty ? 'No messages yet' : group.lastMessagePreview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontStyle: group.lastMessagePreview.isEmpty ? FontStyle.italic : null,
                              color: group.lastMessagePreview.isEmpty ? theme.colorScheme.onSurfaceVariant : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppStatusPill(label: '$memberCount', icon: Icons.people_outline, color: color),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
