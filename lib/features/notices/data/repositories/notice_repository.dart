import '../../../../core/error/result.dart';
import '../models/notice.dart';

/// `/api/notices` — confirmed directly against `noticeRoutes.js`/
/// `noticeController.js`. Two distinct read paths, not one shared endpoint
/// like Assignments: `GET /` (Admin-only, whole school) vs. `GET /my`
/// (Student/Teacher/Parent, audience-filtered to their own role + "all",
/// excludes expired) — kept as two methods rather than forcing one call
/// that would behave differently per role silently.
abstract class NoticeRepository {
  Future<Result<List<Notice>>> getNoticesAsAdmin({String? audience});

  Future<Result<List<Notice>>> getMyNotices();

  Future<Result<Notice>> getNoticeById(String id);

  Future<Result<Notice>> createNotice({
    required String title,
    required String description,
    String? audience,
    bool? isImportant,
    String? expiryDate,
  });

  Future<Result<Notice>> updateNotice({
    required String id,
    String? title,
    String? description,
    String? audience,
    bool? isImportant,
    String? expiryDate,
  });

  Future<Result<void>> deleteNotice(String id);
}
