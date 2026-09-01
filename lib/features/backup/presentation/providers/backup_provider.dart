import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/repositories/backup_repository.dart';

class BackupProvider extends ChangeNotifier {
  final BackupRepository _repository;

  BackupProvider(this._repository);

  LoadStatus _status = LoadStatus.initial;
  AppException? _error;

  LoadStatus get status => _status;
  AppException? get error => _error;

  Future<Uint8List?> downloadSchoolBackup() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _repository.downloadSchoolBackup();
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
