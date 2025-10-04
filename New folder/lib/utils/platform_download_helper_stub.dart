import 'dart:typed_data';
import 'package:flutter/foundation.dart';

Future<void> platformDownloadBytes(
    Uint8List bytes, String fileName, String mime) async {
  // Stub desktop/mobile: rien (éviter crash). Possibilité future: sauvegarde locale.
  debugPrint(
      '[platformDownloadBytes] (stub non-web) fileName=$fileName len=${bytes.length}');
}

Future<void> platformDownloadText(
    String content, String fileName, String mime) async {
  await platformDownloadBytes(
      Uint8List.fromList(content.codeUnits), fileName, mime);
}
