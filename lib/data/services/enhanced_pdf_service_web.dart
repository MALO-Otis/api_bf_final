import 'dart:typed_data';
import 'dart:io' show Platform;

/// Téléchargement spécifique pour le web
Future<void> downloadPdfWeb(Uint8List pdfBytes, String filename) async {
  // Cette fonction ne devrait pas être appelée sur desktop
  throw UnsupportedError('Web download is not available on desktop platforms');
}

/// Stub pour desktop (non utilisé sur web)
Future<void> downloadPdfDesktop(
    Uint8List pdfBytes, String filename, String title) async {
  // Cette fonction ne devrait pas être appelée sur desktop non plus
  // car elle est gérée par le service principal
  throw UnsupportedError('Use the main PDF service for desktop platforms');
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
