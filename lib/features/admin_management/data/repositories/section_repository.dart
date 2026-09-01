import '../../../../core/error/result.dart';
import '../models/class_section.dart';

/// Section creation is nested under `/api/classes/:classId/sections`;
/// everything else (get/update/delete) is `/api/sections/:id`, a separate
/// router (docs/production_roadmap.md Phase B step 1 — confirmed directly
/// against `classRoutes.js`/`sectionRoutes.js`, not previously deep-dived in
/// `api_spec.md`).
abstract class SectionRepository {
  Future<Result<List<ClassSection>>> getSections(String classId);

  Future<Result<ClassSection>> createSection({required String classId, required String name});

  Future<Result<ClassSection>> updateSection({
    required String id,
    String? name,
    String? classId,
    String? status,
  });

  /// Confirmed server-side: deleting a section unassigns its students'
  /// `sectionId` rather than deleting them (`Sectioncontroller.js`'s
  /// `deleteSection`) — not re-implemented client-side.
  Future<Result<void>> deleteSection(String id);
}
