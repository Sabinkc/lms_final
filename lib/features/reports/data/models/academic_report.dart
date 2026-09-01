/// `GET /reports/academic` response shape, confirmed by reading
/// `Reportcontroller.js`'s `getAcademicReport` directly (`api_spec.md`
/// §4.14 only confirmed the endpoint existed, not its payload).
///
/// `passRate` is `0` (a number) when there are no published results yet,
/// but a string like `"76.5"` (JS `.toFixed(1)`) otherwise — parsed via
/// `double.tryParse('$value')` to handle both.
class AcademicReport {
  final int totalExams;
  final int published;
  final int upcoming;
  final int ongoing;
  final int completed;
  final Map<String, int> gradeDistribution;
  final int totalStudentResults;
  final int totalPassed;
  final double passRate;
  final int totalStudents;
  final int totalTeachers;

  const AcademicReport({
    required this.totalExams,
    required this.published,
    required this.upcoming,
    required this.ongoing,
    required this.completed,
    required this.gradeDistribution,
    required this.totalStudentResults,
    required this.totalPassed,
    required this.passRate,
    required this.totalStudents,
    required this.totalTeachers,
  });

  factory AcademicReport.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? const {};
    final gradeDistribution = (json['gradeDistribution'] as Map<String, dynamic>? ?? const {})
        .map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0));
    return AcademicReport(
      totalExams: (summary['totalExams'] as num?)?.toInt() ?? 0,
      published: (summary['published'] as num?)?.toInt() ?? 0,
      upcoming: (summary['upcoming'] as num?)?.toInt() ?? 0,
      ongoing: (summary['ongoing'] as num?)?.toInt() ?? 0,
      completed: (summary['completed'] as num?)?.toInt() ?? 0,
      gradeDistribution: gradeDistribution,
      totalStudentResults: (json['totalStudentResults'] as num?)?.toInt() ?? 0,
      totalPassed: (json['totalPassed'] as num?)?.toInt() ?? 0,
      passRate: double.tryParse('${json['passRate']}') ?? 0,
      totalStudents: (json['totalStudents'] as num?)?.toInt() ?? 0,
      totalTeachers: (json['totalTeachers'] as num?)?.toInt() ?? 0,
    );
  }
}
