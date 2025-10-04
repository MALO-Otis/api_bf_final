import 'dart:typed_data';

Future<void> downloadPdfWeb(Uint8List pdfBytes, String filename) async {
  throw UnsupportedError('downloadPdfWeb is not supported on this platform.');
}

Future<void> downloadPdfDesktop(
  Uint8List pdfBytes,
  String filename,
  String title,
) async {
  throw UnsupportedError(
      'downloadPdfDesktop is not supported on this platform.');
}

Future<void> sharePdfMobile(
  Uint8List pdfBytes,
  String filename,
  String title,
  String? description,
) async {
  throw UnsupportedError('sharePdfMobile is not supported on this platform.');
}
