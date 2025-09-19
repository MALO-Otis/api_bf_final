import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

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

  /// Couleurs de l'entreprise
  static const PdfColor primaryColor = PdfColor.fromInt(0xFFF49101); // Orange
  static const PdfColor secondaryColor =
      PdfColor.fromInt(0xFF2D0C0D); // Marron foncé
  static const PdfColor accentColor =
      PdfColor.fromInt(0xFF8B4513); // Marron moyen

  // Cache mémoire pour le logo (bytes) afin d'éviter rechargements multiples.
  static Uint8List? _cachedLogoBytes;

  /// Définit (ou remplace) le logo à utiliser (bytes d'image). Vous pouvez charger
  /// les bytes dans le code Flutter via:
  /// final bytes = await rootBundle.load('assets/logo/logo.jpeg');
  /// ApiSavanaPdfService.setLogo(bytes.buffer.asUint8List());
  static void setLogo(Uint8List bytes) {
    _cachedLogoBytes = bytes;
  }

  // Ancienne méthode _buildLogoWidget supprimée (intégrée directement dans buildHeader)

  /// Crée l'en-tête standard ApiSavana
  static pw.Widget buildHeader({
    String? documentTitle,
    String? documentNumber,
    DateTime? documentDate,
    bool showLogo = true,
    String headerStyle = 'large', // 'large' ou 'compact'
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final bool isLarge = headerStyle == 'large';
    final double logoSize = isLarge ? 85 : 55;
    final double nameFont = isLarge ? 20 : 16;
    final double subtitleFont = isLarge ? 11 : 9.5;
    final double legalFont = isLarge ? 11 : 10;
    final double sectionSpacing = isLarge ? 12 : 8;

    return pw.Container(
      padding: pw.EdgeInsets.all(isLarge ? 24 : 16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: primaryColor, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Logo et nom de l'entreprise
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (showLogo && _cachedLogoBytes != null) ...[
                pw.Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(10),
                    border: pw.Border.all(color: primaryColor, width: 2),
                    boxShadow: [
                      pw.BoxShadow(
                        color: PdfColors.grey400,
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: pw.ClipRRect(
                    horizontalRadius: 10,
                    verticalRadius: 10,
                    child: pw.Image(
                      pw.MemoryImage(_cachedLogoBytes!),
                      fit: pw.BoxFit.cover,
                    ),
                  ),
                ),
                pw.SizedBox(width: 20),
              ] else ...[
                pw.Container(
                  width: logoSize,
                  height: logoSize,
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    gradient: pw.LinearGradient(colors: [
                      primaryColor,
                      PdfColor.fromInt(0xFFE57C00),
                    ]),
                    borderRadius: pw.BorderRadius.circular(10),
                    border: pw.Border.all(color: PdfColors.white, width: 1.2),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'APISAVANA',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: isLarge ? 12 : 9,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.5,
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
                        fontSize: nameFont,
                        fontWeight: pw.FontWeight.bold,
                        color: secondaryColor,
                        letterSpacing: 0.3,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: isLarge ? 6 : 3),
                    pw.Text(
                      _companySubtitle1,
                      style: pw.TextStyle(
                          fontSize: subtitleFont, color: secondaryColor),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      _companySubtitle2,
                      style: pw.TextStyle(
                          fontSize: subtitleFont, color: secondaryColor),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      _companySubtitle3,
                      style: pw.TextStyle(
                          fontSize: subtitleFont, color: secondaryColor),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: sectionSpacing),

          // Informations légales et contact
          pw.Container(
            padding: pw.EdgeInsets.symmetric(
              vertical: isLarge ? 10 : 6,
              horizontal: isLarge ? 16 : 10,
            ),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [
                  PdfColor.fromInt(0xFFFFF3E0),
                  PdfColor.fromInt(0xFFFFE0B2)
                ],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: primaryColor, width: 0.8),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  _companyIfu,
                  style: pw.TextStyle(
                      fontSize: legalFont, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
                pw.Text(
                  _companyBank,
                  style: pw.TextStyle(
                      fontSize: legalFont, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: isLarge ? 4 : 2),
                pw.Wrap(
                  alignment: pw.WrapAlignment.center,
                  spacing: 18,
                  runSpacing: 4,
                  children: [
                    pw.Text(
                      _companyAddress,
                      style: pw.TextStyle(
                          fontSize: legalFont - 0.5,
                          fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      _companyPhone,
                      style: pw.TextStyle(
                          fontSize: legalFont - 0.5,
                          fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Titre du document si fourni
          if (documentTitle != null) ...[
            pw.SizedBox(height: isLarge ? 18 : 12),
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
                  fontSize: isLarge ? 16 : 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          ],

          // Informations du document
          if (documentNumber != null || documentDate != null) ...[
            pw.SizedBox(height: isLarge ? 12 : 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                if (documentNumber != null)
                  pw.Text(
                    'N° $documentNumber',
                    style: pw.TextStyle(
                      fontSize: legalFont,
                      fontWeight: pw.FontWeight.bold,
                      color: secondaryColor,
                    ),
                  ),
                if (documentDate != null)
                  pw.Text(
                    'Date: ${dateFormat.format(documentDate)}',
                    style: pw.TextStyle(
                      fontSize: legalFont,
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
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page ${1}', // Sera mis à jour par le contexte
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
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
              color: primaryColor,
              borderRadius: pw.BorderRadius.circular(4),
            )
          : null,
      headerStyle: hasHeader
          ? pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 11,
            )
          : null,
      cellStyle: pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.center,
      cellPadding: const pw.EdgeInsets.all(6),
      border: pw.TableBorder.all(
        color: PdfColors.grey300,
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
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: pw.BoxDecoration(
            color: titleColor ?? accentColor,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
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
