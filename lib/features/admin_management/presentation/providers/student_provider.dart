import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../data/models/academic_class.dart';
import '../../data/models/bulk_import_result.dart';
import '../../data/models/class_section.dart';
import '../../data/models/student.dart';
import '../../data/repositories/class_repository.dart';
import '../../data/repositories/section_repository.dart';
import '../../data/repositories/student_repository.dart';
import 'academic_structure_provider.dart' show LoadStatus;

/// Owns Student CRUD plus its own read-only view of Classes/Sections for the
/// add/edit form's pickers — a second, independent read of
/// `ClassRepository`/`SectionRepository` rather than depending on
/// [AcademicStructureProvider]'s instance, matching the "one `ChangeNotifier`
/// per feature, never share state across providers" rule
/// (docs/production_roadmap.md §5 step 4).
class StudentProvider extends ChangeNotifier {
  final StudentRepository _studentRepository;
  final ClassRepository _classRepository;
  final SectionRepository _sectionRepository;

  StudentProvider(this._studentRepository, this._classRepository, this._sectionRepository);

  LoadStatus _status = LoadStatus.initial;
  List<Student> _students = const [];
  AppException? _error;
  String? _classFilter;

  bool _isSaving = false;
  AppException? _actionError;

  List<AcademicClass> _classOptions = const [];
  List<ClassSection> _sectionOptions = const [];

  bool _isImporting = false;
  AppException? _importError;
  BulkImportResult? _lastImportResult;

  bool _isDownloading = false;
  AppException? _downloadError;

  LoadStatus get status => _status;
  List<Student> get students => _students;
  AppException? get error => _error;
  String? get classFilter => _classFilter;

  bool get isSaving => _isSaving;
  AppException? get actionError => _actionError;

  List<AcademicClass> get classOptions => _classOptions;
  List<ClassSection> get sectionOptions => _sectionOptions;

  bool get isImporting => _isImporting;
  AppException? get importError => _importError;
  BulkImportResult? get lastImportResult => _lastImportResult;

  bool get isDownloading => _isDownloading;
  AppException? get downloadError => _downloadError;

  Future<void> loadStudents({String? className, bool silent = false}) async {
    _classFilter = className;
    // A silent reload (pull-to-refresh) keeps the current data on screen.
    if (!silent || _status != LoadStatus.success) _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _studentRepository.getStudents(className: className);
    result.when(
      success: (students) {
        _students = students;
        _status = LoadStatus.success;
      },
      failure: (error) {
        _error = error;
        _status = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<void> loadClassOptions() async {
    final result = await _classRepository.getClasses();
    result.when(success: (classes) => _classOptions = classes, failure: (_) {});
    notifyListeners();
  }

  Future<void> loadSectionOptions(String classId) async {
    final result = await _sectionRepository.getSections(classId);
    result.when(success: (sections) => _sectionOptions = sections, failure: (_) => _sectionOptions = const []);
    notifyListeners();
  }

  Future<bool> createStudent({
    required String className,
    required String section,
    String? fullName,
    String? email,
    String? password,
    String? admissionNumber,
    String? rollNumber,
    String? dob,
    String? address,
    String? phone,
  }) async {
    _isSaving = true;
    _actionError = null;
    notifyListeners();

    final result = await _studentRepository.createStudent(
      className: className,
      section: section,
      fullName: fullName,
      email: email,
      password: password,
      admissionNumber: admissionNumber,
      rollNumber: rollNumber,
      dob: dob,
      address: address,
      phone: phone,
    );
    final succeeded = result.isSuccess;
    result.when(success: (created) => _students = [..._students, created], failure: (error) => _actionError = error);

    _isSaving = false;
    notifyListeners();
    return succeeded;
  }

  Future<bool> updateStudent({
    required String id,
    String? admissionNumber,
    String? rollNumber,
    String? className,
    String? section,
    String? dob,
    String? address,
    String? phone,
    String? status,
  }) async {
    _isSaving = true;
    _actionError = null;
    notifyListeners();

    final result = await _studentRepository.updateStudent(
      id: id,
      admissionNumber: admissionNumber,
      rollNumber: rollNumber,
      className: className,
      section: section,
      dob: dob,
      address: address,
      phone: phone,
      status: status,
    );
    final succeeded = result.isSuccess;
    result.when(
      success: (updated) => _students = [
        for (final s in _students)
          if (s.id == updated.id) updated else s,
      ],
      failure: (error) => _actionError = error,
    );

    _isSaving = false;
    notifyListeners();
    return succeeded;
  }

  Future<bool> deleteStudent(String id) async {
    _actionError = null;

    final result = await _studentRepository.deleteStudent(id);
    final succeeded = result.isSuccess;
    result.when(
      success: (_) => _students = _students.where((s) => s.id != id).toList(),
      failure: (error) => _actionError = error,
    );

    notifyListeners();
    return succeeded;
  }

  Future<bool> bulkImport(Uint8List fileBytes, String filename) async {
    _isImporting = true;
    _importError = null;
    _lastImportResult = null;
    notifyListeners();

    final result = await _studentRepository.bulkImport(fileBytes, filename);
    final succeeded = result.isSuccess;
    result.when(
      success: (importResult) {
        _lastImportResult = importResult;
        // Cheapest correct way to reflect newly-created students: reload
        // against the current filter rather than trying to reconstruct
        // each created row from the summary response (which only carries
        // row/email/id, not the full Student shape `fromJson` expects).
      },
      failure: (error) => _importError = error,
    );

    _isImporting = false;
    notifyListeners();
    if (succeeded) await loadStudents(className: _classFilter);
    return succeeded;
  }

  Future<Uint8List?> downloadImportTemplate() async {
    _isDownloading = true;
    _downloadError = null;
    notifyListeners();

    final result = await _studentRepository.downloadImportTemplate();
    _isDownloading = false;
    Uint8List? bytes;
    result.when(success: (data) => bytes = data, failure: (error) => _downloadError = error);
    notifyListeners();
    return bytes;
  }

  Future<Uint8List?> exportStudents() async {
    _isDownloading = true;
    _downloadError = null;
    notifyListeners();

    final result = await _studentRepository.exportStudents(className: _classFilter);
    _isDownloading = false;
    Uint8List? bytes;
    result.when(success: (data) => bytes = data, failure: (error) => _downloadError = error);
    notifyListeners();
    return bytes;
  }
}
