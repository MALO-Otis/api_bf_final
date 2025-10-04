import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/report_models.dart';
import 'map_service.dart';
import 'enhanced_pdf_service_stub.dart'
  if (dart.library.html) 'enhanced_pdf_service_web.dart'
  if (dart.library.io) 'enhanced_pdf_service_io.dart' as platform_service;

/// Service amélioré pour la génération de rapports PDF avec design parfait
/// et téléchargement multiplateforme (Desktop, Web, Mobile)
class EnhancedPdfService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Couleurs personnalisées
  static const PdfColor primaryColor = PdfColor.fromInt(0xFFF49101);
  static const PdfColor accentColor = PdfColor.fromInt(0xFF0066CC);
  static const PdfColor successColor = PdfColor.fromInt(0xFF28A745);
  static const PdfColor warningColor = PdfColor.fromInt(0xFFFFC107);
  static const PdfColor dangerColor = PdfColor.fromInt(0xFFDC3545);

  /// Génère un rapport statistiques avec design amélioré
  static Future<Uint8List> genererRapportStatistiquesAmeliore(
      RapportStatistiques rapport) async {
    try {
      final pdf = pw.Document();

      // Charger les polices personnalisées
      final fontRegular = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();
      final fontMedium = await PdfGoogleFonts.robotoMedium();

      // Pré-générer la carte de localisation
      final mapSection = await _buildLocationMapSection(
          rapport, fontBold, fontMedium, fontRegular);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          header: (context) =>
              _buildEnhancedHeader(rapport, fontBold, fontRegular),
          footer: (context) => _buildEnhancedFooter(context, fontRegular),
          build: (pw.Context context) => [
            // Informations générales avec design moderne
            _buildModernInfoSection(rapport, fontBold, fontMedium, fontRegular),
            pw.SizedBox(height: 20),

            // Tableau des contenants avec design parfait
            _buildPerfectTable(rapport, fontBold, fontMedium, fontRegular),
            pw.SizedBox(height: 20),

            // Statistiques avec graphiques visuels
            _buildVisualStatsSection(
                rapport, fontBold, fontMedium, fontRegular),
            pw.SizedBox(height: 20),

            // Graphiques de répartition
            _buildChartSection(rapport, fontBold, fontMedium, fontRegular),
            pw.SizedBox(height: 20),

            // Carte de localisation
            mapSection,
            pw.SizedBox(height: 20),

            // Analyse et recommandations
            _buildAnalysisSection(rapport, fontBold, fontMedium, fontRegular),
          ],
        ),
      );

      print('✅ PDF rapport statistiques amélioré généré');
      return await pdf.save();
    } catch (e) {
      print('❌ Erreur génération PDF amélioré: $e');
      rethrow;
    }
  }

  /// Génère un reçu de collecte avec design amélioré
  static Future<Uint8List> genererRecuCollecteAmeliore(
      RecuCollecte recu) async {
    try {
      final pdf = pw.Document();

      final fontRegular = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();
      final fontMedium = await PdfGoogleFonts.robotoMedium();

    final logoBytes = await _loadReceiptLogo();

      // Pré-générer la carte de localisation
      final mapSectionRecu = await _buildLocationMapSectionRecu(
          recu, fontBold, fontMedium, fontRegular);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête moderne avec logo
        _buildModernReceiptHeader(
          recu, fontBold, fontRegular, logoBytes),
              pw.SizedBox(height: 30),

              // Informations de collecte avec design cards
              _buildReceiptInfoCards(recu, fontBold, fontMedium, fontRegular),
              pw.SizedBox(height: 20),

              // Tableau détaillé avec couleurs
              _buildDetailedReceiptTable(
                  recu, fontBold, fontMedium, fontRegular),
              pw.SizedBox(height: 20),

              // Section totaux avec highlight
              _buildHighlightedTotals(recu, fontBold, fontMedium),
              pw.SizedBox(height: 30),

              // Message personnalisé
              _buildPersonalizedMessage(recu, fontMedium, fontRegular),
              pw.SizedBox(height: 30),

              // Carte de localisation
              mapSectionRecu,
              pw.SizedBox(height: 30),

              // Section signatures avec design moderne
              _buildModernSignatures(recu, fontRegular),
            ],
          ),
        ),
      );

      print('✅ PDF reçu collecte amélioré généré');
      return await pdf.save();
    } catch (e) {
      print('❌ Erreur génération PDF reçu amélioré: $e');
      rethrow;
    }
  }

  /// Télécharge le PDF selon la plateforme (Web, Desktop, Mobile)
  static Future<void> downloadPdf(
    Uint8List pdfBytes,
    String filename, {
    required String title,
    String? description,
  }) async {
    try {
      if (kIsWeb) {
        // Téléchargement pour Web
        await platform_service.downloadPdfWeb(pdfBytes, filename);
      } else {
        // Pour Desktop et Mobile, utiliser le service IO
        await platform_service.downloadPdfDesktop(pdfBytes, filename, title);
      }

      print('✅ PDF téléchargé avec succès: $filename');
    } catch (e) {
      print('❌ Erreur téléchargement PDF: $e');
      rethrow;
    }
  }

  /// Imprime le PDF directement
  static Future<void> printPdf(Uint8List pdfBytes, String title) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: title,
      );
      print('✅ PDF envoyé à l\'impression: $title');
    } catch (e) {
      print('❌ Erreur impression PDF: $e');
      rethrow;
    }
  }

  // ==================== MÉTHODES UTILITAIRES ====================

  /// Section carte de localisation pour rapport statistiques
  static Future<pw.Widget> _buildLocationMapSection(
    RapportStatistiques rapport,
    pw.Font fontBold,
    pw.Font fontMedium,
    pw.Font fontRegular,
  ) async {
    try {
      // Obtenir les coordonnées avec fallback sur Koudougou
      final coords = MapService.getCoordinatesWithFallback(
          rapport.collecte.geolocationData);

      print(
          '🗺️ PDF: Génération carte pour rapport - ${coords['description']}');

      // Générer l'image de carte
      final mapImageBytes = await MapService.genererCarteAvecLocalisation(
        latitude: coords['latitude'],
        longitude: coords['longitude'],
        accuracy: coords['accuracy'],
        width: 500,
        height: 300,
      );

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 4,
                height: 20,
                color: PdfColors.teal,
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'LOCALISATION SUR CARTE',
                style: pw.TextStyle(
                    font: fontBold, fontSize: 16, color: PdfColors.teal),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              children: [
                // Image de la carte
                if (mapImageBytes.isNotEmpty)
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColors.grey400),
                    ),
                    child: pw.Container(
                      width: 450,
                      height: 280,
                      child: pw.Image(
                        pw.MemoryImage(mapImageBytes),
                        width: 450,
                        height: 280,
                        fit: pw.BoxFit.cover,
                      ),
                    ),
                  ),
                pw.SizedBox(height: 12),
                // Informations de localisation
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: coords['isTest']
                        ? PdfColors.orange50
                        : PdfColors.green50,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(
                      color: coords['isTest']
                          ? PdfColors.orange200
                          : PdfColors.green200,
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        coords['isTest']
                            ? '⚠️ LOCALISATION DE TEST'
                            : '📍 LOCALISATION GPS',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 12,
                          color: coords['isTest']
                              ? PdfColors.orange800
                              : PdfColors.green800,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        coords['description'],
                        style: pw.TextStyle(font: fontMedium, fontSize: 11),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Coordonnées: ${coords['latitude'].toStringAsFixed(6)}, ${coords['longitude'].toStringAsFixed(6)}',
                        style: pw.TextStyle(font: fontRegular, fontSize: 10),
                      ),
                      if (coords['accuracy'] != null)
                        pw.Text(
                          'Précision: ±${coords['accuracy'].toStringAsFixed(1)} mètres',
                          style: pw.TextStyle(font: fontRegular, fontSize: 10),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } catch (e) {
      print('❌ PDF: Erreur génération section carte: $e');
      // Retourner une section d'erreur simple
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: PdfColors.red50,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.red200),
        ),
        child: pw.Text(
          'Carte non disponible - Vérifiez votre connexion internet',
          style: pw.TextStyle(
              font: fontRegular, fontSize: 12, color: PdfColors.red800),
        ),
      );
    }
  }

  /// Section carte de localisation pour reçu de collecte
  static Future<pw.Widget> _buildLocationMapSectionRecu(
    RecuCollecte recu,
    pw.Font fontBold,
    pw.Font fontMedium,
    pw.Font fontRegular,
  ) async {
    try {
      // Obtenir les coordonnées avec fallback sur Koudougou
      final coords =
          MapService.getCoordinatesWithFallback(recu.collecte.geolocationData);

      print('🗺️ PDF: Génération carte pour reçu - ${coords['description']}');

      // Générer l'image de carte
      final mapImageBytes = await MapService.genererCarteAvecLocalisation(
        latitude: coords['latitude'],
        longitude: coords['longitude'],
        accuracy: coords['accuracy'],
        width: 450,
        height: 250,
      );

      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(10),
            border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '🗺️ LOCALISATION DE LA COLLECTE',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 14,
                  color: PdfColors.black,
              ),
            ),
            pw.SizedBox(height: 12),
            // Image de la carte
            if (mapImageBytes.isNotEmpty)
              pw.Center(
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Container(
                    width: 400,
                    height: 230,
                    child: pw.Image(
                      pw.MemoryImage(mapImageBytes),
                      width: 400,
                      height: 230,
                      fit: pw.BoxFit.cover,
                    ),
                  ),
                ),
              ),
            pw.SizedBox(height: 12),
            // Informations
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      coords['isTest'] ? 'TYPE' : 'TYPE',
                      style: pw.TextStyle(font: fontBold, fontSize: 10),
                    ),
                    pw.Text(
                      coords['isTest'] ? 'Test (Koudougou)' : 'GPS Réel',
                      style: pw.TextStyle(font: fontRegular, fontSize: 10),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'LATITUDE',
                      style: pw.TextStyle(font: fontBold, fontSize: 10),
                    ),
                    pw.Text(
                      coords['latitude'].toStringAsFixed(6),
                      style: pw.TextStyle(font: fontRegular, fontSize: 10),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'LONGITUDE',
                      style: pw.TextStyle(font: fontBold, fontSize: 10),
                    ),
                    pw.Text(
                      coords['longitude'].toStringAsFixed(6),
                      style: pw.TextStyle(font: fontRegular, fontSize: 10),
                    ),
                  ],
                ),
                if (coords['accuracy'] != null)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PRÉCISION',
                        style: pw.TextStyle(font: fontBold, fontSize: 10),
                      ),
                      pw.Text(
                        '±${coords['accuracy'].toStringAsFixed(1)}m',
                        style: pw.TextStyle(font: fontRegular, fontSize: 10),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      );
    } catch (e) {
      print('❌ PDF: Erreur génération section carte reçu: $e');
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Text(
          '⚠️ Carte non disponible',
          style: pw.TextStyle(font: fontRegular, fontSize: 12),
        ),
      );
    }
  }

  // ==================== BUILDERS PDF AMÉLIORÉS ====================

  /// En-tête moderne avec gradient et logo
  static pw.Widget _buildEnhancedHeader(
    RapportStatistiques rapport,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    return pw.Container(
      width: double.infinity,
      height: 80,
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [primaryColor, accentColor],
          begin: pw.Alignment.centerLeft,
          end: pw.Alignment.centerRight,
        ),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(16),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'APISAVANA GESTION',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 20,
                    color: PdfColors.white,
                  ),
                ),
                pw.Text(
                  'Rapport Statistiques de Collecte',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 14,
                    color: PdfColors.white.shade(0.7),
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'N° ${rapport.numeroRapport}',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 16,
                    color: PdfColors.white,
                  ),
                ),
                pw.Text(
                  rapport.dateGenerationFormatee,
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 12,
                    color: PdfColors.white.shade(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Pied de page moderne
  static pw.Widget _buildEnhancedFooter(
    pw.Context context,
    pw.Font fontRegular,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'ApiSavana Gestion - Rapport confidentiel',
            style: pw.TextStyle(
                font: fontRegular, fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page ${context.pageNumber}/${context.pagesCount}',
            style: pw.TextStyle(
                font: fontRegular, fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  /// Section d'informations moderne avec cards
  static pw.Widget _buildModernInfoSection(
    RapportStatistiques rapport,
    pw.Font fontBold,
    pw.Font fontMedium,
    pw.Font fontRegular,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 4,
                height: 20,
                color: primaryColor,
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'INFORMATIONS GÉNÉRALES',
                style: pw.TextStyle(
                    font: fontBold, fontSize: 16, color: primaryColor),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoCard(
                  'Site de collecte',
                  rapport.collecte.site,
                  fontMedium,
                  fontRegular,
                  successColor,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _buildInfoCard(
                  'Type de collecte',
                  rapport.collecte.typeCollecte.label,
                  fontMedium,
                  fontRegular,
                  accentColor,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoCard(
                  'Date de collecte',
                  rapport.collecte.dateFormatee,
                  fontMedium,
                  fontRegular,
                  warningColor,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _buildInfoCard(
                  'Technicien',
                  rapport.collecte.technicienNom,
                  fontMedium,
                  fontRegular,
                  dangerColor,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          _buildInfoCard(
            'Localisation complète',
            rapport.collecte.localisationComplete,
            fontMedium,
            fontRegular,
            PdfColors.purple,
          ),
        ],
      ),
    );
  }

  /// Card d'information avec couleur
  static pw.Widget _buildInfoCard(
    String label,
    String value,
    pw.Font fontMedium,
    pw.Font fontRegular,
    PdfColor color,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: color.shade(0.3)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: fontMedium,
              fontSize: 10,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: fontRegular,
              fontSize: 12,
              color: PdfColors.grey800,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildReceiptInfoCard(
    String label,
    String value,
    pw.Font fontMedium,
    pw.Font fontRegular,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: fontMedium,
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: fontRegular,
              fontSize: 12,
              color: PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// Tableau parfait avec design moderne
  static pw.Widget _buildPerfectTable(
    RapportStatistiques rapport,
    pw.Font fontBold,
    pw.Font fontMedium,
    pw.Font fontRegular,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 4,
              height: 20,
              color: accentColor,
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              'DÉTAIL DES CONTENANTS',
              style: pw.TextStyle(
                  font: fontBold, fontSize: 16, color: accentColor),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Table(
            border: pw.TableBorder.all(color: PdfColors.white.shade(0)),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(2),
            },
            children: [
              // En-tête avec gradient
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  gradient: const pw.LinearGradient(
                    colors: [accentColor, primaryColor],
                    begin: pw.Alignment.centerLeft,
                    end: pw.Alignment.centerRight,
                  ),
                  borderRadius: const pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(8),
                    topRight: pw.Radius.circular(8),
                  ),
                ),
                children: [
                  _buildPerfectTableCell(
                      'Type de contenant', fontBold, 11, PdfColors.white, true),
                  _buildPerfectTableCell(
                      'Type de miel', fontBold, 11, PdfColors.white, true),
                  _buildPerfectTableCell(
                      'Poids (kg)', fontBold, 11, PdfColors.white, true),
                  _buildPerfectTableCell(
                      'Prix/kg (FCFA)', fontBold, 11, PdfColors.white, true),
                  _buildPerfectTableCell(
                      'Total (FCFA)', fontBold, 11, PdfColors.white, true),
                ],
              ),
              // Données avec alternance de couleurs
              ...rapport.collecte.contenants.asMap().entries.map((entry) {
                final index = entry.key;
                final contenant = entry.value;
                final isEven = index % 2 == 0;
                final bgColor = isEven ? PdfColors.grey50 : PdfColors.white;

                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: bgColor),
                  children: [
                    _buildPerfectTableCell(contenant.type, fontRegular, 10,
                        PdfColors.grey800, false),
                    _buildPerfectTableCell(contenant.typeMiel, fontRegular, 10,
                        PdfColors.grey800, false),
                    _buildPerfectTableCell(
                        contenant.quantite.toStringAsFixed(2),
                        fontMedium,
                        10,
                        successColor,
                        false),
                    _buildPerfectTableCell(
                        contenant.prixUnitaire.toStringAsFixed(0),
                        fontMedium,
                        10,
                        warningColor,
                        false),
                    _buildPerfectTableCell(
                        contenant.montantTotal.toStringAsFixed(0),
                        fontBold,
                        10,
                        dangerColor,
                        false),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  /// Cellule de tableau parfaite
  static pw.Widget _buildPerfectTableCell(
    String text,
    pw.Font font,
    double fontSize,
    PdfColor color,
    bool isHeader,
  ) {
    return pw.Container(
      padding: pw.EdgeInsets.all(isHeader ? 12 : 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: fontSize,
          color: color,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Section statistiques visuelles
  static pw.Widget _buildVisualStatsSection(
    RapportStatistiques rapport,
    pw.Font fontBold,
    pw.Font fontMedium,
    pw.Font fontRegular,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 4,
              height: 20,
              color: PdfColors.black,
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              'STATISTIQUES VISUELLES',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 16,
                color: PdfColors.black,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildStatCard(
                'Nombre de contenants',
                '${rapport.nombreContenants}',
                fontBold,
                fontMedium,
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: _buildStatCard(
                'Poids total collecté',
                rapport.collecte.poidsFormatte,
                fontBold,
                fontMedium,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildStatCard(
                'Montant total',
                rapport.collecte.montantFormatte,
                fontBold,
                fontMedium,
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: _buildStatCard(
                'Prix moyen/kg',
                rapport.prixMoyenFormatte,
                fontBold,
                fontMedium,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Card de statistique avec design moderne
  static pw.Widget _buildStatCard(
    String label,
    String value,
    pw.Font fontBold,
    pw.Font fontMedium,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: fontMedium,
              fontSize: 12,
              color: PdfColors.grey700,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 18,
              color: PdfColors.black,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Section graphiques et répartitions
  static pw.Widget _buildChartSection(
    RapportStatistiques rapport,
    pw.Font fontBold,
    pw.Font fontMedium,
    pw.Font fontRegular,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 4,
              height: 20,
              color: PdfColors.black,
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              'RÉPARTITIONS ET ANALYSES',
              style: pw.TextStyle(
                  font: fontBold, fontSize: 16, color: PdfColors.black),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: _buildRepartitionCard(
                'Répartition par type de contenant',
                rapport.repartitionParType,
                fontBold,
                fontMedium,
                fontRegular,
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: _buildRepartitionCard(
                'Répartition par type de miel (kg)',
                rapport.repartitionParMiel.map(
                    (key, value) => MapEntry(key, value.toStringAsFixed(2))),
                fontBold,
                fontMedium,
                fontRegular,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Card de répartition avec barres visuelles
  static pw.Widget _buildRepartitionCard(
    String title,
    Map<String, dynamic> data,
    pw.Font fontBold,
    pw.Font fontMedium,
    pw.Font fontRegular,
  ) {
    final total = data.values.fold<double>(0, (sum, value) {
      return sum + (value is num ? value.toDouble() : 0);
    });

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 12,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 8),
          ...data.entries.map((entry) {
            final value = entry.value is num ? entry.value.toDouble() : 0.0;
            final percentage = total > 0 ? (value / total * 100) : 0.0;

            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        entry.key,
                        style: pw.TextStyle(font: fontMedium, fontSize: 10),
                      ),
                      pw.Text(
                        '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                        style: pw.TextStyle(font: fontRegular, fontSize: 9),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 2),
                  pw.Container(
                    height: 4,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(2),
                    ),
                    child: pw.Container(
                      width: (percentage / 100) *
                          200, // Largeur fixe pour la barre
                      decoration: pw.BoxDecoration(
                        color: PdfColors.black,
                        borderRadius: pw.BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Section d'analyse et recommandations
  static pw.Widget _buildAnalysisSection(
    RapportStatistiques rapport,
    pw.Font fontBold,
    pw.Font fontMedium,
    pw.Font fontRegular,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: primaryColor.shade(0.3)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 4,
                height: 20,
                color: primaryColor,
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'ANALYSE ET RECOMMANDATIONS',
                style: pw.TextStyle(
                    font: fontBold, fontSize: 14, color: primaryColor),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            '• Rendement estimé: ${rapport.rendementFormatte}',
            style: pw.TextStyle(font: fontMedium, fontSize: 11),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '• Poids moyen par contenant: ${rapport.poidsMoyenFormatte}',
            style: pw.TextStyle(font: fontMedium, fontSize: 11),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '• Cette collecte représente ${rapport.nombreContenants} contenants pour un total de ${rapport.collecte.poidsFormatte}',
            style: pw.TextStyle(font: fontRegular, fontSize: 10),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Note: Ce rapport est généré automatiquement et reflète l\'état de la collecte au moment de sa génération.',
            style: pw.TextStyle(
                font: fontRegular, fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  // ==================== BUILDERS REÇU AMÉLIORÉ ====================

  /// En-tête moderne pour reçu
  static pw.Widget _buildModernReceiptHeader(
    RecuCollecte recu,
    pw.Font fontBold,
    pw.Font fontRegular,
    Uint8List? logoBytes,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoBytes != null)
                pw.Container(
                  width: 60,
                  height: 60,
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.grey400),
                  ),
                  child: pw.Center(
                    child: pw.Image(
                      pw.MemoryImage(logoBytes),
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                )
              else
                pw.Container(
                  width: 60,
                  height: 60,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'AS',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 18,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              pw.SizedBox(width: 16),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'APISAVANA GESTION',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 22,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'REÇU DE COLLECTE OFFICIEL',
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 14,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'N° ${recu.numeroRecu}',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 18,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                recu.dateGenerationFormatee,
                style: pw.TextStyle(
                  font: fontRegular,
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Cards d'informations pour reçu
  static pw.Widget _buildReceiptInfoCards(
    RecuCollecte recu,
    pw.Font fontBold,
    pw.Font fontMedium,
    pw.Font fontRegular,
  ) {
    return pw.Column(
      children: [
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildReceiptInfoCard(
                'Date de collecte',
                recu.collecte.dateFormatee,
                fontMedium,
                fontRegular,
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: _buildReceiptInfoCard(
                'Type de collecte',
                recu.collecte.typeCollecte.label,
                fontMedium,
                fontRegular,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildReceiptInfoCard(
                'Source/Producteur',
                recu.collecte.nomSource,
                fontMedium,
                fontRegular,
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: _buildReceiptInfoCard(
                'Technicien responsable',
                recu.collecte.technicienNom,
                fontMedium,
                fontRegular,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        _buildReceiptInfoCard(
          'Localisation complète',
          recu.collecte.localisationComplete,
          fontMedium,
          fontRegular,
        ),
      ],
    );
  }

  /// Tableau détaillé pour reçu
  static pw.Widget _buildDetailedReceiptTable(
    RecuCollecte recu,
    pw.Font fontBold,
    pw.Font fontMedium,
    pw.Font fontRegular,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Table(
        border: pw.TableBorder.all(color: PdfColors.white.shade(0)),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(1.5),
          3: const pw.FlexColumnWidth(1.5),
          4: const pw.FlexColumnWidth(2),
        },
        children: [
          // En-tête
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: PdfColors.black,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            children: [
              _buildPerfectTableCell(
                  'Type contenant', fontBold, 11, PdfColors.white, true),
              _buildPerfectTableCell(
                  'Type miel', fontBold, 11, PdfColors.white, true),
              _buildPerfectTableCell(
                  'Quantité (kg)', fontBold, 11, PdfColors.white, true),
              _buildPerfectTableCell(
                  'Prix unitaire', fontBold, 11, PdfColors.white, true),
              _buildPerfectTableCell(
                  'Montant (FCFA)', fontBold, 11, PdfColors.white, true),
            ],
          ),
          // Données
          ...recu.collecte.contenants.asMap().entries.map((entry) {
            final index = entry.key;
            final contenant = entry.value;
            final isEven = index % 2 == 0;
            final bgColor = isEven ? PdfColors.grey200 : PdfColors.white;

            return pw.TableRow(
              decoration: pw.BoxDecoration(color: bgColor),
              children: [
                _buildPerfectTableCell(
                    contenant.type, fontRegular, 10, PdfColors.grey800, false),
                _buildPerfectTableCell(contenant.typeMiel, fontRegular, 10,
                    PdfColors.grey800, false),
                _buildPerfectTableCell(contenant.quantite.toStringAsFixed(2),
                    fontMedium, 10, PdfColors.black, false),
                _buildPerfectTableCell(
                    contenant.prixUnitaire.toStringAsFixed(0),
                    fontMedium,
                    10,
                    PdfColors.black,
                    false),
                _buildPerfectTableCell(
                    contenant.montantTotal.toStringAsFixed(0),
                    fontBold,
                    10,
                    PdfColors.black,
                    false),
              ],
            );
          }),
        ],
      ),
    );
  }

  /// Totaux avec highlight
  static pw.Widget _buildHighlightedTotals(
    RecuCollecte recu,
    pw.Font fontBold,
    pw.Font fontMedium,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: [
          pw.Column(
            children: [
              pw.Text(
                'POIDS TOTAL',
                style: pw.TextStyle(
                  font: fontMedium,
                  fontSize: 14,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                recu.collecte.poidsFormatte,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 20,
                  color: PdfColors.black,
                ),
              ),
            ],
          ),
          pw.Container(
            width: 2,
            height: 40,
            color: PdfColors.grey300,
          ),
          pw.Column(
            children: [
              pw.Text(
                'MONTANT TOTAL',
                style: pw.TextStyle(
                  font: fontMedium,
                  fontSize: 14,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                recu.collecte.montantFormatte,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 20,
                  color: PdfColors.black,
                ),
              ),
            ],
          ),
          pw.Container(
            width: 2,
            height: 40,
            color: PdfColors.grey300,
          ),
          pw.Column(
            children: [
              pw.Text(
                'CONTENANTS',
                style: pw.TextStyle(
                  font: fontMedium,
                  fontSize: 14,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '${recu.collecte.contenants.length}',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 20,
                  color: PdfColors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Message personnalisé
  static pw.Widget _buildPersonalizedMessage(
    RecuCollecte recu,
    pw.Font fontMedium,
    pw.Font fontRegular,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            '🍯 MESSAGE DE REMERCIEMENT',
            style: pw.TextStyle(
              font: fontMedium,
              fontSize: 16,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            recu.messageRemerciement,
            style: pw.TextStyle(
              font: fontRegular,
              fontSize: 12,
              color: PdfColors.grey700,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Signatures modernes
  static pw.Widget _buildModernSignatures(
    RecuCollecte recu,
    pw.Font fontRegular,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
      children: [
        _buildSignatureBox('Signature du producteur/source', fontRegular),
        _buildSignatureBox('Signature du technicien', fontRegular),
      ],
    );
  }

  /// Box de signature
  static pw.Widget _buildSignatureBox(String title, pw.Font fontRegular) {
    return pw.Container(
      width: 200,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: fontRegular,
              fontSize: 11,
              color: PdfColors.grey700,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 40),
          pw.Container(
            width: double.infinity,
            height: 1,
            color: PdfColors.grey400,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Date et signature',
            style: pw.TextStyle(
              font: fontRegular,
              fontSize: 9,
              color: PdfColors.grey500,
            ),
          ),
        ],
      ),
    );
  }

  static Future<Uint8List?> _loadReceiptLogo() async {
    const candidatePaths = [
      'assets/logo/logo.jpeg',
      'assets/logo/logo.jpg',
      'assets/logo/logo.png',
      'assets/logo/logo.PNG',
      'assets/logo/apisavana_logo.jpg',
      'assets/logo/apisavana_logo.png',
    ];

    for (final path in candidatePaths) {
      try {
        final data = await rootBundle.load(path);
        print('🖼️ Logo reçu chargé: $path');
        return data.buffer.asUint8List();
      } catch (_) {
        // Continue jusqu'à trouver un logo valide.
      }
    }

    print('⚠️ Aucun logo trouvé pour le reçu amélioré.');
    return null;
  }

  /// Sauvegarde les métadonnées d'un rapport
  static Future<void> sauvegarderRapportMetadata(
    String site,
    String numeroRapport,
    TypeRapport typeRapport,
    String collecteId,
    TypeCollecteRapport typeCollecte,
  ) async {
    try {
      await _firestore
          .collection('Sites')
          .doc(site)
          .collection('rapports_generes')
          .doc(numeroRapport)
          .set({
        'numero_rapport': numeroRapport,
        'type_rapport': typeRapport.name,
        'type_collecte': typeCollecte.name,
        'collecte_id': collecteId,
        'site': site,
        'date_generation': FieldValue.serverTimestamp(),
        'statut': 'genere',
        'version': '2.0', // Version améliorée
      });
      print('✅ Métadonnées rapport sauvegardées: $numeroRapport');
    } catch (e) {
      print('❌ Erreur sauvegarde metadata rapport: $e');
    }
  }
}
