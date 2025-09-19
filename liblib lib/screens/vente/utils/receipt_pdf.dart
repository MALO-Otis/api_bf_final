import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'apisavana_pdf_service.dart';
import '../models/vente_models.dart';
import 'package:pdf/widgets.dart' as pw;

/// Génère un PDF pour un reçu de vente avec l'en-tête ApiSavana.
Future<Uint8List> buildVenteReceiptPdf(Vente vente) async {
  final doc = pw.Document();
  final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
  final total = vente.montantTotal;
  final paye = vente.montantPaye;
  final reste = vente.montantRestant;

  // Section informations de la vente
  pw.Widget venteInfo() => ApiSavanaPdfService.buildSection(
        title: "INFORMATIONS DE LA VENTE",
        content: pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Commercial: ${vente.commercialNom}',
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'ID: ${vente.id}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Client: ${vente.clientNom.isEmpty ? 'Client Libre' : vente.clientNom}',
                style: const pw.TextStyle(fontSize: 11),
              ),
              if (vente.clientTelephone != null &&
                  vente.clientTelephone!.trim().isNotEmpty)
                pw.Text(
                  'Téléphone: ${vente.clientTelephone}',
                  style: const pw.TextStyle(fontSize: 11),
                ),
            ],
          ),
        ),
      );

  // Section produits vendus
  pw.Widget produitsSection() => ApiSavanaPdfService.buildSection(
        title: "DÉTAIL DES PRODUITS",
        content: ApiSavanaPdfService.createStyledTable(
          data: [
            ['Produit', 'Quantité', 'Prix Unit.', 'Total'],
            ...vente.produits
                .map((p) => [
                      p.typeEmballage,
                      p.quantiteVendue.toString(),
                      ApiSavanaPdfService.formatAmount(p.prixUnitaire),
                      ApiSavanaPdfService.formatAmount(p.montantTotal),
                    ])
                .toList(),
          ],
          columnWidths: [0.4, 0.15, 0.2, 0.25],
          hasHeader: true,
        ),
      );

  // Section totaux et paiement
  pw.Widget paimentSection() => ApiSavanaPdfService.buildSection(
        title: "RÉCAPITULATIF PAIEMENT",
        content: pw.Column(
          children: [
            ApiSavanaPdfService.createStyledTable(
              data: [
                ['Élément', 'Montant'],
                ['Montant Total', ApiSavanaPdfService.formatAmount(total)],
                ['Montant Payé', ApiSavanaPdfService.formatAmount(paye)],
                [
                  reste > 0 ? 'Crédit (reste)' : 'Solde',
                  reste > 0 ? ApiSavanaPdfService.formatAmount(reste) : '0 FCFA'
                ],
                ['Mode de Paiement', vente.modePaiement.name],
                ['Statut', vente.statut.name],
              ],
              columnWidths: [0.6, 0.4],
              hasHeader: true,
            ),
            if (vente.observations != null &&
                vente.observations!.trim().isNotEmpty) ...[
              pw.SizedBox(height: 12),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFFFF3CD),
                  border: pw.Border.all(color: PdfColor.fromInt(0xFFDDA520)),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Observations:',
                      style: pw.TextStyle(
                          fontSize: 11, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      vente.observations!,
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
            pw.SizedBox(height: 20),
            // Signature
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildSignatureBox('Commercial', vente.commercialNom),
                _buildSignatureBox('Client',
                    vente.clientNom.isEmpty ? 'Client Libre' : vente.clientNom),
              ],
            ),
          ],
        ),
      );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      header: (context) => ApiSavanaPdfService.buildHeader(
        documentTitle: "REÇU DE VENTE",
        documentNumber: vente.id,
        documentDate: vente.dateVente,
      ),
      footer: (context) => ApiSavanaPdfService.buildFooter(),
      build: (ctx) => [
        venteInfo(),
        produitsSection(),
        paimentSection(),
      ],
    ),
  );

  return doc.save();
}

// Méthode utilitaire pour les boîtes de signature
pw.Widget _buildSignatureBox(String title, String name) {
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
