import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../data/models/teacher.dart';
import '../../data/repositories/teacher_repository.dart';
import 'academic_structure_provider.dart' show LoadStatus;

class TeacherProvider extends ChangeNotifier {
  final TeacherRepository _teacherRepository;

  TeacherProvider(this._teacherRepository);

  LoadStatus _status = LoadStatus.initial;
  List<Teacher> _teachers = const [];
  AppException? _error;
  bool _isSaving = false;
  AppException? _actionError;

  LoadStatus get status => _status;
  List<Teacher> get teachers => _teachers;
  AppException? get error => _error;
  bool get isSaving => _isSaving;
  AppException? get actionError => _actionError;

  Future<void> loadTeachers({bool silent = false}) async {
    // A silent reload (pull-to-refresh) keeps the current data on screen.
    if (!silent || _status != LoadStatus.success) _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _teacherRepository.getTeachers();
    result.when(
      success: (teachers) {
        _teachers = teachers;
        _status = LoadStatus.success;
      },
      failure: (error) {
        _error = error;
        _status = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<bool> createTeacher({
    required String fullName,
    required String email,
    required String employeeId,
    required String department,
    String? password,
    String? designation,
    String? qualification,
    List<String>? subjects,
    int? experience,
    double? salary,
    String? address,
    String? phone,
    String? bankAccountNumber,
  }) async {
    _isSaving = true;
    _actionError = null;
    notifyListeners();

    final result = await _teacherRepository.createTeacher(
      fullName: fullName,
      email: email,
      employeeId: employeeId,
      department: department,
      password: password,
      designation: designation,
      qualification: qualification,
      subjects: subjects,
      experience: experience,
      salary: salary,
      address: address,
      phone: phone,
      bankAccountNumber: bankAccountNumber,
    );
    final succeeded = result.isSuccess;
    result.when(success: (created) => _teachers = [..._teachers, created], failure: (error) => _actionError = error);

    _isSaving = false;
    notifyListeners();
    return succeeded;
  }

  Future<bool> updateTeacher({
    required String id,
    String? employeeId,
    String? department,
    String? designation,
    String? qualification,
    List<String>? subjects,
    int? experience,
    double? salary,
    String? address,
    String? phone,
    String? bankAccountNumber,
    String? status,
  }) async {
    _isSaving = true;
    _actionError = null;
    notifyListeners();

    final result = await _teacherRepository.updateTeacher(
      id: id,
      employeeId: employeeId,
      department: department,
      designation: designation,
      qualification: qualification,
      subjects: subjects,
      experience: experience,
      salary: salary,
      address: address,
      phone: phone,
      bankAccountNumber: bankAccountNumber,
      status: status,
    );
    final succeeded = result.isSuccess;
    result.when(
      success: (updated) => _teachers = [
        for (final t in _teachers)
          if (t.id == updated.id) updated else t,
      ],
      failure: (error) => _actionError = error,
    );

    _isSaving = false;
    notifyListeners();
    return succeeded;
  }

  Future<bool> deleteTeacher(String id) async {
    _actionError = null;

    final result = await _teacherRepository.deleteTeacher(id);
    final succeeded = result.isSuccess;
    result.when(
      success: (_) => _teachers = _teachers.where((t) => t.id != id).toList(),
      failure: (error) => _actionError = error,
    );

    notifyListeners();
    return succeeded;
  }
}
