import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'apisavana_pdf_service.dart';
import '../models/vente_models.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/commercial_models.dart';

/// Générateur de rapports statistiques PDF pour les modules commercial
class StatisticsReportGenerator {
  /// Génère un rapport statistique pour les attributions (Gestion Commerciale)
  static Future<Uint8List> generateAttributionStatisticsReport({
    required List<AttributionPartielle> attributions,
    required DateTime periodeDebut,
    required DateTime periodeFin,
    String? siteFilter,
    String? commercialFilter,
  }) async {
    final pdf = pw.Document();

    // Calculs statistiques
    final stats = _calculateAttributionStats(attributions);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => ApiSavanaPdfService.buildHeader(
          documentTitle: "RAPPORT STATISTIQUE - ATTRIBUTIONS",
          documentDate: DateTime.now(),
        ),
        footer: (context) => ApiSavanaPdfService.buildFooter(),
        build: (context) => [
          // Période et filtres
          ApiSavanaPdfService.buildSection(
            title: "PARAMÈTRES DU RAPPORT",
            content: pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFE3F2FD),
                border: pw.Border.all(color: PdfColors.blue300),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Période: ${ApiSavanaPdfService.formatDate(periodeDebut)} - ${ApiSavanaPdfService.formatDate(periodeFin)}',
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                  if (siteFilter != null)
                    pw.Text('Site: $siteFilter',
                        style: const pw.TextStyle(fontSize: 11)),
                  if (commercialFilter != null)
                    pw.Text('Commercial: $commercialFilter',
                        style: const pw.TextStyle(fontSize: 11)),
                  pw.Text(
                    'Généré le: ${ApiSavanaPdfService.formatDateTime(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
          ),

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
                      _buildMetricCard('Total Attributions',
                          '${stats.totalAttributions}', PdfColors.blue),
                      _buildMetricCard('Lots Concernés',
                          '${stats.nombreLotsUniques}', PdfColors.green),
                      _buildMetricCard('Commerciaux Actifs',
                          '${stats.nombreCommerciaux}', PdfColors.orange),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricCard('Quantité Totale',
                          '${stats.quantiteTotale}', PdfColors.purple),
                      _buildMetricCard(
                          'Valeur Moyenne',
                          '${stats.valeurMoyenne.toStringAsFixed(0)} FCFA',
                          PdfColors.indigo),
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
                      'Valeur Totale: ${ApiSavanaPdfService.formatAmount(stats.valeurTotale)}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Répartition par commercial
          if (stats.repartitionCommercial.isNotEmpty)
            ApiSavanaPdfService.buildSection(
              title: "RÉPARTITION PAR COMMERCIAL",
              content: ApiSavanaPdfService.createStyledTable(
                data: [
                  ['Commercial', 'Attributions', 'Quantité', 'Valeur', '%'],
                  ...stats.repartitionCommercial.entries.map((entry) {
                    final pourcentage =
                        (entry.value['value'] / stats.valeurTotale * 100)
                            .toStringAsFixed(1);
                    return [
                      entry.key,
                      '${entry.value['count']}',
                      '${entry.value['quantity']}',
                      '${(entry.value['value'] as double).toStringAsFixed(0)}',
                      '$pourcentage%',
                    ];
                  }).toList(),
                ],
                columnWidths: [0.3, 0.15, 0.15, 0.2, 0.2],
                hasHeader: true,
              ),
            ),

          // Répartition par site
          if (stats.repartitionSite.isNotEmpty)
            ApiSavanaPdfService.buildSection(
              title: "RÉPARTITION PAR SITE",
              content: ApiSavanaPdfService.createStyledTable(
                data: [
                  ['Site', 'Attributions', 'Quantité', 'Valeur', '%'],
                  ...stats.repartitionSite.entries.map((entry) {
                    final pourcentage =
                        (entry.value['value'] / stats.valeurTotale * 100)
                            .toStringAsFixed(1);
                    return [
                      entry.key,
                      '${entry.value['count']}',
                      '${entry.value['quantity']}',
                      '${(entry.value['value'] as double).toStringAsFixed(0)}',
                      '$pourcentage%',
                    ];
                  }).toList(),
                ],
                columnWidths: [0.3, 0.15, 0.15, 0.2, 0.2],
                hasHeader: true,
              ),
            ),

          // Top 10 des lots les plus attribués
          if (stats.topLots.isNotEmpty)
            ApiSavanaPdfService.buildSection(
              title: "TOP 10 - LOTS LES PLUS ATTRIBUÉS",
              content: ApiSavanaPdfService.createStyledTable(
                data: [
                  ['N° Lot', 'Type', 'Attributions', 'Quantité', 'Valeur'],
                  ...stats.topLots
                      .take(10)
                      .map((lot) => [
                            lot['numeroLot'] as String,
                            lot['typeEmballage'] as String,
                            '${lot['count']}',
                            '${lot['quantity']}',
                            '${(lot['value'] as double).toStringAsFixed(0)}',
                          ])
                      .toList(),
                ],
                columnWidths: [0.2, 0.2, 0.15, 0.15, 0.3],
                hasHeader: true,
              ),
            ),

          // Évolution mensuelle
          if (stats.evolutionMensuelle.isNotEmpty)
            ApiSavanaPdfService.buildSection(
              title: "ÉVOLUTION MENSUELLE",
              content: ApiSavanaPdfService.createStyledTable(
                data: [
                  ['Mois', 'Attributions', 'Quantité', 'Valeur'],
                  ...stats.evolutionMensuelle.entries
                      .map((entry) => [
                            entry.key,
                            '${entry.value['count']}',
                            '${entry.value['quantity']}',
                            '${(entry.value['value'] as double).toStringAsFixed(0)}',
                          ])
                      .toList(),
                ],
                columnWidths: [0.25, 0.25, 0.25, 0.25],
                hasHeader: true,
              ),
            ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Génère un rapport statistique pour les ventes (Espace Commercial)
  static Future<Uint8List> generateVenteStatisticsReport({
    required List<Vente> ventes,
    required DateTime periodeDebut,
    required DateTime periodeFin,
    String? siteFilter,
    String? commercialFilter,
  }) async {
    final pdf = pw.Document();

    // Calculs statistiques
    final stats = _calculateVenteStats(ventes);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => ApiSavanaPdfService.buildHeader(
          documentTitle: "RAPPORT STATISTIQUE - VENTES",
          documentDate: DateTime.now(),
        ),
        footer: (context) => ApiSavanaPdfService.buildFooter(),
        build: (context) => [
          // Période et filtres
          ApiSavanaPdfService.buildSection(
            title: "PARAMÈTRES DU RAPPORT",
            content: pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFE8F5E8),
                border: pw.Border.all(color: PdfColors.green300),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Période: ${ApiSavanaPdfService.formatDate(periodeDebut)} - ${ApiSavanaPdfService.formatDate(periodeFin)}',
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                  if (siteFilter != null)
                    pw.Text('Site: $siteFilter',
                        style: const pw.TextStyle(fontSize: 11)),
                  if (commercialFilter != null)
                    pw.Text('Commercial: $commercialFilter',
                        style: const pw.TextStyle(fontSize: 11)),
                  pw.Text(
                    'Généré le: ${ApiSavanaPdfService.formatDateTime(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
          ),

          // Résumé exécutif ventes
          ApiSavanaPdfService.buildSection(
            title: "RÉSUMÉ EXÉCUTIF",
            content: pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF8F9FA),
                border: pw.Border.all(color: PdfColors.green, width: 2),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricCard('Total Ventes', '${stats.totalVentes}',
                          PdfColors.green),
                      _buildMetricCard('Clients Uniques',
                          '${stats.nombreClientsUniques}', PdfColors.blue),
                      _buildMetricCard('Commerciaux Actifs',
                          '${stats.nombreCommerciaux}', PdfColors.orange),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricCard(
                          'Panier Moyen',
                          '${stats.panierMoyen.toStringAsFixed(0)} FCFA',
                          PdfColors.purple),
                      _buildMetricCard(
                          'Taux Crédit',
                          '${stats.tauxCredit.toStringAsFixed(1)}%',
                          stats.tauxCredit > 20
                              ? PdfColors.red
                              : PdfColors.green),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green,
                          borderRadius: pw.BorderRadius.circular(20),
                        ),
                        child: pw.Text(
                          'CA Total: ${ApiSavanaPdfService.formatAmount(stats.chiffreAffaires)}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: stats.totalCredits > 0
                              ? PdfColors.orange
                              : PdfColors.green,
                          borderRadius: pw.BorderRadius.circular(20),
                        ),
                        child: pw.Text(
                          'Crédits: ${ApiSavanaPdfService.formatAmount(stats.totalCredits)}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Répartition par commercial ventes
          if (stats.repartitionCommercial.isNotEmpty)
            ApiSavanaPdfService.buildSection(
              title: "PERFORMANCE PAR COMMERCIAL",
              content: ApiSavanaPdfService.createStyledTable(
                data: [
                  ['Commercial', 'Ventes', 'CA', 'Panier Moy.', '% CA'],
                  ...stats.repartitionCommercial.entries.map((entry) {
                    final ca = entry.value['ca'] as double;
                    final ventes = entry.value['ventes'] as int;
                    final panierMoy = ventes > 0 ? ca / ventes : 0;
                    final pourcentageCA =
                        (ca / stats.chiffreAffaires * 100).toStringAsFixed(1);
                    return [
                      entry.key,
                      '$ventes',
                      '${ca.toStringAsFixed(0)}',
                      '${panierMoy.toStringAsFixed(0)}',
                      '$pourcentageCA%',
                    ];
                  }).toList(),
                ],
                columnWidths: [0.3, 0.15, 0.25, 0.15, 0.15],
                hasHeader: true,
              ),
            ),

          // Top produits
          if (stats.topProduits.isNotEmpty)
            ApiSavanaPdfService.buildSection(
              title: "TOP 10 - PRODUITS LES PLUS VENDUS",
              content: ApiSavanaPdfService.createStyledTable(
                data: [
                  ['Produit', 'Quantité', 'CA', '% CA'],
                  ...stats.topProduits.take(10).map((produit) {
                    final pourcentage =
                        (produit['ca'] / stats.chiffreAffaires * 100)
                            .toStringAsFixed(1);
                    return [
                      produit['nom'] as String,
                      '${produit['quantite']}',
                      '${(produit['ca'] as double).toStringAsFixed(0)}',
                      '$pourcentage%',
                    ];
                  }).toList(),
                ],
                columnWidths: [0.4, 0.2, 0.25, 0.15],
                hasHeader: true,
              ),
            ),
        ],
      ),
    );

    return pdf.save();
  }

  // Méthodes utilitaires pour les calculs statistiques

  static AttributionStats _calculateAttributionStats(
      List<AttributionPartielle> attributions) {
    final repartitionCommercial = <String, Map<String, dynamic>>{};
    final repartitionSite = <String, Map<String, dynamic>>{};
    final evolutionMensuelle = <String, Map<String, dynamic>>{};
    final lotStats = <String, Map<String, dynamic>>{};

    double valeurTotale = 0;
    int quantiteTotale = 0;
    final commerciauxUniques = <String>{};
    final lotsUniques = <String>{};

    for (final attr in attributions) {
      // Totaux
      valeurTotale += attr.valeurTotale;
      quantiteTotale += attr.quantiteAttribuee;
      commerciauxUniques.add(attr.commercialNom);
      lotsUniques.add(attr.lotId);

      // Répartition par commercial
      repartitionCommercial.putIfAbsent(
          attr.commercialNom,
          () => {
                'count': 0,
                'quantity': 0,
                'value': 0.0,
              });
      repartitionCommercial[attr.commercialNom]!['count']++;
      repartitionCommercial[attr.commercialNom]!['quantity'] +=
          attr.quantiteAttribuee;
      repartitionCommercial[attr.commercialNom]!['value'] += attr.valeurTotale;

      // Répartition par site
      repartitionSite.putIfAbsent(
          attr.siteOrigine,
          () => {
                'count': 0,
                'quantity': 0,
                'value': 0.0,
              });
      repartitionSite[attr.siteOrigine]!['count']++;
      repartitionSite[attr.siteOrigine]!['quantity'] += attr.quantiteAttribuee;
      repartitionSite[attr.siteOrigine]!['value'] += attr.valeurTotale;

      // Évolution mensuelle
      final moisCle =
          '${attr.dateAttribution.year}-${attr.dateAttribution.month.toString().padLeft(2, '0')}';
      evolutionMensuelle.putIfAbsent(
          moisCle,
          () => {
                'count': 0,
                'quantity': 0,
                'value': 0.0,
              });
      evolutionMensuelle[moisCle]!['count']++;
      evolutionMensuelle[moisCle]!['quantity'] += attr.quantiteAttribuee;
      evolutionMensuelle[moisCle]!['value'] += attr.valeurTotale;

      // Stats par lot
      lotStats.putIfAbsent(
          attr.numeroLot,
          () => {
                'count': 0,
                'quantity': 0,
                'value': 0.0,
                'typeEmballage': attr.typeEmballage,
                'numeroLot': attr.numeroLot,
              });
      lotStats[attr.numeroLot]!['count']++;
      lotStats[attr.numeroLot]!['quantity'] += attr.quantiteAttribuee;
      lotStats[attr.numeroLot]!['value'] += attr.valeurTotale;
    }

    final topLots = lotStats.values.toList()
      ..sort((a, b) => (b['value'] as double).compareTo(a['value'] as double));

    return AttributionStats(
      totalAttributions: attributions.length,
      nombreLotsUniques: lotsUniques.length,
      nombreCommerciaux: commerciauxUniques.length,
      quantiteTotale: quantiteTotale,
      valeurTotale: valeurTotale,
      valeurMoyenne:
          attributions.isNotEmpty ? valeurTotale / attributions.length : 0,
      repartitionCommercial: repartitionCommercial,
      repartitionSite: repartitionSite,
      evolutionMensuelle: evolutionMensuelle,
      topLots: topLots,
    );
  }

  static VenteStats _calculateVenteStats(List<Vente> ventes) {
    final repartitionCommercial = <String, Map<String, dynamic>>{};
    final produitStats = <String, Map<String, dynamic>>{};

    double chiffreAffaires = 0;
    double totalCredits = 0;
    final commerciauxUniques = <String>{};
    final clientsUniques = <String>{};

    for (final vente in ventes) {
      chiffreAffaires += vente.montantTotal;
      totalCredits += vente.montantRestant;
      commerciauxUniques.add(vente.commercialNom);
      if (vente.clientNom.isNotEmpty) {
        clientsUniques.add(vente.clientNom);
      }

      // Répartition par commercial
      repartitionCommercial.putIfAbsent(
          vente.commercialNom,
          () => {
                'ventes': 0,
                'ca': 0.0,
              });
      repartitionCommercial[vente.commercialNom]!['ventes']++;
      repartitionCommercial[vente.commercialNom]!['ca'] += vente.montantTotal;

      // Stats produits
      for (final produit in vente.produits) {
        produitStats.putIfAbsent(
            produit.typeEmballage,
            () => {
                  'quantite': 0,
                  'ca': 0.0,
                  'nom': produit.typeEmballage,
                });
        produitStats[produit.typeEmballage]!['quantite'] +=
            produit.quantiteVendue;
        produitStats[produit.typeEmballage]!['ca'] += produit.montantTotal;
      }
    }

    final topProduits = produitStats.values.toList()
      ..sort((a, b) => (b['ca'] as double).compareTo(a['ca'] as double));

    return VenteStats(
      totalVentes: ventes.length,
      nombreClientsUniques: clientsUniques.length,
      nombreCommerciaux: commerciauxUniques.length,
      chiffreAffaires: chiffreAffaires,
      totalCredits: totalCredits,
      panierMoyen: ventes.isNotEmpty ? chiffreAffaires / ventes.length : 0,
      tauxCredit:
          chiffreAffaires > 0 ? (totalCredits / chiffreAffaires * 100) : 0,
      repartitionCommercial: repartitionCommercial,
      topProduits: topProduits,
    );
  }

  static pw.Widget _buildMetricCard(
      String title, String value, PdfColor color) {
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
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 9, color: color),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Classes pour les statistiques
class AttributionStats {
  final int totalAttributions;
  final int nombreLotsUniques;
  final int nombreCommerciaux;
  final int quantiteTotale;
  final double valeurTotale;
  final double valeurMoyenne;
  final Map<String, Map<String, dynamic>> repartitionCommercial;
  final Map<String, Map<String, dynamic>> repartitionSite;
  final Map<String, Map<String, dynamic>> evolutionMensuelle;
  final List<Map<String, dynamic>> topLots;

  AttributionStats({
    required this.totalAttributions,
    required this.nombreLotsUniques,
    required this.nombreCommerciaux,
    required this.quantiteTotale,
    required this.valeurTotale,
    required this.valeurMoyenne,
    required this.repartitionCommercial,
    required this.repartitionSite,
    required this.evolutionMensuelle,
    required this.topLots,
  });
}

class VenteStats {
  final int totalVentes;
  final int nombreClientsUniques;
  final int nombreCommerciaux;
  final double chiffreAffaires;
  final double totalCredits;
  final double panierMoyen;
  final double tauxCredit;
  final Map<String, Map<String, dynamic>> repartitionCommercial;
  final List<Map<String, dynamic>> topProduits;

  VenteStats({
    required this.totalVentes,
    required this.nombreClientsUniques,
    required this.nombreCommerciaux,
    required this.chiffreAffaires,
    required this.totalCredits,
    required this.panierMoyen,
    required this.tauxCredit,
    required this.repartitionCommercial,
    required this.topProduits,
  });
}
