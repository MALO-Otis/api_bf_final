import 'dart:html' as html;
import 'dart:typed_data';

/// Téléchargement spécifique pour le web
Future<void> downloadPdfWeb(Uint8List pdfBytes, String filename) async {
  final blob = html.Blob([pdfBytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.document.createElement('a') as html.AnchorElement;
  anchor.href = url;
  anchor.download = filename;
  anchor.click();
  html.Url.revokeObjectUrl(url);
}

/// Stub pour desktop (non utilisé sur web)
Future<void> downloadPdfDesktop(
    Uint8List pdfBytes, String filename, String title) async {
  // Rediriger vers downloadPdfWeb sur le web
  await downloadPdfWeb(pdfBytes, filename);
}

/// Stub pour mobile (non utilisé sur web)
Future<void> sharePdfMobile(
  Uint8List pdfBytes,
  String filename,
  String title,
  String? description,
) async {
  // Rediriger vers downloadPdfWeb sur le web
  await downloadPdfWeb(pdfBytes, filename);
}
