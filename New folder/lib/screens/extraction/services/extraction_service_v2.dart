import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/extraction_models_v2.dart';

/// Service pour gérer les extractions complètes selon le workflow spécifié
class ExtractionServiceV2 {
  static final ExtractionServiceV2 _instance = ExtractionServiceV2._internal();
  factory ExtractionServiceV2() => _instance;
  ExtractionServiceV2._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Enregistre une nouvelle extraction dans Firestore
  Future<bool> enregistrerExtraction(ExtractionData extraction) async {
    try {
      debugPrint('🏭 ===== DÉBUT ENREGISTREMENT EXTRACTION =====');
      debugPrint('   📅 Date: ${extraction.dateExtraction}');
      debugPrint('   👤 Extracteur: ${extraction.extracteur}');
      debugPrint('   🏢 Site: ${extraction.siteExtraction}');
      debugPrint('   ⚡ Technologie: ${extraction.technologie.label}');
      debugPrint('   📦 Nombre de contenants: ${extraction.nombreContenants}');
      debugPrint('   ⚖️ Poids total: ${extraction.poidsTotal} kg');
      debugPrint(
          '   🧪 Quantité extraite: ${extraction.quantiteExtraiteReelle} kg');
      debugPrint(
          '   📊 Rendement: ${extraction.rendementExtraction.toStringAsFixed(1)}%');

      // 1️⃣ Enregistrer l'extraction dans la collection principale
      await _enregistrerExtractionPrincipale(extraction);

      // 2️⃣ Mettre à jour les statistiques
      await _mettreAJourStatistiques(extraction);

      // 3️⃣ Marquer les produits comme extraits dans attribution_reçu
      await _marquerProduitsCommeExtraits(extraction);

      debugPrint('✅ Extraction enregistrée avec succès !');
      debugPrint('🏭 ===== FIN ENREGISTREMENT EXTRACTION =====');

      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'enregistrement de l\'extraction: $e');
      return false;
    }
  }

  /// Enregistre l'extraction dans la collection principale
  Future<void> _enregistrerExtractionPrincipale(
      ExtractionData extraction) async {
    debugPrint('📝 Enregistrement extraction principale...');

    // Collection: Extraction/{site}/extractions/{extractionId}
    await _firestore
        .collection('Extraction')
        .doc(extraction.siteExtraction)
        .collection('extractions')
        .doc(extraction.id)
        .set(extraction.toMap());

    debugPrint('   ✅ Extraction principale enregistrée');
  }

  /// Met à jour les statistiques d'extraction
  Future<void> _mettreAJourStatistiques(ExtractionData extraction) async {
    debugPrint('📊 Mise à jour des statistiques...');

    try {
      final statsRef = _firestore
          .collection('Extraction')
          .doc(extraction.siteExtraction)
          .collection('statistiques')
          .doc('global');

      // Récupérer les statistiques existantes
      final statsDoc = await statsRef.get();
      ExtractionStatistics statsActuelles;

      if (statsDoc.exists) {
        statsActuelles = ExtractionStatistics.fromMap(statsDoc.data()!);
      } else {
        statsActuelles = ExtractionStatistics(
          totalExtractions: 0,
          poidsTotal: 0,
          quantiteTotaleExtraite: 0,
          rendementMoyen: 0,
          repartitionTechnologie: {},
          repartitionSites: {},
        );
      }

      // Calculer les nouvelles statistiques
      final nouvellesTotalExtractions = statsActuelles.totalExtractions + 1;
      final nouveauPoidsTotal =
          statsActuelles.poidsTotal + extraction.poidsTotal;
      final nouvelleQuantiteTotale = statsActuelles.quantiteTotaleExtraite +
          extraction.quantiteExtraiteReelle;
      final nouveauRendementMoyen = nouveauPoidsTotal > 0
          ? (nouvelleQuantiteTotale / nouveauPoidsTotal) * 100
          : 0;

      // Mettre à jour la répartition technologie
      final nouvelleRepartitionTechnologie =
          Map<String, int>.from(statsActuelles.repartitionTechnologie);
      nouvelleRepartitionTechnologie[extraction.technologie.name] =
          (nouvelleRepartitionTechnologie[extraction.technologie.name] ?? 0) +
              1;

      // Mettre à jour la répartition sites
      final nouvelleRepartitionSites =
          Map<String, double>.from(statsActuelles.repartitionSites);
      nouvelleRepartitionSites[extraction.siteExtraction] =
          (nouvelleRepartitionSites[extraction.siteExtraction] ?? 0.0) +
              extraction.quantiteExtraiteReelle;

      final nouvellesStats = ExtractionStatistics(
        totalExtractions: nouvellesTotalExtractions,
        poidsTotal: nouveauPoidsTotal,
        quantiteTotaleExtraite: nouvelleQuantiteTotale,
        rendementMoyen: nouveauRendementMoyen.toDouble(),
        repartitionTechnologie: nouvelleRepartitionTechnologie,
        repartitionSites: nouvelleRepartitionSites,
        premiereExtraction:
            statsActuelles.premiereExtraction ?? extraction.dateExtraction,
        derniereExtraction: extraction.dateExtraction,
      );

      await statsRef.set(nouvellesStats.toMap());

      debugPrint('   ✅ Statistiques mises à jour');
      debugPrint('      - Total extractions: $nouvellesTotalExtractions');
      debugPrint(
          '      - Rendement moyen: ${nouveauRendementMoyen.toStringAsFixed(1)}%');
    } catch (e) {
      debugPrint('   ❌ Erreur mise à jour statistiques: $e');
    }
  }

  /// Marque les produits comme extraits dans attribution_reçu
  Future<void> _marquerProduitsCommeExtraits(ExtractionData extraction) async {
    debugPrint('🏷️ Marquage des produits comme extraits...');

    try {
      // Récupérer les codes contenants extraits
      final codesContenantsExtraits =
          extraction.produitsExtraction.map((p) => p.codeContenant).toList();

      debugPrint(
          '   📦 Contenants à marquer: ${codesContenantsExtraits.length}');
      for (final code in codesContenantsExtraits) {
        debugPrint('      → $code');
      }

      // Rechercher et mettre à jour les attributions contenant ces produits
      final attributionsQuery = await _firestore
          .collection('attribution_reçu')
          .doc(extraction.siteExtraction)
          .collection('attributions')
          .where('type', isEqualTo: 'extraction')
          .get();

      debugPrint(
          '   🔍 ${attributionsQuery.docs.length} attributions trouvées');

      for (final doc in attributionsQuery.docs) {
        final data = doc.data();
        final List<dynamic> produits = data['produits'] ?? [];
        bool documentModifie = false;

        // Vérifier si cette attribution contient des produits extraits
        for (int i = 0; i < produits.length; i++) {
          final produit = produits[i];
          final codeContenant = produit['codeContenant'];

          if (codesContenantsExtraits.contains(codeContenant)) {
            // Marquer le produit comme extrait
            produits[i] = {
              ...produit,
              'estExtrait': true,
              'dateExtraction': extraction.dateExtraction.toIso8601String(),
              'extractionId': extraction.id,
              'quantiteExtraite': extraction.quantiteExtraiteReelle,
            };
            documentModifie = true;
            debugPrint('      ✅ Produit marqué extrait: $codeContenant');
          }
        }

        // Mettre à jour le document si modifié
        if (documentModifie) {
          await doc.reference.update({
            'produits': produits,
            'derniereMiseAJour': FieldValue.serverTimestamp(),
            'statut':
                'partiellement_extrait', // ou 'completement_extrait' selon logique
          });
          debugPrint('      📝 Attribution ${doc.id} mise à jour');
        }
      }

      debugPrint('   ✅ Produits marqués comme extraits');
    } catch (e) {
      debugPrint('   ❌ Erreur marquage produits extraits: $e');
    }
  }

  /// Récupère toutes les extractions d'un site
  Future<List<ExtractionData>> getExtractionsPourSite(String site) async {
    try {
      debugPrint('📊 Récupération extractions pour site: $site');

      final query = await _firestore
          .collection('Extraction')
          .doc(site)
          .collection('extractions')
          .orderBy('dateExtraction', descending: true)
          .get();

      final extractions =
          query.docs.map((doc) => ExtractionData.fromMap(doc.data())).toList();

      debugPrint('   ✅ ${extractions.length} extractions récupérées');
      return extractions;
    } catch (e) {
      debugPrint('❌ Erreur récupération extractions: $e');
      return [];
    }
  }

  /// Récupère les statistiques d'extraction d'un site
  Future<ExtractionStatistics?> getStatistiquesPourSite(String site) async {
    try {
      final doc = await _firestore
          .collection('Extraction')
          .doc(site)
          .collection('statistiques')
          .doc('global')
          .get();

      if (doc.exists) {
        return ExtractionStatistics.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur récupération statistiques: $e');
      return null;
    }
  }

  /// Génère un ID unique pour une extraction
  String genererIdExtraction() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    return 'ext_${timestamp}_${now.microsecond}';
  }

  /// Valide les données d'extraction avant enregistrement
  bool validerDonneesExtraction(ExtractionData extraction) {
    if (extraction.produitsExtraction.isEmpty) {
      debugPrint('❌ Validation: Aucun produit sélectionné');
      return false;
    }

    if (extraction.quantiteExtraiteReelle <= 0) {
      debugPrint('❌ Validation: Quantité extraite invalide');
      return false;
    }

    if (extraction.quantiteExtraiteReelle > extraction.poidsTotal) {
      debugPrint('❌ Validation: Quantité extraite supérieure au poids total');
      return false;
    }

    if (extraction.extracteur.isEmpty) {
      debugPrint('❌ Validation: Extracteur non spécifié');
      return false;
    }

    return true;
  }
}
