import 'dart:typed_data';

import '../../../../core/error/result.dart';

/// `/api/id-cards`, confirmed by reading `idCardRoutes.js`/
/// `idCardController.js` directly (`docs/production_roadmap.md` Phase L6,
/// `implementation_backlog.md` E21). **Two corrections to the original
/// scoping notes**: there is no QR code anywhere in card generation
/// (`api_spec.md`'s "PDF+QR" characterization was wrong — pure `pdfkit`
/// PDF, no `qrcode` import in the controller at all), and there is no
/// `Document`-model persistence either — each call generates and streams a
/// PDF on demand, nothing is stored server-side. School branding (logo,
/// address, phone, principal signature, stamp) is baked into the PDF
/// server-side from the populated `schoolId`, so no separate branding fetch
/// is needed client-side. `GET /my` only resolves via `Student.findOne({
/// userId: req.user._id})` — there is no Parent-facing equivalent, so
/// Parent access to a child's ID card is confirmed **not possible** via
/// this backend at all (resolves `production_roadmap.md`'s earlier
/// `UNKNOWN — VERIFY` on that point).
abstract class IdCardRepository {
  /// Admin only. `GET /student/:id`.
  Future<Result<Uint8List>> generateStudentIdCard(String studentId);

  /// Student only, own card. `GET /my`.
  Future<Result<Uint8List>> generateMyIdCard();
}
