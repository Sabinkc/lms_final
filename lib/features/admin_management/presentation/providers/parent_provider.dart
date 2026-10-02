import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../data/models/parent.dart';
import '../../data/models/student.dart';
import '../../data/repositories/parent_repository.dart';
import '../../data/repositories/student_repository.dart';
import 'academic_structure_provider.dart' show LoadStatus;

/// Owns Parent CRUD plus its own read-only view of Students for the
/// add/edit form's child-linking picker — a second, independent read of
/// `StudentRepository` rather than depending on [StudentProvider]'s
/// instance, matching the "one `ChangeNotifier` per feature" rule
/// (docs/production_roadmap.md §5 step 4).
class ParentProvider extends ChangeNotifier {
  final ParentRepository _parentRepository;
  final StudentRepository _studentRepository;

  ParentProvider(this._parentRepository, this._studentRepository);

  LoadStatus _status = LoadStatus.initial;
  List<Parent> _parents = const [];
  AppException? _error;

  bool _isSaving = false;
  AppException? _actionError;

  List<Student> _studentOptions = const [];

  LoadStatus get status => _status;
  List<Parent> get parents => _parents;
  AppException? get error => _error;

  bool get isSaving => _isSaving;
  AppException? get actionError => _actionError;

  List<Student> get studentOptions => _studentOptions;

  Future<void> loadParents({bool silent = false}) async {
    // A silent reload (pull-to-refresh) keeps the current data on screen.
    if (!silent || _status != LoadStatus.success) _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _parentRepository.getParents();
    result.when(
      success: (parents) {
        _parents = parents;
        _status = LoadStatus.success;
      },
      failure: (error) {
        _error = error;
        _status = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<void> loadStudentOptions() async {
    final result = await _studentRepository.getStudents();
    result.when(success: (students) => _studentOptions = students, failure: (_) {});
    notifyListeners();
  }

  Future<bool> createParent({
    required String fullName,
    required String email,
    String? password,
    String? occupation,
    String? address,
    String? phone,
    List<String>? studentIds,
  }) async {
    _isSaving = true;
    _actionError = null;
    notifyListeners();

    final result = await _parentRepository.createParent(
      fullName: fullName,
      email: email,
      password: password,
      occupation: occupation,
      address: address,
      phone: phone,
      studentIds: studentIds,
    );
    final succeeded = result.isSuccess;
    result.when(success: (created) => _parents = [..._parents, created], failure: (error) => _actionError = error);

    _isSaving = false;
    notifyListeners();
    return succeeded;
  }

  Future<bool> updateParent({
    required String id,
    String? occupation,
    String? address,
    String? phone,
    String? status,
    List<String>? studentIds,
  }) async {
    _isSaving = true;
    _actionError = null;
    notifyListeners();

    final result = await _parentRepository.updateParent(
      id: id,
      occupation: occupation,
      address: address,
      phone: phone,
      status: status,
      studentIds: studentIds,
    );
    final succeeded = result.isSuccess;
    result.when(
      success: (updated) => _parents = [
        for (final p in _parents)
          if (p.id == updated.id) updated else p,
      ],
      failure: (error) => _actionError = error,
    );

    _isSaving = false;
    notifyListeners();
    return succeeded;
  }

  Future<bool> deleteParent(String id) async {
    _actionError = null;

    final result = await _parentRepository.deleteParent(id);
    final succeeded = result.isSuccess;
    result.when(
      success: (_) => _parents = _parents.where((p) => p.id != id).toList(),
      failure: (error) => _actionError = error,
    );

    notifyListeners();
    return succeeded;
  }
}
