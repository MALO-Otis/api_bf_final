import 'dart:typed_data';
import 'dart:html' as html;
// Web-specific implementation using dart:html to trigger a file download.
// Separated to avoid build errors on desktop/mobile platforms.
// ignore: avoid_web_libraries_in_flutter

void downloadPdfBytes(Uint8List bytes, String fileName) {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
