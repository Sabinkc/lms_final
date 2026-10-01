import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../../auth/data/models/app_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/group_conversation.dart';
import '../providers/chat_provider.dart';
import 'create_group_dialog.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';

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
        body: switch (provider.groupsStatus) {
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
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _query = value),
                          decoration: const InputDecoration(
                            hintText: 'Search conversations or classes...',
                            prefixIcon: Icon(Icons.search),
                            isDense: true,
                          ),
                        ),
                      ),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(child: Text('No conversations match your search'))
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 8),
                                itemBuilder: (context, index) => _GroupTile(group: filtered[index]),
                              ),
                      ),
                    ],
                  ),
        },
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  final GroupConversation group;

  const _GroupTile({required this.group});

  String get _initials {
    final words = group.className.trim().split(RegExp(r'\s+'));
    final base = words.isNotEmpty && words.first.isNotEmpty ? words.first : group.name;
    final letters = base.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    return letters.length >= 2 ? letters.substring(0, 2).toUpperCase() : letters.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final memberCount = group.memberIds.length + group.teacherIds.length;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.chatThread(group.id), extra: group),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: accent,
                child: Text(
                  _initials.isEmpty ? '?' : _initials,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      group.lastMessagePreview.isEmpty ? '$memberCount members' : group.lastMessagePreview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
