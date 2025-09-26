import 'dart:io' as io;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

Future<String> savePdfBytes(Uint8List bytes, String fileName) async {
  // Try common Downloads path on Android-like devices
  try {
    final downloadsDir = io.Directory('/storage/emulated/0/Download');
    if (await downloadsDir.exists()) {
      final file = io.File('${downloadsDir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    }
  } catch (_) {
    // Continue to fallback
  }

  // Fallback to application documents directory (Windows/macOS/Linux/iOS)
  final dir = await getApplicationDocumentsDirectory();
  final file = io.File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
