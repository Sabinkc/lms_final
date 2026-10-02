import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/student_followup.dart';
import '../../data/repositories/student_followup_repository.dart';

/// Admin: Manage Student Follow-ups (`docs/production_roadmap.md` Phase L5,
/// `implementation_backlog.md` E18) — same CRUD + status-filter + export
/// shape [FeeProvider]/[DepartmentProvider] already established.
class StudentFollowupProvider extends ChangeNotifier {
  final StudentFollowupRepository _repository;

  StudentFollowupProvider(this._repository);

  LoadStatus _status = LoadStatus.initial;
  List<StudentFollowup> _followups = const [];
  AppException? _error;

  bool _isSaving = false;
  AppException? _actionError;

  bool _isDownloading = false;
  AppException? _downloadError;

  LoadStatus get status => _status;
  List<StudentFollowup> get followups => _followups;
  AppException? get error => _error;

  bool get isSaving => _isSaving;
  AppException? get actionError => _actionError;

  bool get isDownloading => _isDownloading;
  AppException? get downloadError => _downloadError;

  Future<void> loadFollowups({String? status, String? search, bool silent = false}) async {
    // A silent reload (pull-to-refresh) keeps the current data on screen.
    if (!silent || _status != LoadStatus.success) _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _repository.getFollowups(status: status, search: search, limit: 100);
    result.when(
      success: (followups) {
        _followups = followups;
        _status = LoadStatus.success;
      },
      failure: (error) {
        _error = error;
        _status = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<bool> createFollowup({
    required String studentName,
    required String faculty,
    required String email,
    required String contactNumber,
    required String address,
    required String followUpNote,
    String? visitDate,
    String? status,
  }) async {
    _isSaving = true;
    _actionError = null;
    notifyListeners();

    final result = await _repository.createFollowup(
      studentName: studentName,
      faculty: faculty,
      email: email,
      contactNumber: contactNumber,
      address: address,
      followUpNote: followUpNote,
      visitDate: visitDate,
      status: status,
    );
    final succeeded = result.isSuccess;
    result.when(success: (created) => _followups = [created, ..._followups], failure: (error) => _actionError = error);

    _isSaving = false;
    notifyListeners();
    return succeeded;
  }

  Future<bool> updateFollowup({
    required String id,
    String? studentName,
    String? faculty,
    String? email,
    String? contactNumber,
    String? address,
    String? followUpNote,
    String? visitDate,
    String? status,
  }) async {
    _isSaving = true;
    _actionError = null;
    notifyListeners();

    final result = await _repository.updateFollowup(
      id: id,
      studentName: studentName,
      faculty: faculty,
      email: email,
      contactNumber: contactNumber,
      address: address,
      followUpNote: followUpNote,
      visitDate: visitDate,
      status: status,
    );
    final succeeded = result.isSuccess;
    result.when(
      success: (updated) => _followups = [
        for (final f in _followups)
          if (f.id == updated.id) updated else f,
      ],
      failure: (error) => _actionError = error,
    );

    _isSaving = false;
    notifyListeners();
    return succeeded;
  }

  Future<bool> deleteFollowup(String id) async {
    _actionError = null;

    final result = await _repository.deleteFollowup(id);
    final succeeded = result.isSuccess;
    result.when(
      success: (_) => _followups = _followups.where((f) => f.id != id).toList(),
      failure: (error) => _actionError = error,
    );

    notifyListeners();
    return succeeded;
  }

  Future<Uint8List?> exportFollowups({String? status, String? search}) async {
    _isDownloading = true;
    _downloadError = null;
    notifyListeners();

    final result = await _repository.exportFollowups(status: status, search: search);
    _isDownloading = false;
    Uint8List? bytes;
    result.when(success: (data) => bytes = data, failure: (error) => _downloadError = error);
    notifyListeners();
    return bytes;
  }
}
