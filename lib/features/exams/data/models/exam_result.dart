/// `Result` (System B), confirmed against `resultSchema.js`/
/// `resultController.js`/`resultService.js`. One doc per student per exam.
class ExamResultMark {
  final String subject;
  final int fullMarks;
  final int passMarks;
  final int obtainedMarks;
  final bool isPassed;
  final String grade;

  const ExamResultMark({
    required this.subject,
    required this.fullMarks,
    required this.passMarks,
    required this.obtainedMarks,
    required this.isPassed,
    required this.grade,
  });

  factory ExamResultMark.fromJson(Map<String, dynamic> json) => ExamResultMark(
        subject: json['subject'] as String? ?? '',
        fullMarks: (json['fullMarks'] as num?)?.toInt() ?? 0,
        passMarks: (json['passMarks'] as num?)?.toInt() ?? 0,
        obtainedMarks: (json['obtainedMarks'] as num?)?.toInt() ?? 0,
        isPassed: json['isPassed'] as bool? ?? false,
        grade: json['grade'] as String? ?? '',
      );
}

class ExamResult {
  final String id;
  final String examId;
  final String examTitle;
  final String studentId;
  final String studentName;
  final String studentAdmissionNumber;
  final List<ExamResultMark> marks;
  final int totalObtained;
  final int totalFull;
  final double percentage;
  final String grade;
  final bool isPassed;
  final int? rank;
  final String remarks;

  const ExamResult({
    required this.id,
    required this.examId,
    required this.examTitle,
    required this.studentId,
    required this.studentName,
    required this.studentAdmissionNumber,
    required this.marks,
    required this.totalObtained,
    required this.totalFull,
    required this.percentage,
    required this.grade,
    required this.isPassed,
    required this.rank,
    required this.remarks,
  });

  factory ExamResult.fromJson(Map<String, dynamic> json) {
    final examRef = json['examId'];
    final studentRef = json['studentId'];
    final studentUser = studentRef is Map<String, dynamic> ? studentRef['userId'] : null;

    return ExamResult(
      id: json['_id'] as String? ?? json['id'] as String,
      examId: examRef is Map<String, dynamic> ? examRef['_id'] as String? ?? '' : examRef as String? ?? '',
      examTitle: examRef is Map<String, dynamic> ? examRef['title'] as String? ?? '' : '',
      studentId: studentRef is Map<String, dynamic> ? studentRef['_id'] as String? ?? '' : studentRef as String? ?? '',
      studentName: studentUser is Map<String, dynamic> ? studentUser['fullName'] as String? ?? '' : '',
      studentAdmissionNumber: studentRef is Map<String, dynamic> ? studentRef['admissionNumber'] as String? ?? '' : '',
      marks: (json['marks'] as List? ?? const []).map((m) => ExamResultMark.fromJson(m as Map<String, dynamic>)).toList(),
      totalObtained: (json['totalObtained'] as num?)?.toInt() ?? 0,
      totalFull: (json['totalFull'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      grade: json['grade'] as String? ?? '',
      isPassed: json['isPassed'] as bool? ?? false,
      rank: (json['rank'] as num?)?.toInt(),
      remarks: json['remarks'] as String? ?? '',
    );
  }
}

/// `summary` shape from `getAllMyResults`/`getChildResults`.
class ResultsSummary {
  final int totalExams;
  final int passed;
  final int failed;
  final double averagePercentage;
  final String? bestGrade;

  const ResultsSummary({
    required this.totalExams,
    required this.passed,
    required this.failed,
    required this.averagePercentage,
    this.bestGrade,
  });

  factory ResultsSummary.fromJson(Map<String, dynamic> json) => ResultsSummary(
        totalExams: (json['totalExams'] as num?)?.toInt() ?? 0,
        passed: (json['passed'] as num?)?.toInt() ?? 0,
        failed: (json['failed'] as num?)?.toInt() ?? 0,
        averagePercentage: double.tryParse('${json['averagePercentage']}') ?? 0,
        bestGrade: json['bestGrade'] as String?,
      );
}

/// `summary` shape from `getExamResults` (Admin, class-level).
class ClassResultsSummary {
  final int total;
  final int passed;
  final int failed;
  final double avgPercentage;
  final Map<String, int> gradeDistribution;

  const ClassResultsSummary({
    required this.total,
    required this.passed,
    required this.failed,
    required this.avgPercentage,
    required this.gradeDistribution,
  });

  factory ClassResultsSummary.fromJson(Map<String, dynamic> json) => ClassResultsSummary(
        total: (json['total'] as num?)?.toInt() ?? 0,
        passed: (json['passed'] as num?)?.toInt() ?? 0,
        failed: (json['failed'] as num?)?.toInt() ?? 0,
        avgPercentage: double.tryParse('${json['avgPercentage']}') ?? 0,
        gradeDistribution: (json['gradeDistribution'] as Map<String, dynamic>? ?? const {})
            .map((k, v) => MapEntry(k, (v as num).toInt())),
      );
}

/// `GET /api/results/report-card/:examId/:studentId`'s response shape.
class ReportCard {
  final String schoolName;
  final String examTitle;
  final String studentName;
  final String admissionNumber;
  final String rollNumber;
  final String className;
  final String section;
  final List<ExamResultMark> marks;
  final int totalObtained;
  final int totalFull;
  final double percentage;
  final String grade;
  final int? rank;
  final bool isPassed;
  final String remarks;

  const ReportCard({
    required this.schoolName,
    required this.examTitle,
    required this.studentName,
    required this.admissionNumber,
    required this.rollNumber,
    required this.className,
    required this.section,
    required this.marks,
    required this.totalObtained,
    required this.totalFull,
    required this.percentage,
    required this.grade,
    required this.rank,
    required this.isPassed,
    required this.remarks,
  });

  factory ReportCard.fromJson(Map<String, dynamic> json) {
    final school = json['school'] as Map<String, dynamic>?;
    final exam = json['exam'] as Map<String, dynamic>?;
    final student = json['student'] as Map<String, dynamic>?;
    final summary = json['summary'] as Map<String, dynamic>?;

    return ReportCard(
      schoolName: school?['name'] as String? ?? '',
      examTitle: exam?['title'] as String? ?? '',
      studentName: student?['name'] as String? ?? '',
      admissionNumber: student?['admissionNumber'] as String? ?? '',
      rollNumber: student?['rollNumber'] as String? ?? '',
      className: student?['class'] as String? ?? '',
      section: student?['section'] as String? ?? '',
      marks: (json['marks'] as List? ?? const []).map((m) => ExamResultMark.fromJson(m as Map<String, dynamic>)).toList(),
      totalObtained: (summary?['totalObtained'] as num?)?.toInt() ?? 0,
      totalFull: (summary?['totalFull'] as num?)?.toInt() ?? 0,
      percentage: (summary?['percentage'] as num?)?.toDouble() ?? 0,
      grade: summary?['grade'] as String? ?? '',
      rank: (summary?['rank'] as num?)?.toInt(),
      isPassed: summary?['isPassed'] as bool? ?? false,
      remarks: summary?['remarks'] as String? ?? '',
    );
  }
}
