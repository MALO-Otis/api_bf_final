import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Stub pour web (non utilisé sur desktop/mobile)
Future<void> downloadPdfWeb(Uint8List pdfBytes, String filename) async {
  throw UnsupportedError('downloadPdfWeb not supported on this platform');
}

/// Téléchargement spécifique pour desktop
Future<void> downloadPdfDesktop(
    Uint8List pdfBytes, String filename, String title) async {
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    final directory = await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(pdfBytes);
  } else {
    // Pour mobile, utiliser le partage
    await sharePdfMobile(pdfBytes, filename, title, null);
  }
}

/// Partage spécifique pour mobile
Future<void> sharePdfMobile(
  Uint8List pdfBytes,
  String filename,
  String title,
  String? description,
) async {
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/$filename');
  await file.writeAsBytes(pdfBytes);

  final xFile = XFile(file.path);
  await Share.shareXFiles(
    [xFile],
    subject: title,
    text: description ?? 'Rapport généré par ApiSavana Gestion',
  );
}
