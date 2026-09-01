import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/repositories/id_card_repository.dart';

/// Student: Download Own ID Card (`docs/production_roadmap.md` Phase L6,
/// `implementation_backlog.md` E21-F2).
class StudentIdCardProvider extends ChangeNotifier {
  final IdCardRepository _repository;

  StudentIdCardProvider(this._repository);

  LoadStatus _status = LoadStatus.initial;
  AppException? _error;

  LoadStatus get status => _status;
  AppException? get error => _error;

  Future<Uint8List?> downloadMyIdCard() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _repository.generateMyIdCard();
    Uint8List? bytes;
    result.when(
      success: (data) {
        bytes = data;
        _status = LoadStatus.success;
      },
      failure: (error) {
        _error = error;
        _status = LoadStatus.error;
      },
    );
    notifyListeners();
    return bytes;
  }
}
