/// `Exam`, confirmed against `examSchema.js`/`examController.js`. `results[]`
/// (System A's embedded field) is deliberately not modeled here — this app
/// builds against System B, the separate `Result` collection (see
/// `docs/production_roadmap.md` Phase F for the full System A/B finding).
class ExamSubject {
  final String name;
  final int fullMarks;
  final int passMarks;
  final String examDate;
  final String? examTime;
  final String? room;

  const ExamSubject({
    required this.name,
    required this.fullMarks,
    required this.passMarks,
    required this.examDate,
    this.examTime,
    this.room,
  });

  factory ExamSubject.fromJson(Map<String, dynamic> json) => ExamSubject(
        name: json['name'] as String? ?? '',
        fullMarks: (json['fullMarks'] as num?)?.toInt() ?? 0,
        passMarks: (json['passMarks'] as num?)?.toInt() ?? 0,
        examDate: json['examDate'] as String? ?? '',
        examTime: json['examTime'] as String?,
        room: json['room'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'fullMarks': fullMarks,
        'passMarks': passMarks,
        'examDate': examDate,
        if (examTime != null) 'examTime': examTime,
        if (room != null) 'room': room,
      };
}

class Exam {
  final String id;
  final String title;
  final String className;
  final String? section;
  final List<ExamSubject> subjects;
  final String examDate;
  final String status;

  const Exam({
    required this.id,
    required this.title,
    required this.className,
    required this.section,
    required this.subjects,
    required this.examDate,
    required this.status,
  });

  factory Exam.fromJson(Map<String, dynamic> json) => Exam(
        id: json['_id'] as String? ?? json['id'] as String,
        title: json['title'] as String? ?? '',
        className: json['className'] as String? ?? '',
        section: json['section'] as String?,
        subjects:
            (json['subjects'] as List? ?? const []).map((s) => ExamSubject.fromJson(s as Map<String, dynamic>)).toList(),
        examDate: json['examDate'] as String? ?? '',
        status: _effectiveStatus(json['status'] as String? ?? 'upcoming', json['examDate'] as String?),
      );

  /// The server never moves an exam on from "upcoming" once its date passes,
  /// so a past "upcoming" exam is shown as completed (on the exam day itself
  /// it still counts as upcoming).
  static String _effectiveStatus(String status, String? examDate) {
    if (status != 'upcoming') return status;
    final date = DateTime.tryParse(examDate ?? '')?.toLocal();
    if (date == null) return status;
    final now = DateTime.now();
    return DateTime(date.year, date.month, date.day).isBefore(DateTime(now.year, now.month, now.day))
        ? 'completed'
        : status;
  }
}
