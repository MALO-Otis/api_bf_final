import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;

/// NOTE: Pour utiliser le logo, assurez-vous que l'actif `assets/logo/logo.jpeg` existe.
/// Le chargement doit être initié côté Flutter (widgets) avec rootBundle, puis passé
/// aux générateurs si vous souhaitez un logo dynamique. Ici on fournit aussi une
/// fonction utilitaire de cache si vous importez ce service dans du code Flutter.

/// Service PDF commun pour tous les documents ApiSavana
/// Inclut l'en-tête officiel de l'entreprise
class ApiSavanaPdfService {
  static const String _companyName =
      "Groupement d'Intérêt Economique APISAVANA";
  static const String _companySubtitle1 =
      "Fourniture de matériels apicoles, construction et aménagement de miellerie";
  static const String _companySubtitle2 =
      "Formations, production, transformation et commercialisation des produits de la ruche";
  static const String _companySubtitle3 =
      "Consultation et recherche en apiculture, assistance technique et appui-conseil";
  static const String _companyIfu = "N°IFU: 00137379A RCCM N°BFKDG2020B150";
  static const String _companyBank = "ORABANK BURKINA N°063564300201";
  static const String _companyAddress = "BP 153 Koudougou";
  static const String _companyPhone = "Tél: 00226 25441084/70240456";

  /// Couleurs de l'entreprise - Version noir et blanc
  static const PdfColor primaryColor = PdfColors.black; // Noir
  static const PdfColor secondaryColor = PdfColors.black; // Noir
  static const PdfColor accentColor = PdfColors.black; // Noir

  static const PdfColor bodyTextColor = PdfColors.black;
  static const PdfColor bodyBackgroundColor = PdfColors.white;
  static const PdfColor bodyBorderColor = PdfColors.black;

  // Cache mémoire pour le logo (bytes) afin d'éviter rechargements multiples.
  static Uint8List? _cachedLogoBytes;

  /// Définit (ou remplace) le logo à utiliser (bytes d'image). Vous pouvez charger
  /// les bytes dans le code Flutter via:
  /// final bytes = await rootBundle.load('assets/logo/logo.jpeg');
  /// ApiSavanaPdfService.setLogo(bytes.buffer.asUint8List());
  static void setLogo(Uint8List bytes) {
    _cachedLogoBytes = bytes;
  }

  /// Charge le logo depuis assets/logo/logo.jpeg
  static Future<void> loadLogo() async {
    if (_cachedLogoBytes != null) return; // Déjà chargé

    try {
      // Charger le logo depuis assets/logo/logo.jpeg
      final byteData = await rootBundle.load('assets/logo/logo.jpeg');
      _cachedLogoBytes = byteData.buffer.asUint8List();
      print('✅ Logo APISAVANA chargé avec succès depuis assets/logo/logo.jpeg');
    } catch (e) {
      print('❌ Erreur chargement logo: $e');
      _cachedLogoBytes = null;
    }
  }

  /// Retourne un widget image PDF pour le logo APISAVANA avec taille optimisée.
  /// Le logo sera bien visible avec le texte APISAVANA lisible.
  /// Use `size` to control the width (height will keep image aspect ratio).
  static pw.Widget? _buildLogoWidget({double size = 100}) {
    if (_cachedLogoBytes == null) return null;
    return pw.Container(
      width: size,
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Image(
          pw.MemoryImage(_cachedLogoBytes!),
          fit: pw.BoxFit.contain,
          width: size,
        ),
      ),
    );
  }

  /// Crée l'en-tête standard ApiSavana
  static pw.Widget buildHeader({
    String? documentTitle,
    String? documentNumber,
    DateTime? documentDate,
    bool showLogo = true,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: primaryColor, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Logo APISAVANA bien visible en haut avec le nom de l'entreprise
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (showLogo && _buildLogoWidget() != null) ...[
                // Logo APISAVANA plus grand et bien visible
                _buildLogoWidget(size: 120)!,
                pw.SizedBox(width: 20),
              ] else ...[
                // Fallback si le logo ne charge pas
                pw.Container(
                  width: 120,
                  height: 80,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.black,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.black, width: 2),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'APISAVANA\nGESTION',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ),
                pw.SizedBox(width: 20),
              ],
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      _companyName,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: secondaryColor,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      _companySubtitle1,
                      style: pw.TextStyle(fontSize: 10, color: secondaryColor),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      _companySubtitle2,
                      style: pw.TextStyle(fontSize: 10, color: secondaryColor),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      _companySubtitle3,
                      style: pw.TextStyle(fontSize: 10, color: secondaryColor),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 10),

          // Informations légales et contact
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFFFF8DC), // Beige très clair
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  _companyIfu,
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
                pw.Text(
                  _companyBank,
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      _companyAddress,
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(width: 20),
                    pw.Text(
                      _companyPhone,
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Titre du document si fourni
          if (documentTitle != null) ...[
            pw.SizedBox(height: 15),
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: pw.BoxDecoration(
                color: primaryColor,
                borderRadius: pw.BorderRadius.circular(20),
              ),
              child: pw.Text(
                documentTitle.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          ],

          // Informations du document
          if (documentNumber != null || documentDate != null) ...[
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                if (documentNumber != null)
                  pw.Text(
                    'N° $documentNumber',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: secondaryColor,
                    ),
                  ),
                if (documentDate != null)
                  pw.Text(
                    'Date: ${dateFormat.format(documentDate)}',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: secondaryColor,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Crée le pied de page standard
  static pw.Widget buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: primaryColor, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Document généré automatiquement - ApiSavana',
            style: pw.TextStyle(fontSize: 8, color: bodyTextColor),
          ),
          pw.Text(
            'Page ${1}', // Sera mis à jour par le contexte
            style: pw.TextStyle(fontSize: 8, color: bodyTextColor),
          ),
        ],
      ),
    );
  }

  /// Style pour les tableaux
  static pw.Table createStyledTable({
    required List<List<String>> data,
    List<double>? columnWidths,
    bool hasHeader = true,
  }) {
    return pw.Table.fromTextArray(
      data: data,
      columnWidths: columnWidths != null
          ? Map.fromIterables(
              List.generate(columnWidths.length, (i) => i),
              columnWidths.map((w) => pw.FixedColumnWidth(w)),
            )
          : null,
      headerDecoration: hasHeader
          ? pw.BoxDecoration(
              color: bodyBackgroundColor,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border(
                bottom: pw.BorderSide(color: bodyBorderColor, width: 0.8),
              ),
            )
          : null,
      headerStyle: hasHeader
          ? pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: bodyTextColor,
              fontSize: 11,
            )
          : null,
      cellStyle: pw.TextStyle(fontSize: 10, color: bodyTextColor),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.center,
      cellPadding: const pw.EdgeInsets.all(6),
      border: pw.TableBorder.all(
        color: bodyBorderColor,
        width: 0.5,
      ),
    );
  }

  /// Crée une section avec titre
  static pw.Widget buildSection({
    required String title,
    required pw.Widget content,
    PdfColor? titleColor,
  }) {
    final double borderWidth = titleColor != null ? 1.2 : 0.8;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: pw.BoxDecoration(
            color: bodyBackgroundColor,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: bodyBorderColor, width: borderWidth),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: bodyTextColor,
            ),
          ),
        ),
        pw.SizedBox(height: 8),
        content,
        pw.SizedBox(height: 12),
      ],
    );
  }

  /// Formatte un montant en FCFA
  static String formatAmount(double amount) {
    final formatter = NumberFormat('#,##0', 'fr_FR');
    return '${formatter.format(amount)} FCFA';
  }

  /// Formatte une date
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'fr_FR').format(date);
  }

  /// Formatte une date avec heure
  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(date);
  }
}
