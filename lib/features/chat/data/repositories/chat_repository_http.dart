import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_client.dart';
import '../../../admin_management/data/models/student.dart';
import '../models/eligible_target.dart';
import '../models/group_conversation.dart';
import '../models/group_message.dart';
import 'chat_repository.dart';

class ChatRepositoryHttp implements ChatRepository {
  final ApiClient _apiClient;

  ChatRepositoryHttp(this._apiClient);

  @override
  Future<Result<List<EligibleTarget>>> getEligibleTargets() async {
    try {
      final targets = await _apiClient.get<List<EligibleTarget>>(
        '/group-chats/eligible-targets',
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => EligibleTarget.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(targets);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<List<Student>>> previewRoster({required String classId, String? sectionId}) async {
    try {
      final students = await _apiClient.get<List<Student>>(
        '/group-chats/preview-roster',
        queryParameters: {'classId': classId, if (sectionId != null) 'sectionId': sectionId},
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => Student.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(students);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<GroupConversation>> createGroup({
    required String classId,
    String? sectionId,
    String? name,
    List<String>? extraMemberIds,
  }) async {
    try {
      final group = await _apiClient.post<GroupConversation>(
        '/group-chats',
        data: {
          'classId': classId,
          if (sectionId != null) 'sectionId': sectionId,
          if (name != null) 'name': name,
          if (extraMemberIds != null) 'extraMemberIds': extraMemberIds,
        },
        parse: (data) => GroupConversation.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(group);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<List<GroupConversation>>> getMyGroups() async {
    try {
      final groups = await _apiClient.get<List<GroupConversation>>(
        '/group-chats',
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => GroupConversation.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(groups);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<(GroupConversation, List<Student>)>> getGroupById(String id) async {
    try {
      final result = await _apiClient.get<(GroupConversation, List<Student>)>(
        '/group-chats/$id',
        parse: (data) {
          final map = (data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
          final group = GroupConversation.fromJson(map);
          final members = (map['members'] as List? ?? const [])
              .map((json) => Student.fromJson(json as Map<String, dynamic>))
              .toList();
          return (group, members);
        },
      );
      return Result.success(result);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<GroupConversation>> updateMembers(
    String id, {
    List<String>? addStudentIds,
    List<String>? removeStudentIds,
  }) async {
    try {
      final group = await _apiClient.patch<GroupConversation>(
        '/group-chats/$id/members',
        data: {
          if (addStudentIds != null) 'addStudentIds': addStudentIds,
          if (removeStudentIds != null) 'removeStudentIds': removeStudentIds,
        },
        parse: (data) => GroupConversation.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(group);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<void>> archiveGroup(String id) async {
    try {
      await _apiClient.patch<void>('/group-chats/$id/archive');
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<void>> deleteGroup(String id) async {
    try {
      await _apiClient.delete<void>('/group-chats/$id');
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<List<GroupMessage>>> getMessages(String conversationId, {String? before, int limit = 30}) async {
    try {
      final messages = await _apiClient.get<List<GroupMessage>>(
        '/group-chats/$conversationId/messages',
        queryParameters: {if (before != null) 'before': before, 'limit': limit},
        parse: (data) => ((data as Map<String, dynamic>)['data'] as List)
            .map((json) => GroupMessage.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
      return Result.success(messages);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<GroupMessage>> sendMessage(
    String conversationId, {
    String? text,
    Uint8List? attachmentBytes,
    String? attachmentFilename,
  }) async {
    try {
      final message = await _apiClient.post<GroupMessage>(
        '/group-chats/$conversationId/messages',
        data: FormData.fromMap({
          'text': text ?? '',
          if (attachmentBytes != null) 'media': MultipartFile.fromBytes(attachmentBytes, filename: attachmentFilename),
        }),
        parse: (data) => GroupMessage.fromJson((data as Map<String, dynamic>)['data'] as Map<String, dynamic>),
      );
      return Result.success(message);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<void>> markRead(String conversationId) async {
    try {
      await _apiClient.patch<void>('/group-chats/$conversationId/messages/read');
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
