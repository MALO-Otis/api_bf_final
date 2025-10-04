import 'package:intl/intl.dart';
import '../models/vente_models.dart';

String buildPerteReceiptText(Perte perte) {
  final b = StringBuffer();
  final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(perte.datePerte);
  b.writeln('========= REÇU DÉCLARATION PERTE =========');
  b.writeln('ID Perte    : ${perte.id}');
  b.writeln('Date        : $dateStr');
  b.writeln('Commercial  : ${perte.commercialNom}');
  b.writeln('Prélèvement : ${perte.prelevementId}');
  b.writeln('Type        : ${perte.type.name}');
  b.writeln('Motif       : ${perte.motif}');
  if (perte.observations != null && perte.observations!.trim().isNotEmpty) {
    b.writeln('Observations: ${perte.observations}');
  }
  b.writeln('------------------------------------------');
  b.writeln('Produits perdus:');
  for (final p in perte.produits) {
    final total = p.valeurUnitaire * p.quantitePerdue;
    b.writeln(
        '- ${p.typeEmballage} lot ${p.numeroLot} x${p.quantitePerdue} @${p.valeurUnitaire.toStringAsFixed(0)} = ${total.toStringAsFixed(0)}');
  }
  b.writeln('------------------------------------------');
  b.writeln('Valeur Totale : ${perte.valeurTotale.toStringAsFixed(0)} FCFA');
  b.writeln('Validation    : ${perte.estValidee ? 'Validée' : 'En attente'}');
  b.writeln('==========================================');
  return b.toString();
}
