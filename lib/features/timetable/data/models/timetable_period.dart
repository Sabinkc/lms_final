/// One class period. `teacherId` carries the same dual-shape-ref parsing as
/// `Department.headOfDepartmentId` — populated `{_id, employeeId,
/// userId:{fullName}}` on every read path (`timetableController.js` always
/// `.populate()`s it, except Teacher's own `/teacher` view, which returns it
/// as a bare id since the caller already knows who they are), bare id/null
/// on write. `startTime`/`endTime` are free-text strings, confirmed example
/// shape `"10:00 AM"` (`timetableSchema.js` comment) — not parsed as a
/// `DateTime`, matched by the UI as-is.
class TimetablePeriod {
  final int periodNumber;
  final String subject;
  final String? teacherId;
  final String? teacherName;
  final String startTime;
  final String endTime;
  final String? room;

  const TimetablePeriod({
    required this.periodNumber,
    required this.subject,
    required this.teacherId,
    required this.teacherName,
    required this.startTime,
    required this.endTime,
    required this.room,
  });

  factory TimetablePeriod.fromJson(Map<String, dynamic> json) {
    final teacher = json['teacherId'];
    String? teacherId;
    String? teacherName;
    if (teacher is Map<String, dynamic>) {
      teacherId = teacher['_id'] as String?;
      final user = teacher['userId'] as Map<String, dynamic>?;
      teacherName = user?['fullName'] as String? ?? teacher['employeeId'] as String?;
    } else if (teacher is String) {
      teacherId = teacher;
    }

    return TimetablePeriod(
      periodNumber: (json['periodNumber'] as num?)?.toInt() ?? 0,
      subject: json['subject'] as String? ?? '',
      teacherId: teacherId,
      teacherName: teacherName,
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      room: json['room'] as String?,
    );
  }
}

/// Write-side input for one period — the server only ever needs a bare
/// `teacherId`, never the populated shape [TimetablePeriod] reads back.
class TimetablePeriodInput {
  final int periodNumber;
  final String subject;
  final String? teacherId;
  final String startTime;
  final String endTime;
  final String? room;

  const TimetablePeriodInput({
    required this.periodNumber,
    required this.subject,
    required this.teacherId,
    required this.startTime,
    required this.endTime,
    required this.room,
  });

  Map<String, dynamic> toJson() => {
        'periodNumber': periodNumber,
        'subject': subject,
        if (teacherId != null) 'teacherId': teacherId,
        'startTime': startTime,
        'endTime': endTime,
        if (room != null && room!.isNotEmpty) 'room': room,
      };
}
