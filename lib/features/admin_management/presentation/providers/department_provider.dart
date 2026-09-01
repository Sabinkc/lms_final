import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../data/models/academic_class.dart';
import '../../data/models/department.dart';
import '../../data/models/teacher.dart';
import '../../data/repositories/class_repository.dart';
import '../../data/repositories/department_repository.dart';
import '../../data/repositories/teacher_repository.dart';
import 'academic_structure_provider.dart' show LoadStatus;

/// Admin: Manage Departments (`docs/production_roadmap.md` Phase L2,
/// `implementation_backlog.md` E17) — embeds [TeacherRepository] and
/// [ClassRepository] directly for the head-of-department picker and
/// classes multi-select, same pattern [FeeProvider] uses for its student
/// picker, rather than reading a second provider from the widget tree.
class DepartmentProvider extends ChangeNotifier {
  final DepartmentRepository _departmentRepository;
  final TeacherRepository _teacherRepository;
  final ClassRepository _classRepository;

  DepartmentProvider(this._departmentRepository, this._teacherRepository, this._classRepository);

  LoadStatus _status = LoadStatus.initial;
  List<Department> _departments = const [];
  AppException? _error;

  bool _isSaving = false;
  AppException? _actionError;

  List<Teacher> _teacherOptions = const [];
  List<AcademicClass> _classOptions = const [];

  LoadStatus get status => _status;
  List<Department> get departments => _departments;
  AppException? get error => _error;

  bool get isSaving => _isSaving;
  AppException? get actionError => _actionError;

  List<Teacher> get teacherOptions => _teacherOptions;
  List<AcademicClass> get classOptions => _classOptions;

  Future<void> loadDepartments() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _departmentRepository.getDepartments();
    result.when(
      success: (departments) {
        _departments = departments;
        _status = LoadStatus.success;
      },
      failure: (error) {
        _error = error;
        _status = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<void> loadOptions() async {
    final teacherResult = await _teacherRepository.getTeachers();
    teacherResult.when(success: (teachers) => _teacherOptions = teachers, failure: (_) {});

    final classResult = await _classRepository.getClasses();
    classResult.when(success: (classes) => _classOptions = classes, failure: (_) {});

    notifyListeners();
  }

  Future<bool> createDepartment({
    required String name,
    String? description,
    String? headOfDepartmentId,
    List<String>? classes,
  }) async {
    _isSaving = true;
    _actionError = null;
    notifyListeners();

    final result = await _departmentRepository.createDepartment(
      name: name,
      description: description,
      headOfDepartmentId: headOfDepartmentId,
      classes: classes,
    );
    final succeeded = result.isSuccess;
    result.when(
      success: (created) => _departments = [..._departments, created],
      failure: (error) => _actionError = error,
    );

    _isSaving = false;
    notifyListeners();
    return succeeded;
  }

  Future<bool> updateDepartment({
    required String id,
    String? name,
    String? description,
    String? headOfDepartmentId,
    List<String>? classes,
    String? status,
  }) async {
    _isSaving = true;
    _actionError = null;
    notifyListeners();

    final result = await _departmentRepository.updateDepartment(
      id: id,
      name: name,
      description: description,
      headOfDepartmentId: headOfDepartmentId,
      classes: classes,
      status: status,
    );
    final succeeded = result.isSuccess;
    result.when(
      success: (updated) => _departments = [for (final d in _departments) if (d.id == updated.id) updated else d],
      failure: (error) => _actionError = error,
    );

    _isSaving = false;
    notifyListeners();
    return succeeded;
  }

  Future<bool> deleteDepartment(String id) async {
    _actionError = null;

    final result = await _departmentRepository.deleteDepartment(id);
    final succeeded = result.isSuccess;
    result.when(
      success: (_) => _departments = _departments.where((d) => d.id != id).toList(),
      failure: (error) => _actionError = error,
    );

    notifyListeners();
    return succeeded;
  }
}
