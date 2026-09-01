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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final isTeacher = context.watch<AuthProvider>().role == AppRole.teacher;

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      floatingActionButton: isTeacher
          ? FloatingActionButton(
              onPressed: () => showCreateGroupDialog(context, provider),
              tooltip: 'New Group',
              child: const Icon(Icons.add_comment_outlined),
            )
          : null,
      body: switch (provider.groupsStatus) {
        LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading conversations...'),
        LoadStatus.error => ErrorView(error: provider.groupsError!, onRetry: () => provider.loadGroups()),
        LoadStatus.success => provider.groups.isEmpty
            ? EmptyStateView(
                message: isTeacher ? 'No groups yet — create one for your class' : 'No group conversations yet',
                icon: Icons.chat_bubble_outline,
                actionLabel: isTeacher ? 'New Group' : null,
                onAction: isTeacher ? () => showCreateGroupDialog(context, provider) : null,
              )
            : ListView.builder(
                itemCount: provider.groups.length,
                itemBuilder: (context, index) {
                  final group = provider.groups[index];
                  return _GroupTile(group: group);
                },
              ),
      },
    );
  }
}

class _GroupTile extends StatelessWidget {
  final GroupConversation group;

  const _GroupTile({required this.group});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.groups_outlined)),
      title: Text(group.name),
      subtitle: Text(
        group.lastMessagePreview.isEmpty
            ? '${group.className}${group.sectionName != null ? ' ${group.sectionName}' : ''}'
            : group.lastMessagePreview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => context.push(AppRoutes.chatThread(group.id), extra: group),
    );
  }
}
