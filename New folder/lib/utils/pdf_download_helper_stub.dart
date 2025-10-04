import 'dart:typed_data';

// Fallback stub used when neither web nor IO implementations are available.
Future<String> savePdfBytes(Uint8List bytes, String fileName) async {
  // No-op fallback: return the provided filename.
  return fileName;
}
