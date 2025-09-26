import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'pdf_download_stub.dart' if (dart.library.html) 'pdf_download_web.dart';
// Conditional import: on web we get the real downloader, elsewhere a no-op.

/// Helper centralisé pour l'export / aperçu des PDF.
/// - Web: téléchargement direct (anchor + Blob)
/// - Mobile/Desktop: aperçu + impression / partage via printing
/// Ajoute aussi une logique de cache mémoire courte pour éviter
/// de régénérer plusieurs fois le même document d'affilée.
class PdfExportHelper {
  static final Map<String, _PdfCacheEntry> _cache = {};
  static const Duration defaultTtl = Duration(seconds: 45);

  /// Génère un nom de fichier standardisé.
  /// baseName: ex "rapport_attributions".
  /// dateRange: optionnel, sera ajouté sous forme _YYYYMMDD-YYYYMMDD.
  static String buildFileName(String baseName,
      {DateTime? start, DateTime? end}) {
    final now = DateTime.now();
    final ts = DateFormat('yyyy-MM-dd_HH-mm').format(now);
    String range = '';
    if (start != null || end != null) {
      final df = DateFormat('yyyyMMdd');
      final s = start != null ? df.format(start) : 'XXXXXX';
      final e = end != null ? df.format(end) : 'XXXXXX';
      range = '_${s}-${e}';
    }
    return '${baseName}${range}_$ts.pdf';
  }

  /// Retourne (si encore valide) un PDF précédemment stocké.
  static Uint8List? getFromCache(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _cache.remove(key);
      return null;
    }
    return entry.bytes;
  }

  /// Stocke un PDF dans le cache.
  static void putInCache(String key, Uint8List bytes, {Duration? ttl}) {
    _cache[key] = _PdfCacheEntry(
      bytes: bytes,
      expiresAt: DateTime.now().add(ttl ?? defaultTtl),
    );
  }

  /// Export / preview d'un document PDF.
  /// Si [bytes] est null, affiche un SnackBar d'erreur.
  static Future<void> export({
    required BuildContext context,
    required Uint8List? bytes,
    required String fileName,
    bool cache = false,
    String? cacheKey,
    Duration? cacheTtl,
  }) async {
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: PDF vide.')),
      );
      return;
    }

    if (cache && cacheKey != null) {
      putInCache(cacheKey, bytes, ttl: cacheTtl);
    }

    if (kIsWeb) {
      // Web: déclenche un téléchargement direct.
      downloadPdfBytes(bytes, fileName);
      return;
    }

    // Desktop / Mobile: ouvre l'aperçu impression / partage.
    await Printing.layoutPdf(
      name: fileName,
      onLayout: (format) async => bytes,
    );
  }
}

class _PdfCacheEntry {
  final Uint8List bytes;
  final DateTime expiresAt;
  _PdfCacheEntry({required this.bytes, required this.expiresAt});
}
