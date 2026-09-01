import 'dart:typed_data';

/// Non-web fallback. No verified local target other than Chrome web exists
/// for this app yet (docs/production_roadmap.md §1) — mobile/desktop
/// download UX is deliberately left unimplemented rather than guessed.
void saveBytesAsFile(Uint8List bytes, String filename) {
  throw UnsupportedError('File download is only implemented for the web target.');
}
