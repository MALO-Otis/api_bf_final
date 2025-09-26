import 'dart:typed_data';
// Stub implementation used for non-web platforms.
// Provides a uniform API so that pdf_export_helper can call downloadPdfBytes
// without depending directly on dart:html.

void downloadPdfBytes(Uint8List bytes, String fileName) {
  // No-op outside web. The actual handling (preview/print) is done via printing.
}
