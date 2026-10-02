import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Mobile/desktop: opens the system "Save as" screen (Android's document
/// picker, iOS Files) via `file_picker`, which writes [bytes] wherever the
/// user chooses — no storage permission needed. Returns `false` when the
/// user cancels.
Future<bool> saveBytesAsFile(Uint8List bytes, String filename) async {
  final uri = await FilePicker.saveFile(fileName: filename, bytes: bytes, mimeType: _mimeTypeFor(filename));
  return uri != null;
}

String _mimeTypeFor(String filename) => switch (filename.split('.').last.toLowerCase()) {
  'pdf' => 'application/pdf',
  'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'xls' => 'application/vnd.ms-excel',
  'csv' => 'text/csv',
  'zip' => 'application/zip',
  _ => 'application/octet-stream',
};
