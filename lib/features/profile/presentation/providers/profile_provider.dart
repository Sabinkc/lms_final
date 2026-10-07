import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../../auth/data/models/app_role.dart';
import '../../data/models/my_profile.dart';
import '../../data/models/school_info.dart';
import '../../data/repositories/profile_repository.dart';

/// My Profile + (Admin) School Profile state. Each write returns `null` on
/// success or the error to show, and reloads from the server afterwards so
/// the screen always shows what the backend actually saved.
class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _repository;

  ProfileProvider(this._repository);

  LoadStatus _status = LoadStatus.initial;
  MyProfile? _profile;
  AppException? _error;

  LoadStatus _schoolStatus = LoadStatus.initial;
  SchoolInfo? _school;
  AppException? _schoolError;

  LoadStatus get status => _status;
  MyProfile? get profile => _profile;
  AppException? get error => _error;

  LoadStatus get schoolStatus => _schoolStatus;
  SchoolInfo? get school => _school;
  AppException? get schoolError => _schoolError;

  /// [refresh] keeps the current profile on screen (pull-to-refresh);
  /// otherwise it's cleared first, so a previous login's profile is never
  /// shown while the new one loads.
  Future<void> load(AppRole role, {bool refresh = false}) async {
    if (!refresh) _profile = null;
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    final result = await _repository.getMyProfile(role);
    result.when(
      success: (data) {
        _profile = data;
        _status = LoadStatus.success;
      },
      failure: (e) {
        _error = e;
        _status = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<AppException?> updateDetails({
    required String fullName,
    String? email,
    String? phone,
    String? address,
    DateTime? dob,
    String? occupation,
  }) async {
    final current = _profile;
    if (current == null) return null;
    final result = await _repository.updateMyProfile(
      current.role,
      fullName: fullName,
      email: email,
      phone: phone,
      address: address,
      dob: dob,
      occupation: occupation,
    );
    if (result.isFailure) return result.when(success: (_) => null, failure: (e) => e);
    await _reloadQuietly(current.role);
    return null;
  }

  Future<AppException?> changePassword({required String currentPassword, required String newPassword}) async {
    final current = _profile;
    if (current == null) return null;
    final result = await _repository.changePassword(
      current.role,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    return result.when(success: (_) => null, failure: (e) => e);
  }

  Future<AppException?> uploadPhoto(Uint8List bytes, String filename) async {
    final current = _profile;
    if (current == null) return null;
    final result = await _repository.uploadMyPhoto(
      current.role,
      profileId: current.id,
      bytes: bytes,
      filename: filename,
    );
    if (result.isFailure) return result.when(success: (_) => null, failure: (e) => e);
    await _reloadQuietly(current.role);
    return null;
  }

  Future<void> loadSchool({bool refresh = false}) async {
    if (!refresh) _school = null;
    _schoolStatus = LoadStatus.loading;
    _schoolError = null;
    notifyListeners();
    final result = await _repository.getMySchool();
    result.when(
      success: (data) {
        _school = data;
        _schoolStatus = LoadStatus.success;
      },
      failure: (e) {
        _schoolError = e;
        _schoolStatus = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<AppException?> uploadSchoolLogo(Uint8List bytes, String filename) async {
    final result = await _repository.uploadSchoolLogo(bytes: bytes, filename: filename);
    return result.when(
      success: (data) {
        _school = data;
        notifyListeners();
        return null;
      },
      failure: (e) => e,
    );
  }

  /// Refresh after a write without flashing the full-screen loader.
  Future<void> _reloadQuietly(AppRole role) async {
    final result = await _repository.getMyProfile(role);
    result.when(success: (data) => _profile = data, failure: (_) {});
    notifyListeners();
  }
}
