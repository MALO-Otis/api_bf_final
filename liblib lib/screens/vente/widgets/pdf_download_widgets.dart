import 'dart:html' as html;
import 'package:get/get.dart';
import '../utils/receipt_pdf.dart';
import '../models/vente_models.dart';
import 'package:flutter/material.dart';
import '../models/commercial_models.dart';
import '../utils/attribution_pdf_generator.dart';
import '../utils/statistics_report_generator.dart';

/// Widget pour les boutons de téléchargement PDF
class PdfDownloadButtons extends StatelessWidget {
  const PdfDownloadButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.picture_as_pdf, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 8),
          Text(
            'Export PDF',
            style: TextStyle(
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bouton PDF pour une attribution individuelle
class AttributionPdfButton extends StatelessWidget {
  final AttributionPartielle attribution;
  final bool isIconOnly;

  const AttributionPdfButton({
    super.key,
    required this.attribution,
    this.isIconOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Télécharger le reçu PDF',
      child: isIconOnly
          ? IconButton(
              onPressed: () => _downloadAttributionPdf(),
              icon: Icon(
                Icons.picture_as_pdf,
                color: Colors.orange.shade700,
                size: 20,
              ),
            )
          : ElevatedButton.icon(
              onPressed: () => _downloadAttributionPdf(),
              icon: const Icon(Icons.picture_as_pdf, size: 16),
              label: const Text('PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade100,
                foregroundColor: Colors.orange.shade700,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(0, 32),
              ),
            ),
    );
  }

  Future<void> _downloadAttributionPdf() async {
    try {
      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Génération du PDF...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final pdfBytes =
          await AttributionPdfGenerator.generateAttributionPdf(attribution);

      Get.back(); // Fermer le dialog de chargement

      // Télécharger le fichier
      final blob = html.Blob([pdfBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement;
      anchor.href = url;
      anchor.download =
          'Attribution_${attribution.numeroLot}_${attribution.commercialNom.replaceAll(' ', '_')}.pdf';
      anchor.click();
      html.Url.revokeObjectUrl(url);

      Get.snackbar(
        'Succès',
        'PDF téléchargé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      Get.back(); // Fermer le dialog de chargement si ouvert
      Get.snackbar(
        'Erreur',
        'Impossible de générer le PDF: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }
  }
}

/// Bouton PDF pour un reçu de vente
class VentePdfButton extends StatelessWidget {
  final Vente vente;
  final bool isIconOnly;

  const VentePdfButton({
    super.key,
    required this.vente,
    this.isIconOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Télécharger le reçu PDF',
      child: isIconOnly
          ? IconButton(
              onPressed: () => _downloadVentePdf(),
              icon: Icon(
                Icons.receipt_long,
                color: Colors.green.shade700,
                size: 20,
              ),
            )
          : ElevatedButton.icon(
              onPressed: () => _downloadVentePdf(),
              icon: const Icon(Icons.receipt_long, size: 16),
              label: const Text('Reçu PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade100,
                foregroundColor: Colors.green.shade700,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(0, 32),
              ),
            ),
    );
  }

  Future<void> _downloadVentePdf() async {
    try {
      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Génération du reçu PDF...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final pdfBytes = await buildVenteReceiptPdf(vente);

      Get.back(); // Fermer le dialog de chargement

      // Télécharger le fichier
      final blob = html.Blob([pdfBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement;
      anchor.href = url;
      anchor.download =
          'Recu_Vente_${vente.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      anchor.click();
      html.Url.revokeObjectUrl(url);

      Get.snackbar(
        'Succès',
        'Reçu PDF téléchargé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      Get.back(); // Fermer le dialog de chargement si ouvert
      Get.snackbar(
        'Erreur',
        'Impossible de générer le reçu PDF: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }
  }
}

/// Bouton pour générer un rapport statistique sur les attributions
class AttributionStatsPdfButton extends StatelessWidget {
  final List<AttributionPartielle> attributions;
  final String titre;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String? commercialFilter;
  final String? siteFilter;

  const AttributionStatsPdfButton({
    super.key,
    required this.attributions,
    required this.titre,
    this.dateDebut,
    this.dateFin,
    this.commercialFilter,
    this.siteFilter,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: attributions.isEmpty ? null : () => _downloadStatsPdf(),
      icon: const Icon(Icons.analytics, size: 16),
      label: const Text('Rapport PDF'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade100,
        foregroundColor: Colors.blue.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Future<void> _downloadStatsPdf() async {
    try {
      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Génération du rapport...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final pdfBytes =
          await StatisticsReportGenerator.generateAttributionStatisticsReport(
        attributions: attributions,
        periodeDebut:
            dateDebut ?? DateTime.now().subtract(const Duration(days: 30)),
        periodeFin: dateFin ?? DateTime.now(),
        commercialFilter: commercialFilter,
        siteFilter: siteFilter,
      );

      Get.back(); // Fermer le dialog de chargement

      // Télécharger le fichier
      final blob = html.Blob([pdfBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement;
      anchor.href = url;
      anchor.download =
          'Rapport_Attributions_${DateTime.now().millisecondsSinceEpoch}.pdf';
      anchor.click();
      html.Url.revokeObjectUrl(url);

      Get.snackbar(
        'Succès',
        'Rapport PDF téléchargé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      Get.back(); // Fermer le dialog de chargement si ouvert
      Get.snackbar(
        'Erreur',
        'Impossible de générer le rapport PDF: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }
  }
}

/// Bouton pour générer un rapport statistique sur les ventes
class VenteStatsPdfButton extends StatelessWidget {
  final List<Vente> ventes;
  final String titre;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String? commercialFilter;
  final String? siteFilter;

  const VenteStatsPdfButton({
    super.key,
    required this.ventes,
    required this.titre,
    this.dateDebut,
    this.dateFin,
    this.commercialFilter,
    this.siteFilter,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: ventes.isEmpty ? null : () => _downloadStatsPdf(),
      icon: const Icon(Icons.bar_chart, size: 16),
      label: const Text('Rapport PDF'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple.shade100,
        foregroundColor: Colors.purple.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Future<void> _downloadStatsPdf() async {
    try {
      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Génération du rapport de ventes...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final pdfBytes =
          await StatisticsReportGenerator.generateVenteStatisticsReport(
        ventes: ventes,
        periodeDebut:
            dateDebut ?? DateTime.now().subtract(const Duration(days: 30)),
        periodeFin: dateFin ?? DateTime.now(),
        commercialFilter: commercialFilter,
        siteFilter: siteFilter,
      );

      Get.back(); // Fermer le dialog de chargement

      // Télécharger le fichier
      final blob = html.Blob([pdfBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement;
      anchor.href = url;
      anchor.download =
          'Rapport_Ventes_${DateTime.now().millisecondsSinceEpoch}.pdf';
      anchor.click();
      html.Url.revokeObjectUrl(url);

      Get.snackbar(
        'Succès',
        'Rapport de ventes PDF téléchargé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.purple,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      Get.back(); // Fermer le dialog de chargement si ouvert
      Get.snackbar(
        'Erreur',
        'Impossible de générer le rapport PDF: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }
  }
}

/// Bouton pour télécharger plusieurs attributions en un seul PDF
class MultipleAttributionsPdfButton extends StatelessWidget {
  final List<AttributionPartielle> attributions;
  final String titre;

  const MultipleAttributionsPdfButton({
    super.key,
    required this.attributions,
    required this.titre,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: attributions.isEmpty ? null : () => _downloadMultiplePdf(),
      icon: const Icon(Icons.picture_as_pdf, size: 16),
      label: Text('PDF Groupé (${attributions.length})'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber.shade100,
        foregroundColor: Colors.amber.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Future<void> _downloadMultiplePdf() async {
    try {
      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Génération du PDF groupé...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final pdfBytes =
          await AttributionPdfGenerator.generateMultipleAttributionsPdf(
        attributions: attributions,
        titre: titre,
      );

      Get.back(); // Fermer le dialog de chargement

      // Télécharger le fichier
      final blob = html.Blob([pdfBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement;
      anchor.href = url;
      anchor.download =
          'Attributions_Groupees_${DateTime.now().millisecondsSinceEpoch}.pdf';
      anchor.click();
      html.Url.revokeObjectUrl(url);

      Get.snackbar(
        'Succès',
        'PDF groupé téléchargé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.amber,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      Get.back(); // Fermer le dialog de chargement si ouvert
      Get.snackbar(
        'Erreur',
        'Impossible de générer le PDF groupé: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }
  }
}
