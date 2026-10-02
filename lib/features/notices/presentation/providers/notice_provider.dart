import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/notice.dart';
import '../../data/repositories/notice_repository.dart';

/// One provider for Notices, mirroring `AssignmentProvider`'s shape but
/// with two distinct list-loading entry points (`loadNoticesAsAdmin`/
/// `loadMyNotices`) instead of one shared call — `NoticeRepository`'s doc
/// comment explains why the backend itself has two separate read routes
/// here, unlike Assignments' single role-scoped endpoint.
class NoticeProvider extends ChangeNotifier {
  final NoticeRepository _repository;

  NoticeProvider(this._repository);

  LoadStatus _status = LoadStatus.initial;
  List<Notice> _notices = const [];
  AppException? _error;

  LoadStatus _detailStatus = LoadStatus.initial;
  Notice? _currentNotice;
  AppException? _detailError;

  bool _isSaving = false;
  AppException? _actionError;

  LoadStatus get status => _status;
  List<Notice> get notices => _notices;
  AppException? get error => _error;

  LoadStatus get detailStatus => _detailStatus;
  Notice? get currentNotice => _currentNotice;
  AppException? get detailError => _detailError;

  bool get isSaving => _isSaving;
  AppException? get actionError => _actionError;

  Future<void> loadNoticesAsAdmin({bool silent = false}) async {
    // A silent reload (pull-to-refresh) keeps the current data on screen.
    if (!silent || _status != LoadStatus.success) _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _repository.getNoticesAsAdmin();
    result.when(
      success: (notices) {
        _notices = notices;
        _status = LoadStatus.success;
      },
      failure: (error) {
        _error = error;
        _status = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<void> loadMyNotices({bool silent = false}) async {
    // A silent reload (pull-to-refresh) keeps the current data on screen.
    if (!silent || _status != LoadStatus.success) _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _repository.getMyNotices();
    result.when(
      success: (notices) {
        _notices = notices;
        _status = LoadStatus.success;
      },
      failure: (error) {
        _error = error;
        _status = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<void> loadNoticeDetail(String id, {bool silent = false}) async {
    // A silent reload (pull-to-refresh) keeps the current data on screen.
    if (!silent || _detailStatus != LoadStatus.success) _detailStatus = LoadStatus.loading;
    _detailError = null;
    notifyListeners();

    final result = await _repository.getNoticeById(id);
    result.when(
      success: (notice) {
        _currentNotice = notice;
        _detailStatus = LoadStatus.success;
      },
      failure: (error) {
        _detailError = error;
        _detailStatus = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<bool> createNotice({
    required String title,
    required String description,
    String? audience,
    bool? isImportant,
    String? expiryDate,
  }) async {
    _isSaving = true;
    _actionError = null;
    notifyListeners();

    final result = await _repository.createNotice(
      title: title,
      description: description,
      audience: audience,
      isImportant: isImportant,
      expiryDate: expiryDate,
    );
    final succeeded = result.isSuccess;
    result.when(success: (created) => _notices = [created, ..._notices], failure: (error) => _actionError = error);

    _isSaving = false;
    notifyListeners();
    return succeeded;
  }

  Future<bool> updateNotice({
    required String id,
    String? title,
    String? description,
    String? audience,
    bool? isImportant,
    String? expiryDate,
  }) async {
    _isSaving = true;
    _actionError = null;
    notifyListeners();

    final result = await _repository.updateNotice(
      id: id,
      title: title,
      description: description,
      audience: audience,
      isImportant: isImportant,
      expiryDate: expiryDate,
    );
    final succeeded = result.isSuccess;
    result.when(
      success: (updated) {
        _notices = [
          for (final n in _notices)
            if (n.id == updated.id) updated else n,
        ];
        if (_currentNotice?.id == updated.id) _currentNotice = updated;
      },
      failure: (error) => _actionError = error,
    );

    _isSaving = false;
    notifyListeners();
    return succeeded;
  }

  Future<bool> deleteNotice(String id) async {
    _actionError = null;

    final result = await _repository.deleteNotice(id);
    final succeeded = result.isSuccess;
    result.when(
      success: (_) => _notices = _notices.where((n) => n.id != id).toList(),
      failure: (error) => _actionError = error,
    );

    notifyListeners();
    return succeeded;
  }
}
