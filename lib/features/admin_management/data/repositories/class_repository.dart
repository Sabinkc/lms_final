import '../../../../core/error/result.dart';
import '../models/academic_class.dart';

/// `/api/classes`, `protectAdmin`-guarded throughout (docs/api_spec.md §3;
/// exact shapes confirmed directly per docs/production_roadmap.md Phase B
/// step 1). Presentation code depends only on this interface, matching the
/// pattern set by `AuthRepository` (docs/architecture.md §5).
abstract class ClassRepository {
  Future<Result<List<AcademicClass>>> getClasses();

  Future<Result<AcademicClass>> createClass({required String name, String? description});

  Future<Result<AcademicClass>> updateClass({
    required String id,
    String? name,
    String? description,
    String? status,
  });

  /// Fails (409, surfaced via the exception's `.message`) if the class
  /// still has sections under it — confirmed server-side guard
  /// (`Classcontroller.js`'s `deleteClass`), not re-implemented client-side.
  Future<Result<void>> deleteClass(String id);
}
