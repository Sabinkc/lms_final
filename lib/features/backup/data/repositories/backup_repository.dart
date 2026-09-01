import 'dart:typed_data';

import '../../../../core/error/result.dart';

/// Admin: download a zip of the school's own data
/// (`docs/production_roadmap.md` Phase L1, `implementation_backlog.md` E20).
/// Backend confirms `GET /api/backup/school` is `protectAdmin`-only,
/// school-scoped server-side — there is no restore or scheduling here, only
/// the one download the real web app exposes (`Admin Settings` → "Run
/// Backup").
abstract class BackupRepository {
  Future<Result<Uint8List>> downloadSchoolBackup();
}
