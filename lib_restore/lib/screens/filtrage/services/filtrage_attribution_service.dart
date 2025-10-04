import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apisavana_gestion/authentication/user_session.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart';

/// Service pour récupérer les produits pour filtrage (attribués + extraits)
class FiltrageAttributionService {
  static final FiltrageAttributionService _instance =
      FiltrageAttributionService._internal();
  factory FiltrageAttributionService() => _instance;
  FiltrageAttributionService._internal();

  // Liste centralisée des sites gérés par l'application
  static const List<String> _coreSites = <String>[
    'Koudougou',
    'Ouagadougou',
    'Bobo-Dioulasso',
    'Kaya',
    'Mangodara',
    'Bagre',
    'Pô',
  ];

  // ✅ NOUVEAU: Cache pour optimiser les performances
  List<ProductControle>? _cachedProducts;
  DateTime? _cacheTimestamp;
  Map<String, dynamic>? _cachedStats;
  static const Duration _cacheDuration = Duration(minutes: 5);

  // ✅ NOUVEAU: Flag pour le chargement en arrière-plan
  bool _isBackgroundLoading = false;

  /// Calcule la liste des sites cibles selon le rôle et la session utilisateur
  List<String> _getSitesCibles() {
    final userSession = Get.find<UserSession>();
    final role = (userSession.role ?? '').toLowerCase();
    final isAdmin = role.contains('admin') || role.contains('coordinateur');
    final siteSession = (userSession.site ?? '').trim();

    if (isAdmin) {
      debugPrint(
          '👑 Admin détecté — Accès tous sites: ${_coreSites.join(', ')}');
      return _coreSites;
    }

    if (siteSession.isEmpty) {
      debugPrint(
          '⚠️ Aucun site dans la session du contrôleur — aucun résultat renvoyé.');
      return const [];
    }

    debugPrint('👤 Contrôleur — Accès limité au site: $siteSession');
    return [siteSession];
  }

  /// ✅ OPTIMISÉ: Récupère les produits pour filtrage avec cache
  Future<List<ProductControle>> getProduitsFilterage(
      {String? searchQuery, bool forceRefresh = false}) async {
    try {
      // Vérifier le cache si pas de force refresh
      if (!forceRefresh && _isCacheValid()) {
        debugPrint(
            '⚡ [Cache] Utilisation du cache filtrage (${_cachedProducts!.length} produits)');
        return _applySearchFilter(_cachedProducts!, searchQuery);
      }

      debugPrint(
          '🔄 [Filtrage] Chargement ${forceRefresh ? "(forcé)" : ""}...');

      // Chargement optimisé en parallèle
      final List<ProductControle> produitsFiltrage = [];
      final List<ProductControle> produitsAttribues = [];
      final List<ProductControle> produitsExtraits = [];

      // Lancer les deux requêtes en parallèle pour réduire le temps total
      await Future.wait([
        _getProduitsAttribuesFiltrage(
            produitsAttribues, null), // Pas de filtre ici, on filtre après
        _getProduitsExtraits(produitsExtraits, null),
      ]);

      // Combiner les résultats
      produitsFiltrage.addAll(produitsAttribues);
      produitsFiltrage.addAll(produitsExtraits);

      // Mettre à jour le cache
      _cachedProducts = produitsFiltrage;
      _cacheTimestamp = DateTime.now();

      debugPrint(
          '✅ [Filtrage] ${produitsFiltrage.length} produits chargés et mis en cache');

      // Déclencher un pré-chargement en arrière-plan pour le prochain appel
      _preloadInBackground();

      return _applySearchFilter(produitsFiltrage, searchQuery);
    } catch (e) {
      debugPrint('❌ ERREUR dans getProduitsFilterage: $e');
      // En cas d'erreur, retourner le cache si disponible
      if (_cachedProducts != null) {
        debugPrint('🔄 Fallback vers le cache en cas d\'erreur');
        return _applySearchFilter(_cachedProducts!, searchQuery);
      }
      return [];
    }
  }

  /// Vérifie si le cache est encore valide
  bool _isCacheValid() {
    return _cachedProducts != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheDuration;
  }

  /// Applique le filtre de recherche sur une liste de produits
  List<ProductControle> _applySearchFilter(
      List<ProductControle> products, String? searchQuery) {
    if (searchQuery == null || searchQuery.isEmpty) {
      return products;
    }
    return products
        .where((product) => _matchSearchQuery(product, searchQuery))
        .toList();
  }

  /// Pré-charge les données en arrière-plan pour le prochain appel
  void _preloadInBackground() {
    if (_isBackgroundLoading) return;

    _isBackgroundLoading = true;
    // Programmer un rafraîchissement dans 3 minutes
    Future.delayed(const Duration(minutes: 3), () async {
      try {
        debugPrint('🔄 [Background] Pré-chargement des données filtrage...');
        await getProduitsFilterage(forceRefresh: true);
        debugPrint('✅ [Background] Pré-chargement terminé');
      } catch (e) {
        debugPrint('⚠️ [Background] Erreur pré-chargement: $e');
      } finally {
        _isBackgroundLoading = false;
      }
    });
  }

  /// Version rapide pour l'initialisation - retourne le cache ou lance le chargement
  Future<List<ProductControle>> getProduitsFilterageQuick(
      {String? searchQuery}) async {
    if (_isCacheValid()) {
      debugPrint('⚡ [Quick] Cache valide - retour immédiat');
      return _applySearchFilter(_cachedProducts!, searchQuery);
    }

    // Pas de cache valide, mais ne pas bloquer l'UI
    debugPrint('🚀 [Quick] Lancement chargement asynchrone...');
    getProduitsFilterage(searchQuery: searchQuery); // Pas d'await - asynchrone

    // Retourner une liste vide temporairement
    return [];
  }

  /// Récupère les produits attribués pour filtrage
  Future<void> _getProduitsAttribuesFiltrage(
      List<ProductControle> produitsFiltrage, String? searchQuery) async {
    final firestore = FirebaseFirestore.instance;
    // Déterminer sites selon rôle
    final sites = _getSitesCibles();

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
    // Déterminer sites selon rôle
    final sites = _getSitesCibles();

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
      // Rechercher globalement (collectionGroup) si le code est déjà filtré
      final filtrageSnapshot = await firestore
          .collectionGroup('produits_filtres')
          .where('codeContenant', isEqualTo: codeContenant)
          .limit(1)
          .get();

      final found = filtrageSnapshot.docs.isNotEmpty;
      if (found) {
        debugPrint('   🔍 Produit $codeContenant déjà présent dans Filtrage');
      }
      return found;
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

      // Calculer selon rôle/site
      final sites = _getSitesCibles();

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
      final sites = siteSpecifique != null ? [siteSpecifique] : _coreSites;

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
