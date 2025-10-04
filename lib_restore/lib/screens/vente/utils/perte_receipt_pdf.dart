import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import '../models/vente_models.dart';
import 'package:pdf/widgets.dart' as pw;

Future<Uint8List> buildPerteReceiptPdf(Perte perte) async {
  final doc = pw.Document();
  final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
  final produits = perte.produits;
  final total = perte.valeurTotale;

  pw.Widget header() => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
              'REÇU DÉCLARATION PERTE • ${perte.id} • ${dateFmt.format(perte.datePerte)}',
              style:
                  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Commercial: ${perte.commercialNom}',
              style: const pw.TextStyle(fontSize: 10)),
          pw.Text('Prélèvement: ${perte.prelevementId}',
              style: const pw.TextStyle(fontSize: 10)),
          pw.Text('Type: ${perte.type.name}',
              style: const pw.TextStyle(fontSize: 10)),
          pw.Text('Motif: ${perte.motif}',
              style: const pw.TextStyle(fontSize: 10)),
          if (perte.observations != null && perte.observations!.isNotEmpty)
            pw.Text('Obs: ${perte.observations}',
                style: const pw.TextStyle(fontSize: 10)),
          pw.Divider(),
        ],
      );

  pw.Widget table() => pw.Table.fromTextArray(
        headerDecoration: const pw.BoxDecoration(color: PdfColors.white),
        headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold, color: PdfColors.black),
        cellStyle: const pw.TextStyle(fontSize: 10, color: PdfColors.black),
        cellAlignment: pw.Alignment.centerLeft,
        data: <List<String>>[
          ['Lot', 'Emballage', 'Qté Perdue', 'PU', 'Total'],
          ...produits.map((p) => [
                p.numeroLot,
                p.typeEmballage,
                p.quantitePerdue.toString(),
                p.valeurUnitaire.toStringAsFixed(0),
                (p.valeurUnitaire * p.quantitePerdue).toStringAsFixed(0),
              ])
        ],
      );

  pw.Widget totals() => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.SizedBox(height: 8),
          pw.Text('Valeur Totale Perte: ${total.toStringAsFixed(0)} FCFA',
              style:
                  pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text('Validation: ${perte.estValidee ? 'Validée' : 'En attente'}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.black)),
          pw.Divider(),
          pw.Text('Signature Responsable: ______________________',
              style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 12),
          pw.Text(
              'Généré le ${dateFmt.format(DateTime.now())} • Apisavana Gestion',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
        ],
      );

  doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      build: (c) => [header(), table(), totals()]));
  return doc.save();
}
