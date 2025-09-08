import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../controle_de_donnes/models/attribution_models_v2.dart';

/// Service pour récupérer les produits pour filtrage (attribués + extraits)
class FiltrageAttributionService {
  static final FiltrageAttributionService _instance =
      FiltrageAttributionService._internal();
  factory FiltrageAttributionService() => _instance;
  FiltrageAttributionService._internal();

  /// ✅ NOUVEAU: Récupère les produits pour filtrage (attribués + extraits)
  Future<List<ProductControle>> getProduitsFilterage(
      {String? searchQuery}) async {
    try {
      debugPrint('🔍 ===== RÉCUPÉRATION PRODUITS FILTRAGE =====');
      debugPrint('   📁 Service: FiltrageAttributionService');
      debugPrint('   🎯 Source: Attribution filtrage + Extractions terminées');
      debugPrint('   🏷️ Filtre: type = "filtrage" + miel liquide extrait');
      debugPrint('   🔍 Recherche: ${searchQuery ?? "Aucune"}');
      debugPrint('=============================================');

      final List<ProductControle> produitsFiltrage = [];

      // 1️⃣ Récupérer les produits attribués pour filtrage
      await _getProduitsAttribuesFiltrage(produitsFiltrage, searchQuery);

      // 2️⃣ Récupérer les produits extraits (miel liquide à filtrer)
      await _getProduitsExtraits(produitsFiltrage, searchQuery);

      debugPrint('🎊 ===== RÉSULTAT FINAL =====');
      debugPrint('   ✅ Total produits filtrage: ${produitsFiltrage.length}');

      // Statistiques par source
      final parSource = <String, int>{};
      final parNature = <String, int>{};
      for (final produit in produitsFiltrage) {
        final source = produit.estAttribue ? 'Attribution' : 'Extraction';
        parSource[source] = (parSource[source] ?? 0) + 1;

        final nature = produit.nature.label;
        parNature[nature] = (parNature[nature] ?? 0) + 1;
      }

      debugPrint('   📊 Répartition par source:');
      parSource.forEach((source, count) {
        debugPrint('      - $source: $count produits');
      });
      debugPrint('   📊 Répartition par nature:');
      parNature.forEach((nature, count) {
        debugPrint('      - $nature: $count produits');
      });
      debugPrint('================================');

      return produitsFiltrage;
    } catch (e) {
      debugPrint('❌ ERREUR dans getProduitsFilterage: $e');
      return [];
    }
  }

  /// Récupère les produits attribués pour filtrage
  Future<void> _getProduitsAttribuesFiltrage(
      List<ProductControle> produitsFiltrage, String? searchQuery) async {
    final firestore = FirebaseFirestore.instance;
    final sites = ['Koudougou', 'Ouagadougou', 'Bobo-Dioulasso'];

    debugPrint('📋 1️⃣ PRODUITS ATTRIBUÉS POUR FILTRAGE:');

    for (final site in sites) {
      debugPrint('   📊 Site: $site - Attributions filtrage');

      final attributionsSnapshot = await firestore
          .collection('attribution_reçu')
          .doc(site)
          .collection('attributions')
          .where('type', isEqualTo: 'filtrage')
          .get();

      debugPrint(
          '      ✅ ${attributionsSnapshot.docs.length} attributions trouvées');

      for (final doc in attributionsSnapshot.docs) {
        final data = doc.data();
        if (data['produits'] != null) {
          final List<dynamic> produitsData = data['produits'];

          for (final produitData in produitsData) {
            try {
              final produit = ProductControle.fromMap(produitData);

              // Filtrer les produits déjà filtrés
              final estFiltre = produitData['estFiltre'] == true;
              final dejaFiltreDansCollection =
                  await _verifierSiProduitFiltre(produit.codeContenant);

              if (estFiltre || dejaFiltreDansCollection) {
                debugPrint(
                    '      ⏭️ Produit déjà filtré ignoré: ${produit.codeContenant} (estFiltre: $estFiltre, dansCollection: $dejaFiltreDansCollection)');
                continue;
              }

              // Appliquer la recherche
              if (_matchSearchQuery(produit, searchQuery)) {
                produitsFiltrage.add(produit);
                debugPrint(
                    '      ✅ Produit attribué ajouté: ${produit.codeContenant}');
              }
            } catch (e) {
              debugPrint('      ❌ Erreur parsing produit attribué: $e');
            }
          }
        }
      }
    }
  }

  /// ✅ NOUVEAU: Récupère les produits extraits (miel liquide à filtrer)
  Future<void> _getProduitsExtraits(
      List<ProductControle> produitsFiltrage, String? searchQuery) async {
    final firestore = FirebaseFirestore.instance;
    final sites = ['Koudougou', 'Ouagadougou', 'Bobo-Dioulasso'];

    debugPrint('🍯 2️⃣ MIEL LIQUIDE EXTRAIT À FILTRER:');

    for (final site in sites) {
      debugPrint('   📊 Site: $site - Extractions terminées');

      try {
        final extractionsSnapshot = await firestore
            .collection('Extraction')
            .doc(site)
            .collection('extractions')
            .get();

        debugPrint(
            '      ✅ ${extractionsSnapshot.docs.length} extractions trouvées');

        for (final doc in extractionsSnapshot.docs) {
          final data = doc.data();

          // Vérifier si le miel extrait n'a pas encore été filtré
          final estFiltre = data['estFiltre'] == true;
          if (estFiltre) {
            debugPrint('      ⏭️ Extraction déjà filtrée ignorée: ${doc.id}');
            continue;
          }

          // Double vérification dans la collection de filtrage si un codeContenant existe
          final codeContenant = data['codeContenant'];
          if (codeContenant != null) {
            final dejaFiltreDansCollection =
                await _verifierSiProduitFiltre(codeContenant);
            if (dejaFiltreDansCollection) {
              debugPrint(
                  '      ⏭️ Extraction avec code $codeContenant déjà filtrée (collection)');
              continue;
            }
          }

          // Créer un ProductControle virtuel pour le miel extrait
          final mielExtrait = _creerProduitMielExtrait(data, doc.id, site);

          if (mielExtrait != null &&
              _matchSearchQuery(mielExtrait, searchQuery)) {
            produitsFiltrage.add(mielExtrait);
            debugPrint(
                '      ✅ Miel extrait ajouté: ${mielExtrait.codeContenant}');
          }
        }
      } catch (e) {
        debugPrint('      ❌ Erreur récupération extractions: $e');
      }
    }
  }

  /// Crée un ProductControle virtuel pour le miel extrait
  ProductControle? _creerProduitMielExtrait(
      Map<String, dynamic> extractionData, String extractionId, String site) {
    try {
      return ProductControle(
        id: 'extraction_$extractionId',
        codeContenant: 'MIEL-EXT-${extractionId.substring(0, 8).toUpperCase()}',
        collecteId: extractionId,
        producteur: extractionData['extracteur'] ?? 'Inconnu',
        village: 'Extraction $site',
        commune: 'Extraction', // ✅ AJOUT paramètre requis
        quartier: 'Centre', // ✅ AJOUT paramètre requis
        siteOrigine: site,
        nature: ProductNature.liquide, // Miel liquide après extraction
        typeContenant: 'Extraction', // ✅ AJOUT paramètre requis
        numeroContenant:
            extractionId.substring(0, 8), // ✅ AJOUT paramètre requis
        qualite: 'Extrait',
        poidsTotal:
            (extractionData['quantiteExtraiteReelle'] ?? 0.0).toDouble(),
        poidsMiel: (extractionData['quantiteExtraiteReelle'] ?? 0.0).toDouble(),
        predominanceFlorale: 'Multiflorale', // ✅ AJOUT paramètre requis
        dateCollecte: _parseDate(extractionData['dateExtraction']),
        dateReception: _parseDate(extractionData['dateExtraction']),
        dateControle: _parseDate(extractionData['dateExtraction']),
        estAttribue: false, // Marquer comme provenant d'extraction
        estConforme: true,
        typeCollecte: 'Extraction',
      );
    } catch (e) {
      debugPrint('❌ Erreur création produit miel extrait: $e');
      return null;
    }
  }

  /// Parse une date qui peut être soit un Timestamp, soit une String, soit null
  DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) {
      return DateTime.now();
    }

    if (dateValue is Timestamp) {
      return dateValue.toDate();
    }

    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        debugPrint('⚠️ Erreur parsing date string "$dateValue": $e');
        return DateTime.now();
      }
    }

    debugPrint('⚠️ Type de date non supporté: ${dateValue.runtimeType}');
    return DateTime.now();
  }

  /// Vérifie si un produit a déjà été filtré en consultant la collection Filtrage
  Future<bool> _verifierSiProduitFiltre(String codeContenant) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Sites disponibles
      final sites = [
        'Koudougou',
        'Ouagadougou',
        'Bobo-Dioulasso',
        'Mangodara',
        'Bagre',
        'Pô'
      ];

      // Rechercher dans toutes les collections de filtrage de tous les sites
      for (final site in sites) {
        final filtrageSnapshot = await firestore
            .collectionGroup('produits_filtres')
            .where('codeContenant', isEqualTo: codeContenant)
            .limit(1)
            .get();

        if (filtrageSnapshot.docs.isNotEmpty) {
          debugPrint(
              '   🔍 Produit $codeContenant trouvé dans filtrage du site $site');
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('   ⚠️ Erreur vérification filtrage pour $codeContenant: $e');
      return false; // En cas d'erreur, on considère le produit comme non filtré
    }
  }

  /// Vérifie si un produit correspond aux critères de recherche
  bool _matchSearchQuery(ProductControle produit, String? searchQuery) {
    if (searchQuery == null || searchQuery.isEmpty) return true;

    final query = searchQuery.toLowerCase();
    return produit.codeContenant.toLowerCase().contains(query) ||
        produit.village.toLowerCase().contains(query) ||
        produit.producteur.toLowerCase().contains(query) ||
        produit.siteOrigine.toLowerCase().contains(query);
  }

  /// ✅ AMÉLIORÉ: Récupère les statistiques de filtrage (attribués + extraits)
  Future<Map<String, dynamic>> getStatistiquesFiltrage() async {
    try {
      debugPrint('📊 ===== RÉCUPÉRATION STATISTIQUES FILTRAGE =====');

      final firestore = FirebaseFirestore.instance;
      int totalProduits = 0;
      int attribues = 0;
      int extraits = 0;
      int produitsFiltres = 0;
      double poidsTotal = 0.0;
      double rendementMoyen = 0.0;

      final sites = ['Koudougou', 'Ouagadougou', 'Bobo-Dioulasso'];

      for (final site in sites) {
        debugPrint('   📊 Analyse site: $site');

        // 1️⃣ Compter les produits attribués pour filtrage
        final attributionsSnapshot = await firestore
            .collection('attribution_reçu')
            .doc(site)
            .collection('attributions')
            .where('type', isEqualTo: 'filtrage')
            .get();

        for (final doc in attributionsSnapshot.docs) {
          final data = doc.data();
          if (data['produits'] != null) {
            final List<dynamic> produits = data['produits'];
            for (final produit in produits) {
              totalProduits++;
              attribues++;
              final poids = (produit['poidsTotal'] ?? 0.0).toDouble();
              poidsTotal += poids;

              if (produit['estFiltre'] == true) {
                produitsFiltres++;
              }
            }
          }
        }

        // 2️⃣ Compter les produits extraits (miel liquide)
        try {
          final extractionsSnapshot = await firestore
              .collection('Extraction')
              .doc(site)
              .collection('extractions')
              .get();

          for (final doc in extractionsSnapshot.docs) {
            final data = doc.data();
            final estFiltre = data['estFiltre'] == true;

            if (!estFiltre) {
              totalProduits++;
              extraits++;
              final poids = (data['quantiteExtraiteReelle'] ?? 0.0).toDouble();
              poidsTotal += poids;
            } else {
              produitsFiltres++;
            }
          }
        } catch (e) {
          debugPrint('      ❌ Erreur extractions: $e');
        }
      }

      if (totalProduits > 0) {
        rendementMoyen =
            (produitsFiltres / (totalProduits + produitsFiltres)) * 100;
      }

      final stats = {
        'totalProduits': totalProduits,
        'attribues': attribues,
        'extraits': extraits,
        'produitsFiltres': produitsFiltres,
        'produitsEnAttente': totalProduits,
        'poidsTotal': poidsTotal,
        'rendementMoyen': rendementMoyen,
      };

      debugPrint('✅ Statistiques calculées:');
      debugPrint('   - Total produits: $totalProduits');
      debugPrint('   - Attribués: $attribues');
      debugPrint('   - Extraits: $extraits');
      debugPrint('   - Produits filtrés: $produitsFiltres');
      debugPrint('   - En attente: ${stats['produitsEnAttente']}');
      debugPrint('   - Poids total: ${poidsTotal.toStringAsFixed(1)} kg');
      debugPrint('   - Rendement moyen: ${rendementMoyen.toStringAsFixed(1)}%');
      debugPrint('================================================');

      return stats;
    } catch (e) {
      debugPrint('❌ ERREUR dans getStatistiquesFiltrage: $e');
      return {
        'totalProduits': 0,
        'attribues': 0,
        'extraits': 0,
        'produitsFiltres': 0,
        'produitsEnAttente': 0,
        'poidsTotal': 0.0,
        'rendementMoyen': 0.0,
      };
    }
  }

  /// ✅ NOUVEAU: Récupère les statistiques de contrôle par site pour filtrage
  Future<Map<String, dynamic>> getStatistiquesControleParSite({
    String? siteSpecifique,
  }) async {
    try {
      debugPrint('📊 ===== STATS CONTRÔLE FILTRAGE PAR SITE =====');
      debugPrint('   🎯 Site spécifique: ${siteSpecifique ?? "Tous"}');

      final firestore = FirebaseFirestore.instance;
      final Map<String, dynamic> statsSites = {};

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
        debugPrint('   📊 Analyse du site: $site (FILTRAGE uniquement)');

        // Compter les produits contrôlés dans attribution_reçu (FILTRAGE SEULEMENT)
        final attributionsSnapshot = await firestore
            .collection('attribution_reçu')
            .doc(site)
            .collection('attributions')
            .where('type',
                isEqualTo: 'filtrage') // ✅ FILTRER UNIQUEMENT FILTRAGE
            .get();

        int totalControles = 0;
        int filtres = 0;
        int enAttente = 0;

        for (final doc in attributionsSnapshot.docs) {
          final data = doc.data();
          if (data['produits'] != null) {
            final List<dynamic> produits = data['produits'];
            for (final produit in produits) {
              totalControles++;
              if (produit['estFiltre'] == true) {
                filtres++;
              } else {
                enAttente++;
              }
            }
          }
        }

        // Ajouter les extractions disponibles pour filtrage
        try {
          final extractionsSnapshot = await firestore
              .collection('Extraction')
              .doc(site)
              .collection('extractions')
              .get();

          for (final doc in extractionsSnapshot.docs) {
            final data = doc.data();
            if (data['estFiltre'] == true) {
              filtres++;
            } else {
              totalControles++;
              enAttente++;
            }
          }
        } catch (e) {
          debugPrint('      ❌ Erreur extractions site $site: $e');
        }

        statsSites[site] = {
          'totalControles': totalControles,
          'filtres': filtres,
          'enAttente': enAttente,
        };

        debugPrint(
            '   ✅ Site $site: $totalControles contrôlés (FILTRAGE), $filtres filtrés, $enAttente en attente');
      }

      // Calculer les totaux
      int totalGlobal = 0;
      int filtresGlobal = 0;
      int enAttenteGlobal = 0;

      for (final stats in statsSites.values) {
        final siteStats = stats as Map<String, dynamic>;
        totalGlobal += (siteStats['totalControles'] as int);
        filtresGlobal += (siteStats['filtres'] as int);
        enAttenteGlobal += (siteStats['enAttente'] as int);
      }

      final result = {
        'sites': statsSites,
        'totaux': {
          'totalControles': totalGlobal,
          'filtres': filtresGlobal,
          'enAttente': enAttenteGlobal,
        },
      };

      debugPrint('✅ TOTAUX GLOBAUX FILTRAGE:');
      debugPrint('   - Total contrôlés: $totalGlobal');
      debugPrint('   - Filtrés: $filtresGlobal');
      debugPrint('   - En attente: $enAttenteGlobal');
      debugPrint('==============================================');

      return result;
    } catch (e) {
      debugPrint('❌ ERREUR dans getStatistiquesControleParSite (filtrage): $e');
      return {
        'sites': <String, dynamic>{},
        'totaux': {
          'totalControles': 0,
          'filtres': 0,
          'enAttente': 0,
        },
      };
    }
  }

  /// Marque un produit comme prélevé pour filtrage (placeholder pour future implémentation)
  Future<bool> marquerProduitFiltre(
      String productId, Map<String, dynamic> filtrageData) async {
    try {
      debugPrint('🧪 Marquage produit filtré: $productId');
      // TODO: Implémenter la logique de marquage des produits filtrés
      // Cette méthode sera utilisée quand l'utilisateur termine un filtrage

      return true;
    } catch (e) {
      debugPrint('❌ Erreur marquage produit filtré: $e');
      return false;
    }
  }
}
