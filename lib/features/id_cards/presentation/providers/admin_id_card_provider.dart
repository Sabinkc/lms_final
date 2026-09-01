import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../admin_management/data/models/student.dart';
import '../../../admin_management/data/repositories/student_repository.dart';
import '../../data/repositories/id_card_repository.dart';

/// Admin: Generate ID Card (`docs/production_roadmap.md` Phase L6,
/// `implementation_backlog.md` E21-F1) — embeds [StudentRepository] for the
/// student picker, same pattern [FeeProvider] uses for its own student
/// `Autocomplete`.
class AdminIdCardProvider extends ChangeNotifier {
  final IdCardRepository _repository;
  final StudentRepository _studentRepository;

  AdminIdCardProvider(this._repository, this._studentRepository);

  List<Student> _studentOptions = const [];
  List<Student> get studentOptions => _studentOptions;

  bool _isGenerating = false;
  AppException? _generateError;

  bool get isGenerating => _isGenerating;
  AppException? get generateError => _generateError;

  Future<void> loadStudentOptions() async {
    final result = await _studentRepository.getStudents();
    result.when(
      success: (students) => _studentOptions = students,
      failure: (_) {},
    );
    notifyListeners();
  }

  Future<Uint8List?> generateStudentIdCard(String studentId) async {
    _isGenerating = true;
    _generateError = null;
    notifyListeners();

    final result = await _repository.generateStudentIdCard(studentId);
    _isGenerating = false;
    Uint8List? bytes;
    result.when(
      success: (data) => bytes = data,
      failure: (error) => _generateError = error,
    );
    notifyListeners();
    return bytes;
  }
}
