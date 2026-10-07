import 'dart:typed_data';

import '../../../../core/error/result.dart';
import '../../../auth/data/models/app_role.dart';
import '../models/my_profile.dart';
import '../models/school_info.dart';

/// The signed-in user's own profile and (Admin) their school's branding.
abstract class ProfileRepository {
  Future<Result<MyProfile>> getMyProfile(AppRole role);

  /// Only the fields the role's backend endpoint accepts are sent: Admin
  /// name/email/phone; Teacher name/phone/address; Student
  /// name/phone/address/dob; Parent name/phone/address/occupation.
  Future<Result<void>> updateMyProfile(
    AppRole role, {
    required String fullName,
    String? email,
    String? phone,
    String? address,
    DateTime? dob,
    String? occupation,
  });

  Future<Result<void>> changePassword(AppRole role, {required String currentPassword, required String newPassword});

  /// Returns the new photo URL. [profileId] is the Admin document's id
  /// (Admin has no self-upload endpoint, only the by-id one).
  Future<Result<String>> uploadMyPhoto(
    AppRole role, {
    required String profileId,
    required Uint8List bytes,
    required String filename,
  });

  Future<Result<SchoolInfo>> getMySchool();

  Future<Result<SchoolInfo>> uploadSchoolLogo({required Uint8List bytes, required String filename});
}
