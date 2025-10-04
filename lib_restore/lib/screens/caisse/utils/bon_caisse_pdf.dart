import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import '../controllers/caisse_controller.dart';
import '../../vente/utils/apisavana_pdf_service.dart';

/// Générateur PDF pour le Bon de Caisse (reconciliation)
class BonCaissePdf {
  /// Crée un PDF bien structuré et coloré pour la liste de lignes de réconciliation
  static Future<Uint8List> buildBonCaissePdf(
      List<CaisseReconciliationLine> lignes,
      {required DateTime periodeStart,
      required DateTime periodeEnd}) async {
    final pdf = pw.Document();
    final df = DateFormat('dd/MM/yyyy');
    final title = 'BON DE CAISSE';
    final subtitle =
        'Période: ${df.format(periodeStart)} → ${df.format(periodeEnd)}';

    // Header & footer use ApiSavanaPdfService for consistent look
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(18),
        header: (ctx) => ApiSavanaPdfService.buildHeader(
          documentTitle: title,
          documentNumber: 'BC-${DateTime.now().millisecondsSinceEpoch}',
          documentDate: DateTime.now(),
        ),
        footer: (ctx) => ApiSavanaPdfService.buildFooter(),
        build: (context) {
          final rows = <List<String>>[];

          // Table header
          rows.add([
            'Commercial',
            'CA Brut',
            'Crédits',
            'Créd. Remb.',
            'Théorique',
            'Reçu',
            'Écart'
          ]);

          for (final l in lignes) {
            rows.add([
              l.commercialNom,
              ApiSavanaPdfService.formatAmount(l.caBrut),
              ApiSavanaPdfService.formatAmount(l.credit),
              ApiSavanaPdfService.formatAmount(l.creditRembourse),
              ApiSavanaPdfService.formatAmount(l.cashTheorique),
              ApiSavanaPdfService.formatAmount(l.cashRecu),
              l.ecart.toStringAsFixed(0),
            ]);
          }

          // Totals
          final totalTheo =
              lignes.fold<double>(0, (s, e) => s + e.cashTheorique);
          final totalRecu = lignes.fold<double>(0, (s, e) => s + e.cashRecu);
          final totalEcart = lignes.fold<double>(0, (s, e) => s + e.ecart);

          rows.add([
            'TOTAL',
            '',
            '',
            '',
            ApiSavanaPdfService.formatAmount(totalTheo),
            ApiSavanaPdfService.formatAmount(totalRecu),
            totalEcart.toStringAsFixed(0),
          ]);

          return [
            pw.SizedBox(height: 8),
            pw.Text(subtitle,
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(6),
                color: PdfColor.fromInt(0xFFF8FAFC),
              ),
              child: ApiSavanaPdfService.createStyledTable(
                data: rows,
                hasHeader: true,
                columnWidths: [0.28, 0.12, 0.12, 0.12, 0.12, 0.12, 0.12],
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Certifié exact:',
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    pw.Text('Signature Caissier: ____________________',
                        style: pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Total Écart',
                        style: pw.TextStyle(
                            fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: pw.BoxDecoration(
                          color: totalEcart.abs() < 1
                              ? PdfColor.fromInt(0xFFD1FAE5)
                              : PdfColor.fromInt(0xFFFFE4E6),
                          borderRadius: pw.BorderRadius.circular(6)),
                      child: pw.Text(
                          ApiSavanaPdfService.formatAmount(totalEcart),
                          style: pw.TextStyle(
                              fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    )
                  ],
                )
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Text('Notes:',
                style:
                    pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text(
                'Ce bon de caisse récapitule les encaissements saisis par le caissier pour la période indiquée.',
                style: pw.TextStyle(fontSize: 9)),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
