import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/realtime/realtime_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../admin_management/data/models/student.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/eligible_target.dart';
import '../../data/models/group_conversation.dart';
import '../../data/models/group_message.dart';
import '../../data/repositories/chat_repository.dart';

/// Group Conversation List + Thread + Teacher's create/manage flow — one
/// provider, matching this app's "one `ChangeNotifier` per feature" rule.
/// The "currently open thread" is fields on this same provider that get
/// overwritten each time [openThread] is called, the same shape
/// `AssignmentProvider` uses for its list-plus-detail state, rather than a
/// separate per-thread provider instance.
///
/// Real-time wiring (`api_spec.md` §7/§9): [RealtimeService] is connected
/// lazily the first time [loadGroups] runs (Admin/Parent never reach this
/// provider at all, so there's no need to guard against their sockets being
/// rejected here — the router already keeps them off every Chat route).
/// Every socket call is defensive — a failed/absent connection never blocks
/// the REST-driven functionality (send/list/read), only the live fan-out to
/// *other* room members, matching `api_spec.md` §7's "sending is REST, only
/// delivery to others is socket" design.
class ChatProvider extends ChangeNotifier {
  final ChatRepository _repository;
  final RealtimeService _realtimeService;
  final SecureStorageService _secureStorage;

  ChatProvider(this._repository, this._realtimeService, this._secureStorage);

  LoadStatus _groupsStatus = LoadStatus.initial;
  List<GroupConversation> _groups = const [];
  AppException? _groupsError;

  LoadStatus _targetsStatus = LoadStatus.initial;
  List<EligibleTarget> _eligibleTargets = const [];
  List<Student> _rosterPreview = const [];
  bool _isSaving = false;
  AppException? _actionError;

  List<Student> _groupMembers = const [];

  String? _currentConversationId;
  LoadStatus _messagesStatus = LoadStatus.initial;
  List<GroupMessage> _messages = const [];
  AppException? _messagesError;
  bool _isSending = false;
  AppException? _sendError;
  final Set<String> _typingUserNames = {};

  LoadStatus get groupsStatus => _groupsStatus;
  List<GroupConversation> get groups => _groups;
  AppException? get groupsError => _groupsError;

  LoadStatus get targetsStatus => _targetsStatus;
  List<EligibleTarget> get eligibleTargets => _eligibleTargets;
  List<Student> get rosterPreview => _rosterPreview;
  bool get isSaving => _isSaving;
  AppException? get actionError => _actionError;

  List<Student> get groupMembers => _groupMembers;

  String? get currentConversationId => _currentConversationId;
  LoadStatus get messagesStatus => _messagesStatus;
  List<GroupMessage> get messages => _messages;
  AppException? get messagesError => _messagesError;
  bool get isSending => _isSending;
  AppException? get sendError => _sendError;
  Set<String> get typingUserNames => _typingUserNames;

  Future<void> _ensureRealtimeConnected() async {
    if (_realtimeService.isConnected) return;
    final token = await _secureStorage.readAccessToken();
    if (token == null) return;
    try {
      await _realtimeService.connect(token);
    } catch (_) {
      // Live delivery to other members degrades; REST-driven send/list/read
      // still work, so a connect failure is never fatal here.
    }
  }

  void disconnectRealtime() => _realtimeService.disconnect();

  Future<void> loadGroups({bool silent = false}) async {
    // A silent reload (pull-to-refresh) keeps the current data on screen.
    if (!silent || _groupsStatus != LoadStatus.success) _groupsStatus = LoadStatus.loading;
    _groupsError = null;
    notifyListeners();

    unawaited(_ensureRealtimeConnected());

    final result = await _repository.getMyGroups();
    result.when(
      success: (groups) {
        _groups = groups;
        _groupsStatus = LoadStatus.success;
      },
      failure: (error) {
        _groupsError = error;
        _groupsStatus = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<void> loadEligibleTargets({bool silent = false}) async {
    // A silent reload (pull-to-refresh) keeps the current data on screen.
    if (!silent || _targetsStatus != LoadStatus.success) _targetsStatus = LoadStatus.loading;
    notifyListeners();

    final result = await _repository.getEligibleTargets();
    result.when(
      success: (targets) {
        _eligibleTargets = targets;
        _targetsStatus = LoadStatus.success;
      },
      failure: (error) => _targetsStatus = LoadStatus.error,
    );
    notifyListeners();
  }

  Future<void> loadRosterPreview({required String classId, String? sectionId}) async {
    final result = await _repository.previewRoster(classId: classId, sectionId: sectionId);
    result.when(success: (students) => _rosterPreview = students, failure: (_) => _rosterPreview = const []);
    notifyListeners();
  }

  Future<bool> createGroup({required String classId, String? sectionId, String? name}) async {
    _isSaving = true;
    _actionError = null;
    notifyListeners();

    final result = await _repository.createGroup(classId: classId, sectionId: sectionId, name: name);
    final succeeded = result.isSuccess;
    result.when(success: (created) => _groups = [created, ..._groups], failure: (error) => _actionError = error);

    _isSaving = false;
    notifyListeners();
    return succeeded;
  }

  Future<void> loadGroupMembers(String conversationId) async {
    final result = await _repository.getGroupById(conversationId);
    result.when(success: (data) => _groupMembers = data.$2, failure: (_) => _groupMembers = const []);
    notifyListeners();
  }

  Future<bool> updateMembers(
    String conversationId, {
    List<String>? addStudentIds,
    List<String>? removeStudentIds,
  }) async {
    _isSaving = true;
    _actionError = null;
    notifyListeners();

    final result = await _repository.updateMembers(
      conversationId,
      addStudentIds: addStudentIds,
      removeStudentIds: removeStudentIds,
    );
    final succeeded = result.isSuccess;
    result.when(success: (_) {}, failure: (error) => _actionError = error);

    _isSaving = false;
    if (succeeded) await loadGroupMembers(conversationId);
    notifyListeners();
    return succeeded;
  }

  Future<bool> archiveGroup(String id) async {
    _actionError = null;
    final result = await _repository.archiveGroup(id);
    final succeeded = result.isSuccess;
    result.when(
      success: (_) => _groups = _groups.where((g) => g.id != id).toList(),
      failure: (error) => _actionError = error,
    );
    notifyListeners();
    return succeeded;
  }

  Future<bool> deleteGroup(String id) async {
    _actionError = null;
    final result = await _repository.deleteGroup(id);
    final succeeded = result.isSuccess;
    result.when(
      success: (_) => _groups = _groups.where((g) => g.id != id).toList(),
      failure: (error) => _actionError = error,
    );
    notifyListeners();
    return succeeded;
  }

  Future<void> openThread(String conversationId) async {
    _currentConversationId = conversationId;
    _messagesStatus = LoadStatus.loading;
    _messagesError = null;
    _typingUserNames.clear();
    notifyListeners();

    await _ensureRealtimeConnected();
    _joinRoom(conversationId);

    final result = await _repository.getMessages(conversationId);
    result.when(
      success: (messages) {
        _messages = messages;
        _messagesStatus = LoadStatus.success;
      },
      failure: (error) {
        _messagesError = error;
        _messagesStatus = LoadStatus.error;
      },
    );
    notifyListeners();

    if (result.isSuccess) {
      unawaited(_repository.markRead(conversationId));
      _emitRead(conversationId);
    }
  }

  void closeThread() {
    final id = _currentConversationId;
    if (id != null) _leaveRoom(id);
    _currentConversationId = null;
    _messages = const [];
    _messagesStatus = LoadStatus.initial;
    _typingUserNames.clear();
  }

  void _joinRoom(String conversationId) {
    if (!_realtimeService.isConnected) return;
    try {
      _realtimeService.socket.emitWithAck('group:join', conversationId, ack: (_) {});
      _realtimeService.socket.on('group:new-message', _onNewMessage);
      _realtimeService.socket.on('group:typing', _onTyping);
    } catch (_) {
      // Live updates degrade silently — see class doc comment.
    }
  }

  void _leaveRoom(String conversationId) {
    if (!_realtimeService.isConnected) return;
    try {
      _realtimeService.socket.emit('group:leave', conversationId);
      _realtimeService.socket.off('group:new-message', _onNewMessage);
      _realtimeService.socket.off('group:typing', _onTyping);
    } catch (_) {
      // Nothing to clean up if the socket is already gone.
    }
  }

  void _emitRead(String conversationId) {
    if (!_realtimeService.isConnected) return;
    try {
      _realtimeService.socket.emit('group:read', {'conversationId': conversationId});
    } catch (_) {}
  }

  void _onNewMessage(dynamic payload) {
    if (payload is! Map) return;
    final message = GroupMessage.fromJson(Map<String, dynamic>.from(payload));
    if (message.conversationId != _currentConversationId) return;
    if (_messages.any((m) => m.id == message.id)) return;
    _messages = [..._messages, message];
    notifyListeners();
  }

  void _onTyping(dynamic payload) {
    if (payload is! Map) return;
    final name = payload['name'] as String?;
    final isTyping = payload['isTyping'] as bool? ?? false;
    if (name == null) return;
    if (isTyping) {
      _typingUserNames.add(name);
    } else {
      _typingUserNames.remove(name);
    }
    notifyListeners();
  }

  void setTyping(bool isTyping) {
    final id = _currentConversationId;
    if (id == null || !_realtimeService.isConnected) return;
    try {
      _realtimeService.socket.emit('group:typing', {'conversationId': id, 'isTyping': isTyping});
    } catch (_) {}
  }

  Future<bool> sendMessage({String? text, Uint8List? attachmentBytes, String? attachmentFilename}) async {
    final id = _currentConversationId;
    if (id == null) return false;

    _isSending = true;
    _sendError = null;
    notifyListeners();

    final result = await _repository.sendMessage(
      id,
      text: text,
      attachmentBytes: attachmentBytes,
      attachmentFilename: attachmentFilename,
    );
    final succeeded = result.isSuccess;
    result.when(
      success: (message) {
        if (!_messages.any((m) => m.id == message.id)) _messages = [..._messages, message];
      },
      failure: (error) => _sendError = error,
    );

    _isSending = false;
    notifyListeners();
    return succeeded;
  }
}
