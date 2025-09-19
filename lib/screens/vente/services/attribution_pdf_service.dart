import 'dart:io';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/commercial_models.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// 📄 SERVICE DE GÉNÉRATION PDF POUR ATTRIBUTIONS COMMERCIALES
///
/// Génère des rapports PDF détaillés et structurés pour chaque attribution
/// Avec header personnalisé, tableaux et informations complètes

class AttributionPDFService extends GetxService {
  /// Générer un rapport PDF d'attribution
  Future<Uint8List?> generateAttributionReport({
    required AttributionPartielle attribution,
    LotProduit? lot,
  }) async {
    try {
      final pdf = pw.Document();

      // Charger les images
      final headerImage = await _loadHeaderImage();

      // Créer les pages du PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return [
              // Header avec logo et infos entreprise
              _buildHeader(headerImage),

              pw.SizedBox(height: 20),

              // Titre du rapport
              _buildTitle(attribution),

              pw.SizedBox(height: 20),

              // Informations générales
              _buildGeneralInfo(attribution),

              pw.SizedBox(height: 20),

              // Détails du lot (si disponible)
              if (lot != null) ...[
                _buildLotDetails(lot),
                pw.SizedBox(height: 20),
              ],

              // Détails de l'attribution
              _buildAttributionDetails(attribution),

              pw.SizedBox(height: 20),

              // Résumé financier
              _buildFinancialSummary(attribution),

              pw.SizedBox(height: 30),

              // Signatures
              _buildSignatures(),
            ];
          },
          footer: (pw.Context context) {
            return _buildFooter(context);
          },
        ),
      );

      return pdf.save();
    } catch (e) {
      print('❌ Erreur génération PDF: $e');
      return null;
    }
  }

  /// Charger l'image du header
  Future<pw.ImageProvider?> _loadHeaderImage() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/head.jpg');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      print('⚠️ Impossible de charger l\'image header: $e');
      return null;
    }
  }

  /// Construire le header du PDF avec l'image complète
  pw.Widget _buildHeader(pw.ImageProvider? headerImage) {
    if (headerImage != null) {
      // Utiliser l'image complète comme header
      return pw.Container(
        width: double.infinity,
        height: 120, // Hauteur adaptée pour l'image
        decoration: pw.BoxDecoration(
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.ClipRRect(
          horizontalRadius: 8,
          verticalRadius: 8,
          child: pw.Image(
            headerImage,
            fit: pw.BoxFit.cover, // Couvre toute la largeur
            alignment: pw.Alignment.center,
          ),
        ),
      );
    } else {
      // Fallback si l'image n'est pas disponible
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'Groupement d\'Intérêt Economique APISAVANA',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Fourniture de matériels apicoles, construction et aménagement de miellerie',
              style: const pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
            pw.Text(
              'Formations, production, transformation et commercialisation des produits de la ruche',
              style: const pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
            pw.Text(
              'Consultation et recherche en apiculture, assistance technique et appui-conseil',
              style: const pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      );
    }
  }

  /// Construire le titre du rapport
  pw.Widget _buildTitle(AttributionPartielle attribution) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Center(
        child: pw.Text(
          'RAPPORT ATTRIBUTIONS',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
        ),
      ),
    );
  }

  /// Construire les informations générales
  pw.Widget _buildGeneralInfo(AttributionPartielle attribution) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PÉRIODE',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.brown,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(attribution.dateAttribution)}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'RÉSUMÉ',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.brown,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Commercial:', style: const pw.TextStyle(fontSize: 12)),
              pw.Text(
                attribution.commercialNom,
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Quantité attribuée:',
                  style: const pw.TextStyle(fontSize: 12)),
              pw.Text(
                '${attribution.quantiteAttribuee} unités',
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Valeur totale:',
                  style: const pw.TextStyle(fontSize: 12)),
              pw.Text(
                '${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(attribution.valeurTotale)}',
                style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construire les détails du lot
  pw.Widget _buildLotDetails(LotProduit lot) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DÉTAILS DU LOT',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 8),

          // Tableau des informations du lot
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              _buildTableRow('Numéro de lot', lot.numeroLot),
              _buildTableRow('Site d\'origine', lot.siteOrigine),
              _buildTableRow('Type d\'emballage', lot.typeEmballage),
              _buildTableRow('Prédominance florale', lot.predominanceFlorale),
              _buildTableRow(
                  'Quantité initiale', '${lot.quantiteInitiale} unités'),
              _buildTableRow(
                  'Quantité restante', '${lot.quantiteRestante} unités'),
              _buildTableRow('Prix unitaire',
                  '${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(lot.prixUnitaire)}'),
              _buildTableRow('Statut', lot.statut.toString().split('.').last),
            ],
          ),
        ],
      ),
    );
  }

  /// Construire une ligne de tableau
  pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ),
      ],
    );
  }

  /// Construire les détails de l'attribution
  pw.Widget _buildAttributionDetails(AttributionPartielle attribution) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        border: pw.Border.all(color: PdfColors.green200),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ATTRIBUTIONS TERMINÉES',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),
          pw.SizedBox(height: 8),

          // Informations détaillées
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              _buildTableRow('ID Attribution', attribution.id),
              _buildTableRow('Commercial', attribution.commercialNom),
              _buildTableRow('Gestionnaire', attribution.gestionnaire),
              _buildTableRow('Site', attribution.siteOrigine),
              _buildTableRow(
                  'Date d\'attribution',
                  DateFormat('dd/MM/yyyy à HH:mm')
                      .format(attribution.dateAttribution)),
              _buildTableRow(
                  'Quantité', '${attribution.quantiteAttribuee} unités'),
              _buildTableRow('Prix unitaire',
                  '${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(attribution.prixUnitaire)}'),
              _buildTableRow('Valeur totale',
                  '${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(attribution.valeurTotale)}'),
              if (attribution.motifModification != null &&
                  attribution.motifModification!.isNotEmpty)
                _buildTableRow('Motif', attribution.motifModification!),
            ],
          ),
        ],
      ),
    );
  }

  /// Construire le résumé financier
  pw.Widget _buildFinancialSummary(AttributionPartielle attribution) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange50,
        border: pw.Border.all(color: PdfColors.orange200, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'RÉSUMÉ FINANCIER',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.orange800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Quantité attribuée:',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('${attribution.quantiteAttribuee} unités',
                  style: const pw.TextStyle(fontSize: 14)),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Prix unitaire:',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text(
                  '${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(attribution.prixUnitaire)}',
                  style: const pw.TextStyle(fontSize: 14)),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Divider(color: PdfColors.orange300, thickness: 1),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('TOTAL:',
                  style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.orange800)),
              pw.Text(
                '${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(attribution.valeurTotale)}',
                style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construire les signatures
  pw.Widget _buildSignatures() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('Commercial',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 40),
            pw.Container(
              width: 150,
              height: 1,
              color: PdfColors.black,
            ),
            pw.SizedBox(height: 4),
            pw.Text('Signature', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('Gestionnaire',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 40),
            pw.Container(
              width: 150,
              height: 1,
              color: PdfColors.black,
            ),
            pw.SizedBox(height: 4),
            pw.Text('Signature', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ],
    );
  }

  /// Construire le footer
  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Divider(color: PdfColors.grey400),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'N°IFU: 00137379A RCCM N°BFKDG2020B150 - ORABANK BURKINA N°063564300201',
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.Text(
                'Page ${context.pageNumber}',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'BP 153 Koudougou - Tél: 00226 25441084/70240456',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
  }

  /// Télécharger le PDF
  Future<void> downloadPDF({
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    try {
      if (GetPlatform.isWeb) {
        // Sur web, utiliser le téléchargement automatique
        await _downloadWebPDF(pdfBytes, fileName);
      } else if (GetPlatform.isAndroid || GetPlatform.isIOS) {
        // Sur mobile, sauvegarder dans le dossier Downloads
        await _downloadMobilePDF(pdfBytes, fileName);
      } else {
        // Sur desktop, utiliser le dossier Downloads
        await _downloadDesktopPDF(pdfBytes, fileName);
      }
    } catch (e) {
      print('❌ Erreur téléchargement PDF: $e');
      rethrow;
    }
  }

  /// Téléchargement web
  Future<void> _downloadWebPDF(Uint8List pdfBytes, String fileName) async {
    // TODO: Implémenter le téléchargement web avec dart:html
    print('📱 Téléchargement web: $fileName');
  }

  /// Téléchargement mobile
  Future<void> _downloadMobilePDF(Uint8List pdfBytes, String fileName) async {
    // Demander les permissions
    await Permission.storage.request();

    // Obtenir le dossier Downloads
    Directory? downloadsDir;
    if (GetPlatform.isAndroid) {
      downloadsDir = Directory('/storage/emulated/0/Download');
    } else {
      downloadsDir = await getApplicationDocumentsDirectory();
    }

    // Créer le fichier
    final file = File('${downloadsDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);

    print('📱 PDF sauvegardé: ${file.path}');
  }

  /// Téléchargement desktop
  Future<void> _downloadDesktopPDF(Uint8List pdfBytes, String fileName) async {
    final downloadsDir = await getDownloadsDirectory();
    final file = File('${downloadsDir?.path ?? ''}/$fileName');
    await file.writeAsBytes(pdfBytes);

    print('💻 PDF sauvegardé: ${file.path}');
  }
}
