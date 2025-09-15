import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import '../models/vente_models.dart';
import 'package:pdf/widgets.dart' as pw;

/// Génère un PDF pour un reçu de vente.
Future<Uint8List> buildVenteReceiptPdf(Vente vente) async {
  final doc = pw.Document();
  final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
  final total = vente.montantTotal;
  final paye = vente.montantPaye;
  final reste = vente.montantRestant;

  pw.Widget header() => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
              'REÇU DE VENTE • ${vente.id} • ${dateFmt.format(vente.dateVente)}',
              style:
                  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Date: ${dateFmt.format(vente.dateVente)}',
              style: const pw.TextStyle(fontSize: 10)),
          pw.Text('ID Vente: ${vente.id}',
              style: const pw.TextStyle(fontSize: 10)),
          pw.Text('Commercial: ${vente.commercialNom}',
              style: const pw.TextStyle(fontSize: 10)),
          pw.Text(
              'Client: ${vente.clientNom.isEmpty ? 'Client Libre' : vente.clientNom}',
              style: const pw.TextStyle(fontSize: 10)),
          if (vente.clientTelephone != null &&
              vente.clientTelephone!.trim().isNotEmpty)
            pw.Text('Téléphone: ${vente.clientTelephone}',
                style: const pw.TextStyle(fontSize: 10)),
          pw.Divider(),
        ],
      );

  pw.Widget produitsTable() {
    return pw.Table.fromTextArray(
      headerDecoration:
          const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE0E7FF)),
      headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1E3A8A)),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      data: <List<String>>[
        ['Produit', 'Qté', 'PU', 'Total'],
        ...vente.produits.map((p) => [
              p.typeEmballage,
              p.quantiteVendue.toString(),
              p.prixUnitaire.toStringAsFixed(0),
              p.montantTotal.toStringAsFixed(0),
            ])
      ],
    );
  }

  pw.Widget totals() => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.SizedBox(height: 6),
          _kvRow('Montant Total', _fmt(total), bold: true),
          _kvRow('Payé', _fmt(paye)),
          reste > 0
              ? _kvRow('Crédit (reste)', _fmt(reste), color: PdfColors.orange)
              : _kvRow('Solde', '0', color: PdfColors.green),
          _kvRow('Mode Paiement', vente.modePaiement.name),
          _kvRow('Statut', vente.statut.name),
          if (vente.observations != null &&
              vente.observations!.trim().isNotEmpty)
            _kvRow('Note', vente.observations!),
          pw.Divider(),
          pw.SizedBox(height: 4),
          pw.Text('Signature: __________________________',
              style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 12),
          pw.Text(
              'Généré le ${dateFmt.format(DateTime.now())} • Apisavana Gestion',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ],
      );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      build: (ctx) => [header(), produitsTable(), totals()],
    ),
  );

  return doc.save();
}

String _fmt(double v) => '${v.toStringAsFixed(0)} FCFA';

pw.Widget _kvRow(String label, String value,
    {bool bold = false, PdfColor? color}) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: 10,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: color ?? PdfColors.black)),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 10,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: color ?? PdfColors.black)),
      ],
    ),
  );
}
