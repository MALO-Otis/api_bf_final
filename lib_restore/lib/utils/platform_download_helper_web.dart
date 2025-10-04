import 'dart:typed_data';
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter

Future<void> platformDownloadBytes(
    Uint8List bytes, String fileName, String mime) async {
  final blob = html.Blob([bytes], mime);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final a = html.document.createElement('a') as html.AnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = fileName;
  html.document.body!.children.add(a);
  a.click();
  html.document.body!.children.remove(a);
  html.Url.revokeObjectUrl(url);
}

Future<void> platformDownloadText(
    String content, String fileName, String mime) async {
  await platformDownloadBytes(
      Uint8List.fromList(content.codeUnits), fileName, mime);
}
