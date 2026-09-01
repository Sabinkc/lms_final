import '../../../../core/error/result.dart';
import '../models/department.dart';

/// `/api/admin/departments`, `protectAdmin`-guarded throughout (confirmed by
/// reading `Departmentroutes.js` directly). Presentation code depends only
/// on this interface, matching `ClassRepository`'s pattern.
abstract class DepartmentRepository {
  Future<Result<List<Department>>> getDepartments();

  Future<Result<Department>> createDepartment({
    required String name,
    String? description,
    String? headOfDepartmentId,
    List<String>? classes,
  });

  Future<Result<Department>> updateDepartment({
    required String id,
    String? name,
    String? description,
    String? headOfDepartmentId,
    List<String>? classes,
    String? status,
  });

  Future<Result<void>> deleteDepartment(String id);
}
