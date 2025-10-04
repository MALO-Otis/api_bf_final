import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'apisavana_pdf_service.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/commercial_models.dart';

/// Générateur PDF pour les attributions de lots - Gestion Commerciale
class AttributionPdfGenerator {
  /// Génère un PDF pour une attribution de lot
  static Future<Uint8List> generateAttributionPdf(
      AttributionPartielle attribution) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => ApiSavanaPdfService.buildHeader(
          documentTitle: "REÇU D'ATTRIBUTION DE LOT",
          documentNumber: attribution.id,
          documentDate: attribution.dateAttribution,
        ),
        footer: (context) => ApiSavanaPdfService.buildFooter(),
        build: (context) => [
          // Informations du commercial
          ApiSavanaPdfService.buildSection(
            title: "INFORMATIONS DU COMMERCIAL",
            content: pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Commercial: ${attribution.commercialNom}',
                        style: pw.TextStyle(
                            fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'ID: ${attribution.commercialId}',
                        style:
                            pw.TextStyle(fontSize: 10, color: PdfColors.black),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Site d\'origine: ${attribution.siteOrigine}',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                  pw.Text(
                    'Gestionnaire: ${attribution.gestionnaire}',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ),

          // Informations du lot
          ApiSavanaPdfService.buildSection(
            title: "DÉTAILS DU LOT ATTRIBUÉ",
            content: pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'N° de Lot: ${attribution.numeroLot}',
                              style: pw.TextStyle(
                                  fontSize: 12, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Type d\'emballage: ${attribution.typeEmballage}',
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                            pw.Text(
                              'Contenance: ${attribution.contenanceKg.toStringAsFixed(2)} kg',
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                            pw.Text(
                              'Prédominance florale: ${attribution.predominanceFlorale}',
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'Date de conditionnement:',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                            pw.Text(
                              ApiSavanaPdfService.formatDate(
                                  attribution.dateConditionnement),
                              style: pw.TextStyle(
                                  fontSize: 11, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Statut: ${attribution.statut}',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Détails de l'attribution
          ApiSavanaPdfService.buildSection(
            title: "ATTRIBUTION",
            content: ApiSavanaPdfService.createStyledTable(
              data: [
                ['Élément', 'Valeur'],
                [
                  'Quantité attribuée',
                  '${attribution.quantiteAttribuee} unités'
                ],
                [
                  'Prix unitaire',
                  ApiSavanaPdfService.formatAmount(attribution.prixUnitaire)
                ],
                [
                  'Valeur unitaire',
                  ApiSavanaPdfService.formatAmount(attribution.valeurUnitaire)
                ],
                [
                  'Valeur totale',
                  ApiSavanaPdfService.formatAmount(attribution.valeurTotale)
                ],
                [
                  'Date d\'attribution',
                  ApiSavanaPdfService.formatDateTime(
                      attribution.dateAttribution)
                ],
              ],
              columnWidths: [0.4, 0.6],
              hasHeader: true,
            ),
          ),

          // Suivi des quantités
          ApiSavanaPdfService.buildSection(
            title: "SUIVI DES QUANTITÉS",
            content: pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border.all(color: PdfColors.black),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuantityCard('Quantité initiale',
                          attribution.quantiteInitiale, PdfColors.black),
                      _buildQuantityCard('Quantité attribuée',
                          attribution.quantiteAttribuee, PdfColors.black),
                      _buildQuantityCard('Quantité restante',
                          attribution.quantiteRestante, PdfColors.black),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.LinearProgressIndicator(
                    value: attribution.quantiteInitiale > 0
                        ? (attribution.quantiteInitiale -
                                attribution.quantiteRestante) /
                            attribution.quantiteInitiale
                        : 0,
                    backgroundColor: PdfColors.white,
                    valueColor: PdfColors.black,
                    minHeight: 8,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Progression: ${attribution.quantiteInitiale > 0 ? ((attribution.quantiteInitiale - attribution.quantiteRestante) / attribution.quantiteInitiale * 100).toStringAsFixed(1) : "0"}% attribué',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.black),
                  ),
                ],
              ),
            ),
          ),

          // Observations si présentes
          if (attribution.observations != null &&
              attribution.observations!.isNotEmpty)
            ApiSavanaPdfService.buildSection(
              title: "OBSERVATIONS",
              content: pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFFFF3CD),
                  border: pw.Border.all(color: PdfColor.fromInt(0xFFDDA520)),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  attribution.observations!,
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ),
            ),

          // Modifications si présentes
          if (attribution.motifModification != null &&
              attribution.dateDerniereModification != null)
            ApiSavanaPdfService.buildSection(
              title: "HISTORIQUE DES MODIFICATIONS",
              content: pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  border: pw.Border.all(color: PdfColors.black),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Dernière modification: ${ApiSavanaPdfService.formatDateTime(attribution.dateDerniereModification!)}',
                      style: pw.TextStyle(
                          fontSize: 11, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Motif: ${attribution.motifModification!}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),

          // Signatures et validation
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSignatureBox('Gestionnaire', attribution.gestionnaire),
              _buildSignatureBox('Commercial', attribution.commercialNom),
            ],
          ),

          // Note légale
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF5F5F5),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'Ce document certifie l\'attribution du lot mentionné ci-dessus. '
              'Il constitue un justificatif officiel pour la gestion commerciale des produits ApiSavana. '
              'Document généré automatiquement le ${ApiSavanaPdfService.formatDateTime(DateTime.now())}.',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              textAlign: pw.TextAlign.justify,
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Génère un PDF avec plusieurs attributions (rapport groupé)
  static Future<Uint8List> generateMultipleAttributionsPdf({
    required List<AttributionPartielle> attributions,
    required String titre,
    String? commercial,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    final pdf = pw.Document();

    // Calculs statistiques
    final totalQuantite =
        attributions.fold<int>(0, (sum, attr) => sum + attr.quantiteAttribuee);
    final totalValeur =
        attributions.fold<double>(0, (sum, attr) => sum + attr.valeurTotale);
    final nombreLots = attributions.map((attr) => attr.lotId).toSet().length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => ApiSavanaPdfService.buildHeader(
          documentTitle: titre.toUpperCase(),
          documentDate: DateTime.now(),
        ),
        footer: (context) => ApiSavanaPdfService.buildFooter(),
        build: (context) => [
          // Résumé exécutif
          ApiSavanaPdfService.buildSection(
            title: "RÉSUMÉ EXÉCUTIF",
            content: pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF8F9FA),
                border: pw.Border.all(
                    color: ApiSavanaPdfService.primaryColor, width: 2),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard('Attributions', '${attributions.length}',
                          PdfColors.blue),
                      _buildStatCard(
                          'Lots concernés', '$nombreLots', PdfColors.green),
                      _buildStatCard('Quantité totale', '$totalQuantite',
                          PdfColors.orange),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: ApiSavanaPdfService.primaryColor,
                      borderRadius: pw.BorderRadius.circular(20),
                    ),
                    child: pw.Text(
                      'Valeur totale: ${ApiSavanaPdfService.formatAmount(totalValeur)}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Filtres de recherche si appliqués
          if (commercial != null || dateDebut != null || dateFin != null)
            ApiSavanaPdfService.buildSection(
              title: "CRITÈRES DE SÉLECTION",
              content: pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFE3F2FD),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (commercial != null)
                      pw.Text('Commercial: $commercial',
                          style: const pw.TextStyle(fontSize: 11)),
                    if (dateDebut != null)
                      pw.Text(
                          'Date début: ${ApiSavanaPdfService.formatDate(dateDebut)}',
                          style: const pw.TextStyle(fontSize: 11)),
                    if (dateFin != null)
                      pw.Text(
                          'Date fin: ${ApiSavanaPdfService.formatDate(dateFin)}',
                          style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ),

          // Tableau des attributions
          ApiSavanaPdfService.buildSection(
            title: "DÉTAIL DES ATTRIBUTIONS",
            content: ApiSavanaPdfService.createStyledTable(
              data: [
                ['Date', 'Commercial', 'N° Lot', 'Qté', 'Val. Unit.', 'Total'],
                ...attributions
                    .map((attr) => [
                          ApiSavanaPdfService.formatDate(attr.dateAttribution),
                          attr.commercialNom.length > 15
                              ? '${attr.commercialNom.substring(0, 15)}...'
                              : attr.commercialNom,
                          attr.numeroLot.length > 12
                              ? '${attr.numeroLot.substring(0, 12)}...'
                              : attr.numeroLot,
                          '${attr.quantiteAttribuee}',
                          '${attr.valeurUnitaire.toStringAsFixed(0)}',
                          '${attr.valeurTotale.toStringAsFixed(0)}',
                        ])
                    .toList(),
              ],
              columnWidths: [0.12, 0.22, 0.18, 0.08, 0.15, 0.15],
              hasHeader: true,
            ),
          ),

          // Répartition par commercial
          if (attributions.map((a) => a.commercialNom).toSet().length > 1)
            ApiSavanaPdfService.buildSection(
              title: "RÉPARTITION PAR COMMERCIAL",
              content: _buildCommercialBreakdown(attributions),
            ),
        ],
      ),
    );

    return pdf.save();
  }

  // Méthodes utilitaires pour la mise en forme

  static pw.Widget _buildQuantityCard(String label, int value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        border: pw.Border.all(color: color),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 9, color: color),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            '$value',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStatCard(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        border: pw.Border.all(color: color),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 10, color: color),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatureBox(String title, String name) {
    return pw.Container(
      width: 200,
      height: 80,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(
              title,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Spacer(),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Column(
              children: [
                pw.Container(height: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 2),
                pw.Text(
                  name,
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCommercialBreakdown(
      List<AttributionPartielle> attributions) {
    final breakdown = <String, Map<String, dynamic>>{};

    for (final attr in attributions) {
      if (!breakdown.containsKey(attr.commercialNom)) {
        breakdown[attr.commercialNom] = {
          'count': 0,
          'quantity': 0,
          'value': 0.0,
        };
      }
      breakdown[attr.commercialNom]!['count']++;
      breakdown[attr.commercialNom]!['quantity'] += attr.quantiteAttribuee;
      breakdown[attr.commercialNom]!['value'] += attr.valeurTotale;
    }

    return ApiSavanaPdfService.createStyledTable(
      data: [
        ['Commercial', 'Attributions', 'Quantité', 'Valeur totale'],
        ...breakdown.entries
            .map((entry) => [
                  entry.key,
                  '${entry.value['count']}',
                  '${entry.value['quantity']}',
                  ApiSavanaPdfService.formatAmount(entry.value['value']),
                ])
            .toList(),
      ],
      columnWidths: [0.4, 0.2, 0.2, 0.2],
      hasHeader: true,
    );
  }
}
