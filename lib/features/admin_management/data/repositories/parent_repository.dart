import '../../../../core/error/result.dart';
import '../models/parent.dart';

/// `/api/parents`, `protectAdmin`-guarded throughout (confirmed directly
/// against `parentRoutes.js`/`parentController.js`).
abstract class ParentRepository {
  Future<Result<List<Parent>>> getParents();

  Future<Result<Parent>> createParent({
    required String fullName,
    required String email,
    String? password,
    String? occupation,
    String? address,
    String? phone,
    List<String>? studentIds,
  });

  /// [studentIds], when provided, **replaces** the parent's whole linked-child
  /// set — `updateParent` diffs it against the current list server-side to
  /// figure out which `Student.parentId`s to set/unset (`parentController.js`),
  /// it isn't an incremental add/remove call.
  Future<Result<Parent>> updateParent({
    required String id,
    String? occupation,
    String? address,
    String? phone,
    String? status,
    List<String>? studentIds,
  });

  /// Also deletes the linked `User` account and unlinks every child student
  /// server-side (`deleteParent`) — not something the client needs to do
  /// separately.
  Future<Result<void>> deleteParent(String id);
}
