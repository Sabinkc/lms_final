import 'dart:typed_data';
// ignore: deprecated_member_use
import 'dart:html' as html;

/// Triggers a browser file-save via a temporary object URL + anchor click —
/// the standard pattern for "download these bytes" on Flutter web, needed
/// because the backend's export/template endpoints are `protectAdmin`-only
/// (header-only Bearer auth, confirmed no query-token fallback in
/// `adminAuthMiddleware.js`) — a plain `<a href>` to the API URL can't
/// authenticate, so the bytes have to come through [ApiClient] first and get
/// handed to the browser this way instead.
void saveBytesAsFile(Uint8List bytes, String filename) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
