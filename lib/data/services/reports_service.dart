import 'dart:io';
import 'package:pdf/pdf.dart';
import '../models/report_models.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service pour la génération et gestion des rapports de collecte
class ReportsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Génère un rapport statistiques pour l'entreprise
  static Future<RapportStatistiques> genererRapportStatistiques(
      CollecteRapportData collecte) async {
    try {
      final rapport = RapportStatistiques.generer(collecte);

      // Sauvegarder le rapport en base (optionnel)
      await _sauvegarderRapportMetadata(
        collecte.site,
        rapport.numeroRapport,
        TypeRapport.statistiques,
        collecte.id,
        collecte.typeCollecte,
      );

      print('✅ Rapport statistiques généré: ${rapport.numeroRapport}');
      return rapport;
    } catch (e) {
      print('❌ Erreur génération rapport statistiques: $e');
      rethrow;
    }
  }

  /// Génère un reçu de collecte pour le producteur
  static Future<RecuCollecte> genererRecuCollecte(
      CollecteRapportData collecte) async {
    try {
      final recu = RecuCollecte.generer(collecte);

      // Sauvegarder le reçu en base (optionnel)
      await _sauvegarderRapportMetadata(
        collecte.site,
        recu.numeroRecu,
        TypeRapport.recu,
        collecte.id,
        collecte.typeCollecte,
      );

      print('✅ Reçu de collecte généré: ${recu.numeroRecu}');
      return recu;
    } catch (e) {
      print('❌ Erreur génération reçu collecte: $e');
      rethrow;
    }
  }

  /// Génère un PDF pour un rapport statistiques
  static Future<File> genererPdfRapportStatistiques(
      RapportStatistiques rapport) async {
    try {
      final pdf = pw.Document();
      final font = pw.Font.helvetica();
      final fontBold = pw.Font.helveticaBold();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => [
            // En-tête
            _buildHeaderStatistiques(rapport, fontBold, font),
            pw.SizedBox(height: 20),

            // Informations générales
            _buildInfosGenerales(rapport, fontBold, font),
            pw.SizedBox(height: 20),

            // Détails des contenants
            _buildDetailsContenants(rapport, fontBold, font),
            pw.SizedBox(height: 20),

            // Statistiques
            _buildStatistiques(rapport, fontBold, font),
            pw.SizedBox(height: 20),

            // Répartitions
            _buildRepartitions(rapport, fontBold, font),
            pw.SizedBox(height: 30),

            // Pied de page
            _buildFooterStatistiques(rapport, font),
          ],
        ),
      );

      final output = await getTemporaryDirectory();
      final file =
          File('${output.path}/rapport_stats_${rapport.numeroRapport}.pdf');
      await file.writeAsBytes(await pdf.save());

      print('✅ PDF rapport statistiques créé: ${file.path}');
      return file;
    } catch (e) {
      print('❌ Erreur génération PDF rapport: $e');
      rethrow;
    }
  }

  /// Génère un PDF pour un reçu de collecte
  static Future<File> genererPdfRecuCollecte(RecuCollecte recu) async {
    try {
      final pdf = pw.Document();
      final font = pw.Font.helvetica();
      final fontBold = pw.Font.helveticaBold();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête
              _buildHeaderRecu(recu, fontBold, font),
              pw.SizedBox(height: 30),

              // Informations de collecte
              _buildInfosCollecte(recu, fontBold, font),
              pw.SizedBox(height: 20),

              // Détails des contenants
              _buildTableauContenants(recu, fontBold, font),
              pw.SizedBox(height: 20),

              // Totaux
              _buildTotaux(recu, fontBold, font),
              pw.SizedBox(height: 30),

              // Message de remerciement
              _buildMessageRemerciement(recu, font),
              pw.SizedBox(height: 40),

              // Signatures
              _buildSignatures(recu, font),
            ],
          ),
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/recu_collecte_${recu.numeroRecu}.pdf');
      await file.writeAsBytes(await pdf.save());

      print('✅ PDF reçu collecte créé: ${file.path}');
      return file;
    } catch (e) {
      print('❌ Erreur génération PDF reçu: $e');
      rethrow;
    }
  }

  /// Partage un fichier PDF
  static Future<void> partagerPdf(File pdfFile, String titre) async {
    try {
      final xFile = XFile(pdfFile.path);
      await Share.shareXFiles(
        [xFile],
        subject: titre,
        text: 'Rapport de collecte ApiSavana',
      );
      print('✅ PDF partagé: ${pdfFile.path}');
    } catch (e) {
      print('❌ Erreur partage PDF: $e');
      rethrow;
    }
  }

  /// Récupère l'historique des rapports générés
  static Future<List<Map<String, dynamic>>> getHistoriqueRapports(
      String site) async {
    try {
      final snapshot = await _firestore
          .collection('Sites')
          .doc(site)
          .collection('rapports_generes')
          .orderBy('date_generation', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'date_generation': (data['date_generation'] as Timestamp).toDate(),
        };
      }).toList();
    } catch (e) {
      print('❌ Erreur récupération historique rapports: $e');
      return [];
    }
  }

  // ==================== MÉTHODES PRIVÉES ====================

  /// Sauvegarde les métadonnées d'un rapport
  static Future<void> _sauvegarderRapportMetadata(
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
      });
    } catch (e) {
      print('❌ Erreur sauvegarde metadata rapport: $e');
    }
  }

  // ==================== BUILDERS PDF ====================

  /// Construit l'en-tête pour rapport statistiques
  static pw.Widget _buildHeaderStatistiques(
    RapportStatistiques rapport,
    pw.Font fontBold,
    pw.Font font,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange100,
        border: pw.Border.all(color: PdfColors.orange),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'APISAVANA GESTION',
            style: pw.TextStyle(font: fontBold, fontSize: 20),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'RAPPORT STATISTIQUES DE COLLECTE',
            style: pw.TextStyle(font: fontBold, fontSize: 16),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'N° ${rapport.numeroRapport}',
            style: pw.TextStyle(font: font, fontSize: 12),
          ),
          pw.Text(
            'Généré le ${rapport.dateGenerationFormatee}',
            style: pw.TextStyle(font: font, fontSize: 10),
          ),
        ],
      ),
    );
  }

  /// Construit les informations générales
  static pw.Widget _buildInfosGenerales(
    RapportStatistiques rapport,
    pw.Font fontBold,
    pw.Font font,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMATIONS GÉNÉRALES',
            style: pw.TextStyle(font: fontBold, fontSize: 14),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                        'Site:', rapport.collecte.site, fontBold, font),
                    _buildInfoRow('Type:', rapport.collecte.typeCollecte.label,
                        fontBold, font),
                    _buildInfoRow('Date collecte:',
                        rapport.collecte.dateFormatee, fontBold, font),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Technicien:', rapport.collecte.technicienNom,
                        fontBold, font),
                    _buildInfoRow(
                        'Source:', rapport.collecte.nomSource, fontBold, font),
                    _buildInfoRow('Localisation:',
                        rapport.collecte.localisationComplete, fontBold, font),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construit une ligne d'information
  static pw.Widget _buildInfoRow(
      String label, String value, pw.Font fontBold, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(label,
                style: pw.TextStyle(font: fontBold, fontSize: 10)),
          ),
          pw.Expanded(
            child:
                pw.Text(value, style: pw.TextStyle(font: font, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  /// Construit le tableau des contenants
  static pw.Widget _buildDetailsContenants(
    RapportStatistiques rapport,
    pw.Font fontBold,
    pw.Font font,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DÉTAILS DES CONTENANTS',
          style: pw.TextStyle(font: fontBold, fontSize: 14),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1),
          },
          children: [
            // En-tête
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Type', fontBold, 10),
                _buildTableCell('Miel', fontBold, 10),
                _buildTableCell('Poids (kg)', fontBold, 10),
                _buildTableCell('Prix/kg', fontBold, 10),
                _buildTableCell('Total (FCFA)', fontBold, 10),
              ],
            ),
            // Données
            ...rapport.collecte.contenants.map((contenant) => pw.TableRow(
                  children: [
                    _buildTableCell(contenant.type, font, 9),
                    _buildTableCell(contenant.typeMiel, font, 9),
                    _buildTableCell(
                        contenant.quantite.toStringAsFixed(2), font, 9),
                    _buildTableCell(
                        contenant.prixUnitaire.toStringAsFixed(0), font, 9),
                    _buildTableCell(
                        contenant.montantTotal.toStringAsFixed(0), font, 9),
                  ],
                )),
          ],
        ),
      ],
    );
  }

  /// Construit une cellule de tableau
  static pw.Widget _buildTableCell(String text, pw.Font font, double fontSize) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: fontSize),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Construit les statistiques
  static pw.Widget _buildStatistiques(
    RapportStatistiques rapport,
    pw.Font fontBold,
    pw.Font font,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'STATISTIQUES',
            style: pw.TextStyle(font: fontBold, fontSize: 14),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildStatRow('Nombre de contenants:',
                        '${rapport.nombreContenants}', fontBold, font),
                    _buildStatRow('Poids total:',
                        rapport.collecte.poidsFormatte, fontBold, font),
                    _buildStatRow('Montant total:',
                        rapport.collecte.montantFormatte, fontBold, font),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildStatRow('Poids moyen/contenant:',
                        rapport.poidsMoyenFormatte, fontBold, font),
                    _buildStatRow('Prix moyen/kg:', rapport.prixMoyenFormatte,
                        fontBold, font),
                    _buildStatRow('Rendement estimé:',
                        rapport.rendementFormatte, fontBold, font),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construit une ligne de statistique
  static pw.Widget _buildStatRow(
      String label, String value, pw.Font fontBold, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(label,
                style: pw.TextStyle(font: fontBold, fontSize: 10)),
          ),
          pw.Text(value, style: pw.TextStyle(font: font, fontSize: 10)),
        ],
      ),
    );
  }

  /// Construit les répartitions
  static pw.Widget _buildRepartitions(
    RapportStatistiques rapport,
    pw.Font fontBold,
    pw.Font font,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'RÉPARTITION PAR TYPE',
                style: pw.TextStyle(font: fontBold, fontSize: 12),
              ),
              pw.SizedBox(height: 4),
              ...rapport.repartitionParType.entries.map(
                (entry) =>
                    _buildRepartitionRow(entry.key, '${entry.value}', font),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'RÉPARTITION PAR MIEL (kg)',
                style: pw.TextStyle(font: fontBold, fontSize: 12),
              ),
              pw.SizedBox(height: 4),
              ...rapport.repartitionParMiel.entries.map(
                (entry) => _buildRepartitionRow(
                    entry.key, '${entry.value.toStringAsFixed(2)}', font),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construit une ligne de répartition
  static pw.Widget _buildRepartitionRow(
      String label, String value, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('• $label', style: pw.TextStyle(font: font, fontSize: 9)),
          pw.Text(value, style: pw.TextStyle(font: font, fontSize: 9)),
        ],
      ),
    );
  }

  /// Construit le pied de page des statistiques
  static pw.Widget _buildFooterStatistiques(
    RapportStatistiques rapport,
    pw.Font font,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Ce rapport est généré automatiquement par le système ApiSavana Gestion',
            style: pw.TextStyle(font: font, fontSize: 8),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Document confidentiel - Usage interne uniquement',
            style: pw.TextStyle(font: font, fontSize: 8),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== BUILDERS REÇU ====================

  /// Construit l'en-tête pour reçu
  static pw.Widget _buildHeaderRecu(
    RecuCollecte recu,
    pw.Font fontBold,
    pw.Font font,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.green100,
        border: pw.Border.all(color: PdfColors.green),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'APISAVANA GESTION',
            style: pw.TextStyle(font: fontBold, fontSize: 20),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'REÇU DE COLLECTE',
            style: pw.TextStyle(font: fontBold, fontSize: 16),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'N° ${recu.numeroRecu}',
            style: pw.TextStyle(font: fontBold, fontSize: 12),
          ),
          pw.Text(
            'Émis le ${recu.dateGenerationFormatee}',
            style: pw.TextStyle(font: font, fontSize: 10),
          ),
        ],
      ),
    );
  }

  /// Construit les informations de collecte pour reçu
  static pw.Widget _buildInfosCollecte(
    RecuCollecte recu,
    pw.Font fontBold,
    pw.Font font,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMATIONS DE COLLECTE',
            style: pw.TextStyle(font: fontBold, fontSize: 14),
          ),
          pw.SizedBox(height: 8),
          _buildInfoRow(
              'Date de collecte:', recu.collecte.dateFormatee, fontBold, font),
          _buildInfoRow('Type de collecte:', recu.collecte.typeCollecte.label,
              fontBold, font),
          _buildInfoRow('Source:', recu.collecte.nomSource, fontBold, font),
          _buildInfoRow('Localisation:', recu.collecte.localisationComplete,
              fontBold, font),
          _buildInfoRow(
              'Technicien:', recu.collecte.technicienNom, fontBold, font),
          if (recu.collecte.observations != null &&
              recu.collecte.observations!.isNotEmpty)
            _buildInfoRow(
                'Observations:', recu.collecte.observations!, fontBold, font),
        ],
      ),
    );
  }

  /// Construit le tableau des contenants pour reçu
  static pw.Widget _buildTableauContenants(
    RecuCollecte recu,
    pw.Font fontBold,
    pw.Font font,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DÉTAIL DE LA COLLECTE',
          style: pw.TextStyle(font: fontBold, fontSize: 14),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            // En-tête
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.green50),
              children: [
                _buildTableCell('Type contenant', fontBold, 10),
                _buildTableCell('Type miel', fontBold, 10),
                _buildTableCell('Quantité (kg)', fontBold, 10),
                _buildTableCell('Prix unitaire', fontBold, 10),
                _buildTableCell('Montant (FCFA)', fontBold, 10),
              ],
            ),
            // Données
            ...recu.collecte.contenants.map((contenant) => pw.TableRow(
                  children: [
                    _buildTableCell(contenant.type, font, 9),
                    _buildTableCell(contenant.typeMiel, font, 9),
                    _buildTableCell(
                        contenant.quantite.toStringAsFixed(2), font, 9),
                    _buildTableCell(
                        contenant.prixUnitaire.toStringAsFixed(0), font, 9),
                    _buildTableCell(
                        contenant.montantTotal.toStringAsFixed(0), font, 9),
                  ],
                )),
          ],
        ),
      ],
    );
  }

  /// Construit les totaux pour reçu
  static pw.Widget _buildTotaux(
    RecuCollecte recu,
    pw.Font fontBold,
    pw.Font font,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        border: pw.Border.all(color: PdfColors.green200),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: [
          pw.Column(
            children: [
              pw.Text(
                'POIDS TOTAL',
                style: pw.TextStyle(font: fontBold, fontSize: 12),
              ),
              pw.Text(
                recu.collecte.poidsFormatte,
                style: pw.TextStyle(font: fontBold, fontSize: 16),
              ),
            ],
          ),
          pw.Column(
            children: [
              pw.Text(
                'MONTANT TOTAL',
                style: pw.TextStyle(font: fontBold, fontSize: 12),
              ),
              pw.Text(
                recu.collecte.montantFormatte,
                style: pw.TextStyle(font: fontBold, fontSize: 16),
              ),
            ],
          ),
          pw.Column(
            children: [
              pw.Text(
                'NOMBRE CONTENANTS',
                style: pw.TextStyle(font: fontBold, fontSize: 12),
              ),
              pw.Text(
                '${recu.collecte.contenants.length}',
                style: pw.TextStyle(font: fontBold, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construit le message de remerciement
  static pw.Widget _buildMessageRemerciement(
    RecuCollecte recu,
    pw.Font font,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.yellow50,
        border: pw.Border.all(color: PdfColors.orange200),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'MESSAGE DE REMERCIEMENT',
            style: pw.TextStyle(
                font: font, fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            recu.messageRemerciement,
            style: pw.TextStyle(font: font, fontSize: 11),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Construit les signatures
  static pw.Widget _buildSignatures(
    RecuCollecte recu,
    pw.Font font,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
      children: [
        pw.Column(
          children: [
            pw.Text(
              'Signature du producteur/source',
              style: pw.TextStyle(font: font, fontSize: 10),
            ),
            pw.SizedBox(height: 40),
            pw.Container(
              width: 150,
              height: 1,
              color: PdfColors.black,
            ),
          ],
        ),
        pw.Column(
          children: [
            pw.Text(
              'Signature du technicien',
              style: pw.TextStyle(font: font, fontSize: 10),
            ),
            pw.SizedBox(height: 40),
            pw.Container(
              width: 150,
              height: 1,
              color: PdfColors.black,
            ),
          ],
        ),
      ],
    );
  }
}
