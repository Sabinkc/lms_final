import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'file_download.dart';

/// Saves downloaded bytes for every export/download call site (Backup, Fees
/// export, Follow-ups export, ID Cards x2, Student roster export + import
/// template) and tells the user how it went: web hands the file to the
/// browser, mobile opens the system "Save as" screen. A cancelled save shows
/// nothing; a failure shows a SnackBar instead of escaping as an uncaught
/// error (which used to leave the button silently doing nothing).
Future<void> saveBytesOrNotify(BuildContext context, Uint8List bytes, String filename) async {
  String? message;
  try {
    if (await saveBytesAsFile(bytes, filename)) message = 'Saved $filename';
  } catch (_) {
    message = 'Could not save $filename. Please try again.';
  }
  if (message != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
