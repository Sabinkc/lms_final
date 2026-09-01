import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'file_download.dart';

/// Wraps [saveBytesAsFile] for the 7 export/download call sites (Backup,
/// Fees export, Follow-ups export, ID Cards x2, Student roster export +
/// import template) — [saveBytesAsFile] throws [UnsupportedError] on every
/// non-web target (`file_download_stub.dart`), and left unguarded that
/// exception escapes as an uncaught zone error: the button does nothing and
/// the user sees no feedback at all. Catches it here so at least a SnackBar
/// explains why, until a real native save path exists for those targets.
Future<void> saveBytesOrNotify(BuildContext context, Uint8List bytes, String filename) async {
  try {
    saveBytesAsFile(bytes, filename);
  } on UnsupportedError {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloads aren\'t supported on this device yet — use the web app instead.')),
      );
    }
  }
}
