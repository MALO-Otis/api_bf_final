import 'dart:typed_data';
import 'pdf_download_helper_stub.dart'

// Conditional imports select the right implementation per platform.
    if (dart.library.html) 'pdf_download_helper_web.dart'
    if (dart.library.io) 'pdf_download_helper_io.dart' as impl;

/// Cross-platform method to save/download PDF bytes.
/// - On Web: triggers a browser download (returns the filename)
/// - On IO (Windows/Linux/macOS/Android/iOS): writes the file and returns the absolute file path
Future<String> savePdfBytes(Uint8List bytes, String fileName) =>
    impl.savePdfBytes(bytes, fileName);
