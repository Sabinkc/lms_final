import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../data/models/academic_class.dart';
import '../../data/models/class_section.dart';
import '../../data/repositories/class_repository.dart';
import '../../data/repositories/section_repository.dart';

enum LoadStatus { initial, loading, success, error }

/// One `ChangeNotifier` covering both Classes and Sections — kept together
/// (not two separate providers) because the UI is one cohesive drill-down
/// flow (Classes list -> a class's Sections list, docs/screens.md "Manage
/// Classes / Sections / Subjects") and the backend itself nests section
/// creation under a class (`/api/classes/:classId/sections`).
class AcademicStructureProvider extends ChangeNotifier {
  final ClassRepository _classRepository;
  final SectionRepository _sectionRepository;

  AcademicStructureProvider(this._classRepository, this._sectionRepository);

  LoadStatus _classesStatus = LoadStatus.initial;
  List<AcademicClass> _classes = const [];
  AppException? _classesError;
  bool _isSavingClass = false;
  AppException? _classActionError;

  String? _selectedClassId;
  LoadStatus _sectionsStatus = LoadStatus.initial;
  List<ClassSection> _sections = const [];
  AppException? _sectionsError;
  bool _isSavingSection = false;
  AppException? _sectionActionError;

  LoadStatus get classesStatus => _classesStatus;
  List<AcademicClass> get classes => _classes;
  AppException? get classesError => _classesError;
  bool get isSavingClass => _isSavingClass;
  AppException? get classActionError => _classActionError;

  String? get selectedClassId => _selectedClassId;
  LoadStatus get sectionsStatus => _sectionsStatus;
  List<ClassSection> get sections => _sections;
  AppException? get sectionsError => _sectionsError;
  bool get isSavingSection => _isSavingSection;
  AppException? get sectionActionError => _sectionActionError;

  Future<void> loadClasses({bool silent = false}) async {
    // A silent reload (pull-to-refresh) keeps the current data on screen.
    if (!silent || _classesStatus != LoadStatus.success) _classesStatus = LoadStatus.loading;
    _classesError = null;
    notifyListeners();

    final result = await _classRepository.getClasses();
    result.when(
      success: (classes) {
        _classes = classes;
        _classesStatus = LoadStatus.success;
      },
      failure: (error) {
        _classesError = error;
        _classesStatus = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<bool> createClass({required String name, String? description}) async {
    _isSavingClass = true;
    _classActionError = null;
    notifyListeners();

    final result = await _classRepository.createClass(name: name, description: description);
    final succeeded = result.isSuccess;
    result.when(
      // A just-created class has no sections yet.
      success: (created) => _classes = [..._classes, created.withSectionCount(0)],
      failure: (error) => _classActionError = error,
    );

    _isSavingClass = false;
    notifyListeners();
    return succeeded;
  }

  Future<bool> updateClass({required String id, String? name, String? description, String? status}) async {
    _isSavingClass = true;
    _classActionError = null;
    notifyListeners();

    final result = await _classRepository.updateClass(id: id, name: name, description: description, status: status);
    final succeeded = result.isSuccess;
    result.when(
      // The update response doesn't embed `sections` — keep the known count.
      success: (updated) => _classes = [
        for (final c in _classes)
          if (c.id == updated.id) updated.withSectionCount(updated.sectionCount ?? c.sectionCount) else c,
      ],
      failure: (error) => _classActionError = error,
    );

    _isSavingClass = false;
    notifyListeners();
    return succeeded;
  }

  Future<bool> deleteClass(String id) async {
    _classActionError = null;

    final result = await _classRepository.deleteClass(id);
    final succeeded = result.isSuccess;
    result.when(
      success: (_) => _classes = _classes.where((c) => c.id != id).toList(),
      failure: (error) => _classActionError = error,
    );

    notifyListeners();
    return succeeded;
  }

  /// Keeps the Classes list's per-class section count in step with the
  /// Sections screen, so going back doesn't show a stale number.
  void _syncSectionCount() {
    final classId = _selectedClassId;
    if (classId == null) return;
    _classes = [for (final c in _classes) c.id == classId ? c.withSectionCount(_sections.length) : c];
  }

  Future<void> loadSections(String classId, {bool silent = false}) async {
    _selectedClassId = classId;
    // A silent reload (pull-to-refresh) keeps the current data on screen.
    if (!silent || _sectionsStatus != LoadStatus.success) _sectionsStatus = LoadStatus.loading;
    _sectionsError = null;
    notifyListeners();

    final result = await _sectionRepository.getSections(classId);
    result.when(
      success: (sections) {
        _sections = sections;
        _sectionsStatus = LoadStatus.success;
        _syncSectionCount();
      },
      failure: (error) {
        _sectionsError = error;
        _sectionsStatus = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<bool> createSection({required String classId, required String name}) async {
    _isSavingSection = true;
    _sectionActionError = null;
    notifyListeners();

    final result = await _sectionRepository.createSection(classId: classId, name: name);
    final succeeded = result.isSuccess;
    result.when(
      success: (created) {
        _sections = [..._sections, created];
        _syncSectionCount();
      },
      failure: (error) => _sectionActionError = error,
    );

    _isSavingSection = false;
    notifyListeners();
    return succeeded;
  }

  Future<bool> updateSection({required String id, String? name, String? status}) async {
    _isSavingSection = true;
    _sectionActionError = null;
    notifyListeners();

    final result = await _sectionRepository.updateSection(id: id, name: name, status: status);
    final succeeded = result.isSuccess;
    result.when(
      success: (updated) => _sections = [
        for (final s in _sections)
          if (s.id == updated.id) updated else s,
      ],
      failure: (error) => _sectionActionError = error,
    );

    _isSavingSection = false;
    notifyListeners();
    return succeeded;
  }

  Future<bool> deleteSection(String id) async {
    _sectionActionError = null;

    final result = await _sectionRepository.deleteSection(id);
    final succeeded = result.isSuccess;
    result.when(
      success: (_) {
        _sections = _sections.where((s) => s.id != id).toList();
        _syncSectionCount();
      },
      failure: (error) => _sectionActionError = error,
    );

    notifyListeners();
    return succeeded;
  }
}
