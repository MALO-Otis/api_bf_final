import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'apisavana_pdf_service.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/commercial_models.dart';

/// Rapport groupé des attributions (terminées & partielles) avec en-tête standard.
class AttributionStatusReportPdf {
  /// Génère un PDF listant séparément les attributions terminées et partiellement attribuées.
  /// [attributions] : liste complète courante.
  /// La détection "terminée" se base sur quantiteRestante == 0.
  static Future<Uint8List> generate({
    required List<AttributionPartielle> attributions,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    final pdf = pw.Document();
    final terminees =
        attributions.where((a) => a.quantiteRestante == 0).toList();
    final partielles =
        attributions.where((a) => a.quantiteRestante > 0).toList();

    // Tri par valeur totale décroissante
    terminees.sort((a, b) => b.valeurTotale.compareTo(a.valeurTotale));
    partielles.sort((a, b) => b.valeurTotale.compareTo(a.valeurTotale));

    double totalValeurTerminees =
        terminees.fold(0, (s, a) => s + a.valeurTotale);
    double totalValeurPartielles =
        partielles.fold(0, (s, a) => s + a.valeurTotale);

    pw.Widget buildTable(String title, List<AttributionPartielle> list) {
      if (list.isEmpty) {
        return pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            border: pw.Border.all(color: PdfColors.black),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text('Aucune attribution',
              style: const pw.TextStyle(fontSize: 10)),
        );
      }
      final data = <List<String>>[
        [
          'Lot',
          'Commercial',
          'Type',
          'Attribuée',
          'Consommée',
          'Restante',
          'Valeur Tot.',
          '% Cons.'
        ],
        ...list.map((a) {
          final consommee = (a.quantiteAttribuee - a.quantiteRestante)
              .clamp(0, a.quantiteAttribuee);
          final progression = a.quantiteAttribuee > 0
              ? (consommee / a.quantiteAttribuee * 100)
                  .clamp(0, 100)
                  .toStringAsFixed(1)
              : '0';
          return [
            a.numeroLot,
            a.commercialNom,
            a.typeEmballage,
            a.quantiteAttribuee.toString(),
            consommee.toString(),
            a.quantiteRestante.toString(),
            ApiSavanaPdfService.formatAmount(a.valeurTotale),
            '$progression%'
          ];
        })
      ];
      return ApiSavanaPdfService.createStyledTable(
        data: data,
        columnWidths: const [0.12, 0.20, 0.12, 0.11, 0.11, 0.11, 0.15, 0.08],
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        header: (c) => ApiSavanaPdfService.buildHeader(
          documentTitle: 'RAPPORT ATTRIBUTIONS',
          documentDate: DateTime.now(),
        ),
        footer: (c) => ApiSavanaPdfService.buildFooter(),
        build: (context) => [
          ApiSavanaPdfService.buildSection(
            title: 'PÉRIODE',
            content: pw.Text(
              dateDebut != null && dateFin != null
                  ? 'Du ${ApiSavanaPdfService.formatDate(dateDebut)} au ${ApiSavanaPdfService.formatDate(dateFin)}'
                  : 'Période: Non spécifiée',
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
          ApiSavanaPdfService.buildSection(
            title: 'RÉSUMÉ',
            content: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Total attributions: ${attributions.length}',
                    style: pw.TextStyle(fontSize: 11)),
                pw.Text(
                    'Terminées: ${terminees.length}  |  Partielles: ${partielles.length}',
                    style: const pw.TextStyle(fontSize: 11)),
                pw.SizedBox(height: 4),
                pw.Text(
                    'Valeur totale terminées: ${ApiSavanaPdfService.formatAmount(totalValeurTerminees)}',
                    style: pw.TextStyle(fontSize: 10)),
                pw.Text(
                    'Valeur totale partielles: ${ApiSavanaPdfService.formatAmount(totalValeurPartielles)}',
                    style: pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
          ApiSavanaPdfService.buildSection(
            title: 'ATTRIBUTIONS TERMINÉES',
            content: buildTable('Terminées', terminees),
          ),
          ApiSavanaPdfService.buildSection(
            title: 'ATTRIBUTIONS PARTIELLES',
            content: buildTable('Partielles', partielles),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Document généré automatiquement le ${ApiSavanaPdfService.formatDateTime(DateTime.now())}.',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.black),
          )
        ],
      ),
    );

    return pdf.save();
  }
}
