import 'dart:typed_data';

import '../../../../core/error/result.dart';
import '../../../admin_management/data/models/student.dart';
import '../models/eligible_target.dart';
import '../models/group_conversation.dart';
import '../models/group_message.dart';

/// `/api/group-chats` — class/section-scoped group chat (`api_spec.md` §7),
/// not 1:1 messaging. Guarded by `protectAny` throughout, which accepts
/// both Teacher and Student tokens (Admin/Parent tokens are also technically
/// accepted at this REST layer, but every handler 403s them via its own
/// Teacher/Student lookup — see each controller method) — Parent/Admin
/// screens are simply never built against this repository at all, matching
/// the real-time layer's socket-auth rejection of those roles.
abstract class ChatRepository {
  /// Teacher-only: classes/sections they're actually assigned to.
  Future<Result<List<EligibleTarget>>> getEligibleTargets();

  /// Teacher-only: previews who would be auto-enrolled before creating.
  Future<Result<List<Student>>> previewRoster({required String classId, String? sectionId});

  Future<Result<GroupConversation>> createGroup({
    required String classId,
    String? sectionId,
    String? name,
    List<String>? extraMemberIds,
  });

  /// Teacher -> their own groups; Student -> groups they're a member of
  /// (server-scoped by the caller's token, same shape either way).
  Future<Result<List<GroupConversation>>> getMyGroups();

  /// `(group, members)` — the only endpoint that populates full `Student`
  /// docs for `members` (`GET /` only returns bare ids).
  Future<Result<(GroupConversation, List<Student>)>> getGroupById(String id);

  Future<Result<GroupConversation>> updateMembers(
    String id, {
    List<String>? addStudentIds,
    List<String>? removeStudentIds,
  });

  Future<Result<void>> archiveGroup(String id);

  Future<Result<void>> deleteGroup(String id);

  /// `before` is a message id (cursor), not a page number or timestamp —
  /// confirmed by reading `groupMessageController.js`'s `getMessages`
  /// directly, resolving `api_spec.md` §11's previously-`UNKNOWN — VERIFY`
  /// pagination question.
  Future<Result<List<GroupMessage>>> getMessages(String conversationId, {String? before, int limit = 30});

  /// [attachmentBytes]/[attachmentFilename] are optional — this always
  /// posts as `multipart/form-data` (the route's `uploadChatMedia`
  /// middleware runs unconditionally, confirmed in `groupChatRoutes.js`,
  /// so even a text-only message can't be sent as plain JSON).
  Future<Result<GroupMessage>> sendMessage(
    String conversationId, {
    String? text,
    Uint8List? attachmentBytes,
    String? attachmentFilename,
  });

  Future<Result<void>> markRead(String conversationId);
}
