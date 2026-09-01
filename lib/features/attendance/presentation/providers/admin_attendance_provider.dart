import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/attendance_correction.dart';
import '../../data/models/attendance_session.dart';
import '../../data/repositories/attendance_correction_repository.dart';
import '../../data/repositories/attendance_repository.dart';

/// Admin-only attendance state: the school-wide session overview (reusing
/// [AttendanceRepository.getSessions] — unscoped for an Admin caller, unlike
/// the Teacher-facing [AttendanceProvider] that also owns that call) plus
/// the correction-request review queue. Kept as its own provider rather
/// than folded into [AttendanceProvider] because its screens, role, and
/// error states are all distinct from the Teacher flow, even though they
/// share one repository.
class AdminAttendanceProvider extends ChangeNotifier {
  final AttendanceRepository _attendanceRepository;
  final AttendanceCorrectionRepository _correctionRepository;

  AdminAttendanceProvider(this._attendanceRepository, this._correctionRepository);

  LoadStatus _overviewStatus = LoadStatus.initial;
  List<AttendanceSessionSummary> _overviewSessions = const [];
  AppException? _overviewError;

  LoadStatus _correctionsStatus = LoadStatus.initial;
  List<AttendanceCorrection> _corrections = const [];
  AppException? _correctionsError;
  final Set<String> _processingCorrectionIds = {};
  AppException? _correctionActionError;

  LoadStatus get overviewStatus => _overviewStatus;
  List<AttendanceSessionSummary> get overviewSessions => _overviewSessions;
  AppException? get overviewError => _overviewError;

  LoadStatus get correctionsStatus => _correctionsStatus;
  List<AttendanceCorrection> get corrections => _corrections;
  AppException? get correctionsError => _correctionsError;
  bool isProcessingCorrection(String id) => _processingCorrectionIds.contains(id);
  AppException? get correctionActionError => _correctionActionError;

  Future<void> loadOverview({required String date, String? className, String? section}) async {
    _overviewStatus = LoadStatus.loading;
    _overviewError = null;
    notifyListeners();

    final result = await _attendanceRepository.getSessions(date: date, className: className, section: section);
    result.when(
      success: (sessions) {
        _overviewSessions = sessions;
        _overviewStatus = LoadStatus.success;
      },
      failure: (error) {
        _overviewError = error;
        _overviewStatus = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<void> loadCorrections({String status = 'pending'}) async {
    _correctionsStatus = LoadStatus.loading;
    _correctionsError = null;
    notifyListeners();

    final result = await _correctionRepository.getCorrections(status: status);
    result.when(
      success: (corrections) {
        _corrections = corrections;
        _correctionsStatus = LoadStatus.success;
      },
      failure: (error) {
        _correctionsError = error;
        _correctionsStatus = LoadStatus.error;
      },
    );
    notifyListeners();
  }

  Future<bool> approveCorrection(String id, {String? reviewNote}) async {
    _processingCorrectionIds.add(id);
    _correctionActionError = null;
    notifyListeners();

    final result = await _correctionRepository.approve(id, reviewNote: reviewNote);
    final succeeded = result.isSuccess;
    result.when(
      success: (_) => _corrections = _corrections.where((c) => c.id != id).toList(),
      failure: (error) => _correctionActionError = error,
    );

    _processingCorrectionIds.remove(id);
    notifyListeners();
    return succeeded;
  }

  Future<bool> rejectCorrection(String id, {String? reviewNote}) async {
    _processingCorrectionIds.add(id);
    _correctionActionError = null;
    notifyListeners();

    final result = await _correctionRepository.reject(id, reviewNote: reviewNote);
    final succeeded = result.isSuccess;
    result.when(
      success: (_) => _corrections = _corrections.where((c) => c.id != id).toList(),
      failure: (error) => _correctionActionError = error,
    );

    _processingCorrectionIds.remove(id);
    notifyListeners();
    return succeeded;
  }
}
