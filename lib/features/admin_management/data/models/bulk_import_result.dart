/// `POST /api/students/bulk-import`'s response `data` shape, confirmed
/// against `studentController.js`'s `bulkCreateStudents`.
class BulkImportFailure {
  final int row;
  final String? email;
  final String reason;

  const BulkImportFailure({required this.row, required this.email, required this.reason});

  factory BulkImportFailure.fromJson(Map<String, dynamic> json) => BulkImportFailure(
        row: (json['row'] as num).toInt(),
        email: json['email'] as String?,
        reason: json['reason'] as String? ?? '',
      );
}

class BulkImportResult {
  final int createdCount;
  final List<BulkImportFailure> failed;
  final int totalRows;

  const BulkImportResult({required this.createdCount, required this.failed, required this.totalRows});

  factory BulkImportResult.fromJson(Map<String, dynamic> json) => BulkImportResult(
        createdCount: (json['created'] as List).length,
        failed: (json['failed'] as List)
            .map((f) => BulkImportFailure.fromJson(f as Map<String, dynamic>))
            .toList(),
        totalRows: (json['totalRows'] as num).toInt(),
      );
}
