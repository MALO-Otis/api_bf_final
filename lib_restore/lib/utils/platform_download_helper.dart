import 'dart:typed_data';
import 'platform_download_helper_web.dart'

// Conditional imports:
//   - Sur Web on utilise platform_download_helper_web.dart
//   - Sur autres plateformes platform_download_helper_stub.dart (noop)
    if (dart.library.io) 'platform_download_helper_stub.dart';

Future<void> downloadTextCross(String content,
    {required String fileName, String mime = 'text/plain'}) async {
  await platformDownloadText(content, fileName, mime);
}

Future<void> downloadBytesCross(Uint8List bytes,
    {required String fileName,
    String mime = 'application/octet-stream'}) async {
  await platformDownloadBytes(bytes, fileName, mime);
}
