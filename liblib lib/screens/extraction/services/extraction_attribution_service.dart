/// Service pour récupérer les produits attribués à l'extraction
/// 🎯 UTILISE LA MÊME LOGIQUE QUE LES AUTRES SERVICES !
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../authentication/user_session.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart';
import '../../controle_de_donnes/models/collecte_models.dart';
import '../../controle_de_donnes/models/quality_control_models.dart';
import '../../controle_de_donnes/services/firestore_data_service.dart';
import '../../controle_de_donnes/services/quality_control_service.dart';

class ExtractionAttributionService {
  static final ExtractionAttributionService _instance =
      ExtractionAttributionService._internal();
  factory ExtractionAttributionService() => _instance;
  ExtractionAttributionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final QualityControlService _qualityService = QualityControlService();

  /// Récupère tous les produits attribués pour extraction
  /// 🎯 UTILISE LA MÊME LOGIQUE QUE LES AUTRES SERVICES !
  Future<List<ProductControle>> getProduitsExtraction({
    String? siteFilter,
    String? searchQuery,
  }) async {
    try {
      debugPrint('🔍 ===== RÉCUPÉRATION PRODUITS EXTRACTION =====');
      debugPrint('   📁 Service: ExtractionAttributionService');
      debugPrint('   🎯 Source: Collection attribution_reçu (CORRIGÉ)');
      debugPrint('   🏷️ Filtre: type = "extraction"');
      debugPrint('   🏢 Site: ${siteFilter ?? "Tous"}');
      debugPrint('   🔍 Recherche: ${searchQuery ?? "Aucune"}');
      debugPrint('=============================================');

      final userSession = Get.find<UserSession>();
      final siteUtilisateur = siteFilter ?? userSession.site ?? 'SiteInconnu';

      // ✅ CORRECTION : UTILISER LE BON CHEMIN FIRESTORE
      // 1️⃣ Récupérer toutes les attributions de type "extraction" depuis attribution_reçu
      debugPrint('📊 Recherche des attributions extraction...');
      debugPrint(
          '   🎯 CHEMIN CORRIGÉ: attribution_reçu/$siteUtilisateur/attributions');
      final querySnapshot = await _firestore
          .collection('attribution_reçu')
          .doc(siteUtilisateur)
          .collection('attributions')
          .where('type', isEqualTo: 'extraction')
          .orderBy('dateAttribution', descending: true)
          .get();

      debugPrint(
          '   ✅ ${querySnapshot.docs.length} attributions extraction trouvées');

      List<ProductControle> produitsExtraction = [];

      // 2️⃣ Extraire tous les produits de ces attributions
      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          debugPrint('   📄 Attribution ${doc.id}:');
          debugPrint('      - Date: ${data['dateAttribution']}');
          debugPrint('      - Produits: ${data['produits']?.length ?? 0}');

          if (data['produits'] != null) {
            final List<dynamic> produitsData = data['produits'];

            for (final produitData in produitsData) {
              try {
                final produit = ProductControle.fromMap(produitData);

                // ✅ PRIORITÉ: Filtrer les produits déjà extraits
                final estExtrait = produitData['estExtrait'] == true;
                if (estExtrait) {
                  debugPrint(
                      '      ⏭️ Produit déjà extrait ignoré: ${produit.codeContenant}');
                  continue;
                }

                // 3️⃣ Appliquer les filtres
                bool inclure = true;

                // Filtre par recherche
                if (searchQuery != null && searchQuery.isNotEmpty) {
                  final query = searchQuery.toLowerCase();
                  inclure =
                      produit.codeContenant.toLowerCase().contains(query) ||
                          produit.village.toLowerCase().contains(query) ||
                          produit.producteur.toLowerCase().contains(query) ||
                          produit.siteOrigine.toLowerCase().contains(query);
                }

                if (inclure) {
                  produitsExtraction.add(produit);
                  debugPrint(
                      '      ✅ Produit ajouté: ${produit.codeContenant}');
                }
              } catch (e) {
                debugPrint('      ❌ Erreur parsing produit: $e');
              }
            }
          }
        } catch (e) {
          debugPrint('   ❌ Erreur traitement attribution ${doc.id}: $e');
        }
      }

      // 3️⃣ Appliquer les filtres de recherche
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        produitsExtraction = produitsExtraction.where((produit) {
          return produit.codeContenant.toLowerCase().contains(query) ||
              produit.village.toLowerCase().contains(query) ||
              produit.producteur.toLowerCase().contains(query) ||
              produit.siteOrigine.toLowerCase().contains(query);
        }).toList();
      }

      debugPrint('🎊 ===== RÉSULTAT FINAL =====');
      debugPrint(
          '   ✅ Total produits extraction: ${produitsExtraction.length}');
      debugPrint('   🏢 Site: $siteUtilisateur');
      debugPrint('   📊 Répartition par nature:');

      final Map<String, int> repartition = {};
      for (final produit in produitsExtraction) {
        repartition[produit.nature.name] =
            (repartition[produit.nature.name] ?? 0) + 1;
      }

      repartition.forEach((nature, count) {
        debugPrint('      - $nature: $count produits');
      });

      debugPrint('================================');

      return produitsExtraction;
    } catch (e) {
      debugPrint('❌ ERREUR CRITIQUE dans getProduitsExtraction: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Méthodes de conversion supprimées - utilise directement les données de attribution_reçu

  /// Récupère les statistiques des produits d'extraction
  Future<Map<String, dynamic>> getStatistiquesExtraction({
    String? siteFilter,
  }) async {
    try {
      final produits = await getProduitsExtraction(siteFilter: siteFilter);

      final stats = {
        'totalProduits': produits.length,
        'poidsTotal': produits.fold(0.0, (sum, p) => sum + p.poidsTotal),
        'poidsMielTotal': produits.fold(0.0, (sum, p) => sum + p.poidsMiel),
        'repartitionNature': <String, int>{},
        'repartitionSites': <String, int>{},
        'repartitionQualite': <String, int>{},
      };

      // Calculer les répartitions
      for (final produit in produits) {
        final repartitionNature =
            stats['repartitionNature'] as Map<String, int>;
        final repartitionSites = stats['repartitionSites'] as Map<String, int>;
        final repartitionQualite =
            stats['repartitionQualite'] as Map<String, int>;

        repartitionNature[produit.nature.name] =
            (repartitionNature[produit.nature.name] ?? 0) + 1;
        repartitionSites[produit.siteOrigine] =
            (repartitionSites[produit.siteOrigine] ?? 0) + 1;
        repartitionQualite[produit.qualite] =
            (repartitionQualite[produit.qualite] ?? 0) + 1;
      }

      debugPrint(
          '📊 Statistiques extraction calculées: ${stats['totalProduits']} produits');

      return stats;
    } catch (e) {
      debugPrint('❌ ERREUR dans getStatistiquesExtraction: $e');
      return {
        'totalProduits': 0,
        'poidsTotal': 0.0,
        'poidsMielTotal': 0.0,
        'repartitionNature': <String, int>{},
        'repartitionSites': <String, int>{},
        'repartitionQualite': <String, int>{},
      };
    }
  }

  /// Marque un produit comme prélevé (pour extraction)
  Future<bool> marquerProduitPreleve({
    required String attributionId,
    required String codeContenant,
    required double quantitePreleve,
    String? observations,
  }) async {
    try {
      debugPrint('🔧 ===== MARQUAGE PRÉLÈVEMENT =====');
      debugPrint('   📄 Attribution: $attributionId');
      debugPrint('   📦 Contenant: $codeContenant');
      debugPrint('   ⚖️ Quantité: ${quantitePreleve}kg');
      debugPrint('====================================');

      // TODO: Implémenter le marquage de prélèvement
      // Pour l'instant, juste loguer l'action
      debugPrint('   ⚠️ Marquage prélèvement pas encore implémenté');
      debugPrint('   ✅ Prélèvement simulé avec succès');
      return true;
    } catch (e) {
      debugPrint('❌ ERREUR dans marquerProduitPreleve: $e');
      return false;
    }
  }

  /// ✅ NOUVEAU: Récupère les statistiques de contrôle par site
  Future<Map<String, dynamic>> getStatistiquesControleParSite(
      {String? siteSpecifique}) async {
    try {
      debugPrint('🔍 [Contrôles] Récupération statistiques par site...');

      final firestore = FirebaseFirestore.instance;
      final Map<String, Map<String, int>> statsSites = {};

      // Liste des sites à analyser
      final sites = siteSpecifique != null
          ? [siteSpecifique]
          : [
              'Koudougou',
              'Ouagadougou',
              'Bobo-Dioulasso',
              'Kaya'
            ]; // Sites principaux

      for (final site in sites) {
        debugPrint('   📊 Analyse du site: $site (EXTRACTION uniquement)');

        // Compter les produits contrôlés dans attribution_reçu (EXTRACTION SEULEMENT)
        final attributionsSnapshot = await firestore
            .collection('attribution_reçu')
            .doc(site)
            .collection('attributions')
            .where('type',
                isEqualTo: 'extraction') // ✅ FILTRER UNIQUEMENT EXTRACTION
            .get();

        int totalControles = 0;
        int extraits = 0;
        int enAttente = 0;

        for (final doc in attributionsSnapshot.docs) {
          final data = doc.data();
          if (data['produits'] != null) {
            final List<dynamic> produits = data['produits'];
            for (final produit in produits) {
              totalControles++;
              if (produit['estExtrait'] == true) {
                extraits++;
              } else {
                enAttente++;
              }
            }
          }
        }

        statsSites[site] = {
          'totalControles': totalControles,
          'extraits': extraits,
          'enAttente': enAttente,
        };

        debugPrint(
            '   ✅ Site $site: $totalControles contrôlés (EXTRACTION), $extraits extraits, $enAttente en attente');
      }

      // Calculer les totaux
      int totalGlobal = 0;
      int extraitsGlobal = 0;
      int enAttenteGlobal = 0;

      for (final stats in statsSites.values) {
        totalGlobal += stats['totalControles'] ?? 0;
        extraitsGlobal += stats['extraits'] ?? 0;
        enAttenteGlobal += stats['enAttente'] ?? 0;
      }

      return {
        'sites': statsSites,
        'global': {
          'totalControles': totalGlobal,
          'extraits': extraitsGlobal,
          'enAttente': enAttenteGlobal,
        },
      };
    } catch (e) {
      debugPrint('❌ Erreur récupération statistiques contrôle: $e');
      return {
        'sites': <String, Map<String, int>>{},
        'global': {
          'totalControles': 0,
          'extraits': 0,
          'enAttente': 0,
        },
      };
    }
  }

  /// Crée une nouvelle attribution pour l'extraction
  Future<String> creerAttribution({
    required String type,
    required String siteDestination,
    required List<String> produitsExtraitsIds,
    required String extracteurId,
    required String extracteurNom,
    String? instructions,
    String? observations,
  }) async {
    try {
      debugPrint('🔄 [Attribution] Création attribution extraction...');
      debugPrint('   Type: $type');
      debugPrint('   Site destination: $siteDestination');
      debugPrint('   Nombre produits: ${produitsExtraitsIds.length}');
      debugPrint('   Extracteur: $extracteurNom');

      final firestore = FirebaseFirestore.instance;
      final attributionId = 'ATTR_${DateTime.now().millisecondsSinceEpoch}';

      // Récupérer les détails des produits
      final produits = <Map<String, dynamic>>[];
      for (final produitId in produitsExtraitsIds) {
        // Ici on pourrait récupérer les vraies données du produit
        produits.add({
          'id': produitId,
          'attributionId': attributionId,
          'dateAttribution': DateTime.now().toIso8601String(),
          'statut': 'attribue',
          'extracteurId': extracteurId,
          'extracteurNom': extracteurNom,
        });
      }

      // Enregistrer l'attribution
      await firestore
          .collection('attribution_reçu')
          .doc(siteDestination)
          .collection('attributions')
          .doc(attributionId)
          .set({
        'id': attributionId,
        'type': type,
        'siteDestination': siteDestination,
        'extracteurId': extracteurId,
        'extracteurNom': extracteurNom,
        'instructions': instructions,
        'observations': observations,
        'produits': produits,
        'dateCreation': FieldValue.serverTimestamp(),
        'statut': 'active',
      });

      debugPrint('✅ Attribution créée avec succès: $attributionId');
      return attributionId;
    } catch (e) {
      debugPrint('❌ Erreur création attribution: $e');
      rethrow;
    }
  }
}
