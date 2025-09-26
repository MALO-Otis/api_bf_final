import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'apisavana_pdf_service.dart';
import '../models/vente_models.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/commercial_models.dart';

/// Rapport combiné Attributions + Ventes (version initiale)
class AttributionSalesCombinedReportPdf {
  static Future<Uint8List> generate({
    required List<AttributionPartielle> attributions,
    required List<Vente> ventes,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    final pdf = pw.Document();

    // Pré-traitements Attributions
    final terminees = attributions
        .where((a) => a.quantiteRestante == 0)
        .toList()
      ..sort((a, b) => b.valeurTotale.compareTo(a.valeurTotale));
    final partielles = attributions
        .where((a) => a.quantiteRestante > 0)
        .toList()
      ..sort((a, b) => b.valeurTotale.compareTo(a.valeurTotale));
    final valeurAttribTotale =
        attributions.fold<double>(0, (s, a) => s + a.valeurTotale);

    // Pré-traitements Ventes
    final ventesFiltrees = ventes.where((v) {
      if (dateDebut != null && v.dateVente.isBefore(dateDebut)) return false;
      if (dateFin != null && v.dateVente.isAfter(dateFin)) return false;
      return true;
    }).toList();
    double caBrut = 0;
    double caCredit = 0;
    double caCreditRembourse = 0;
    double caEspece = 0;
    double caMobile = 0;
    double caAutres = 0;
    for (final v in ventesFiltrees) {
      if (v.statut != StatutVente.annulee) {
        caBrut += v.montantTotal;
        switch (v.modePaiement) {
          case ModePaiement.espece:
            caEspece += v.montantTotal;
            break;
          case ModePaiement.mobile:
            caMobile += v.montantTotal;
            break;
          default:
            caAutres += v.montantTotal;
            break;
        }
      }
      if (v.statut == StatutVente.creditEnAttente) caCredit += v.montantTotal;
      if (v.statut == StatutVente.creditRembourse)
        caCreditRembourse += v.montantTotal;
    }
    final caNet = caBrut - caCredit;

    pw.Widget buildAttributionsMiniTable(
        String title, List<AttributionPartielle> list) {
      if (list.isEmpty) {
        return pw.Text('$title: aucune');
      }
      final data = <List<String>>[
        ['Lot', 'Comm.', 'Attrib.', 'Rest.', 'Valeur', '% Cons.'],
        ...list.take(12).map((a) {
          final consommee = (a.quantiteAttribuee - a.quantiteRestante)
              .clamp(0, a.quantiteAttribuee);
          final pct = a.quantiteAttribuee > 0
              ? (consommee / a.quantiteAttribuee * 100).toStringAsFixed(0)
              : '0';
          return [
            a.numeroLot,
            a.commercialNom,
            a.quantiteAttribuee.toString(),
            a.quantiteRestante.toString(),
            ApiSavanaPdfService.formatAmount(a.valeurTotale),
            '$pct%'
          ];
        })
      ];
      return pw
          .Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(title,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
        pw.SizedBox(height: 4),
        ApiSavanaPdfService.createStyledTable(data: data),
        if (list.length > 12)
          pw.Text('... ${list.length - 12} autres',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      ]);
    }

    pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        header: (c) => ApiSavanaPdfService.buildHeader(
              documentTitle: 'RAPPORT COMBINÉ',
              documentDate: DateTime.now(),
            ),
        footer: (c) => ApiSavanaPdfService.buildFooter(),
        build: (context) => [
              ApiSavanaPdfService.buildSection(
                title: 'PÉRIODE',
                content: pw.Text(
                  dateDebut != null && dateFin != null
                      ? 'Du ${ApiSavanaPdfService.formatDate(dateDebut)} au ${ApiSavanaPdfService.formatDate(dateFin)}'
                      : 'Non spécifiée',
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ),
              ApiSavanaPdfService.buildSection(
                title: 'SYNTHÈSE GLOBALE',
                content: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                        'Attributions: ${attributions.length} (Term. ${terminees.length} / Part. ${partielles.length})'),
                    pw.Text(
                        'Valeur attributions: ${ApiSavanaPdfService.formatAmount(valeurAttribTotale)}'),
                    pw.SizedBox(height: 6),
                    pw.Text(
                        'Ventes (CA brut): ${ApiSavanaPdfService.formatAmount(caBrut)}'),
                    pw.Text(
                        'Crédits en attente: ${ApiSavanaPdfService.formatAmount(caCredit)}'),
                    pw.Text(
                        'Crédits remboursés: ${ApiSavanaPdfService.formatAmount(caCreditRembourse)}'),
                    pw.Text(
                        'CA net: ${ApiSavanaPdfService.formatAmount(caNet)}'),
                    pw.SizedBox(height: 6),
                    if (caBrut > 0)
                      pw.Text(
                          'Ventilation espèces ${(caEspece / caBrut * 100).toStringAsFixed(1)}%  |  Mobile ${(caMobile / caBrut * 100).toStringAsFixed(1)}%  |  Autres ${(caAutres / caBrut * 100).toStringAsFixed(1)}%'),
                  ],
                ),
              ),
              ApiSavanaPdfService.buildSection(
                title: 'ATTRIBUTIONS TERMINÉES (Top)',
                content: buildAttributionsMiniTable('Terminées', terminees),
              ),
              ApiSavanaPdfService.buildSection(
                title: 'ATTRIBUTIONS PARTIELLES (Top)',
                content: buildAttributionsMiniTable('Partielles', partielles),
              ),
              ApiSavanaPdfService.buildSection(
                title: 'VENTES RÉCENTES (Max 15)',
                content: _buildVentesTable(ventesFiltrees),
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                  'Généré le ${ApiSavanaPdfService.formatDateTime(DateTime.now())}.',
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey600)),
            ]));

    return pdf.save();
  }

  static pw.Widget _buildVentesTable(List<Vente> ventes) {
    if (ventes.isEmpty) return pw.Text('Aucune vente');
    final sorted = [...ventes]
      ..sort((a, b) => b.dateVente.compareTo(a.dateVente));
    final data = <List<String>>[
      ['Date', 'Commercial', 'Client', 'Montant', 'Mode', 'Statut'],
      ...sorted.take(15).map((v) => [
            ApiSavanaPdfService.formatDate(v.dateVente),
            v.commercialNom,
            v.clientNom,
            ApiSavanaPdfService.formatAmount(v.montantTotal),
            v.modePaiement.name,
            v.statut.name,
          ])
    ];
    return ApiSavanaPdfService.createStyledTable(data: data);
  }
}
