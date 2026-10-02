/// `VALID_STATUSES` in `studentattendanceController.js` — the only values
/// the backend accepts for a per-student record.
enum AttendanceStatus {
  present,
  absent,
  late,
  leave,
  halfDay;

  String get apiValue => switch (this) {
    AttendanceStatus.present => 'present',
    AttendanceStatus.absent => 'absent',
    AttendanceStatus.late => 'late',
    AttendanceStatus.leave => 'leave',
    AttendanceStatus.halfDay => 'half-day',
  };

  String get label => switch (this) {
    AttendanceStatus.present => 'Present',
    AttendanceStatus.absent => 'Absent',
    AttendanceStatus.late => 'Late',
    AttendanceStatus.leave => 'Leave',
    AttendanceStatus.halfDay => 'Half-day',
  };

  static AttendanceStatus fromApiValue(String value) => switch (value) {
    'absent' => AttendanceStatus.absent,
    'late' => AttendanceStatus.late,
    'leave' => AttendanceStatus.leave,
    'half-day' => AttendanceStatus.halfDay,
    _ => AttendanceStatus.present,
  };
}
