/// 🎯 SERVICE CONDITIONNEMENT CONNECTÉ À LA BASE DE DONNÉES
///
/// Service optimisé pour récupérer les lots filtrés depuis la vraie structure Firestore
/// et gérer le conditionnement avec filtrage par site selon le rôle utilisateur

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../authentication/user_session.dart';
import '../conditionnement_models.dart';

/// Service principal pour le conditionnement connecté à la DB
class ConditionnementDbService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserSession _userSession = Get.find<UserSession>();

  /// Sites disponibles
  final List<String> sites = [
    'Koudougou',
    'Ouagadougou',
    'Bobo-Dioulasso',
    'Mangodara',
    'Bagre',
    'Pô'
  ];

  /// États observables
  final RxBool _isLoading = false.obs;
  final RxList<LotFiltre> _lotsDisponibles = <LotFiltre>[].obs;
  final RxList<ConditionnementData> _conditionnements =
      <ConditionnementData>[].obs;

  // Getters
  bool get isLoading => _isLoading.value;
  List<LotFiltre> get lotsDisponibles => _lotsDisponibles;
  List<ConditionnementData> get conditionnements => _conditionnements;

  @override
  void onInit() {
    super.onInit();

    // 🔥 Décaler les chargements pour éviter les erreurs de build
    Future.microtask(() async {
      await _loadLotsDisponibles();
      await _loadConditionnements();
    });
  }

  /// 🔄 CHARGEMENT DES LOTS FILTRÉS DISPONIBLES POUR CONDITIONNEMENT
  Future<void> _loadLotsDisponibles() async {
    _isLoading.value = true;
    try {
      debugPrint('🔄 [ConditionnementDB] Chargement des lots filtrés...');

      final lots = <LotFiltre>[];
      final sitesToCheck = _getSitesAutorises();

      // 🔍 DIAGNOSTIC DES COLLECTIONS DISPONIBLES
      debugPrint('🔍 === DIAGNOSTIC COLLECTIONS DISPONIBLES ===');
      try {
        final collectionsSnapshot =
            await _firestore.collection('Filtrage').get();
        debugPrint('📋 Collections dans Filtrage:');
        for (final doc in collectionsSnapshot.docs) {
          debugPrint('   - ${doc.id}');
        }

        // Vérifier les sous-collections
        for (final site in sitesToCheck) {
          try {
            final processusSnapshot = await _firestore
                .collection('Filtrage')
                .doc(site)
                .collection('processus')
                .limit(1)
                .get();
            debugPrint(
                '   - $site/processus: ${processusSnapshot.docs.length} docs');
          } catch (e) {
            debugPrint('   - $site/processus: Erreur - $e');
          }
        }
      } catch (e) {
        debugPrint('❌ Erreur diagnostic collections: $e');
      }
      debugPrint('==========================================');

      // Essayer d'abord la nouvelle structure /Filtrage/{site}/processus/
      for (final site in sitesToCheck) {
        debugPrint(
            '   📍 Analyse du site: $site (structure /Filtrage/{site}/processus/)');

        try {
          // Requête simple sans orderBy pour éviter l'index
          final filtrageSnapshot = await _firestore
              .collection('Filtrage')
              .doc(site)
              .collection('processus')
              .where('statut', isEqualTo: 'termine')
              .get();

          debugPrint(
              '      ✅ ${filtrageSnapshot.docs.length} filtrages trouvés dans /Filtrage/{site}/processus/');

          // 🔍 DIAGNOSTIC DÉTAILLÉ DES CHAMPS /Filtrage/{site}/processus/
          if (filtrageSnapshot.docs.isNotEmpty) {
            debugPrint('🔍 === DIAGNOSTIC /Filtrage/{site}/processus/ ===');
            final premierDoc = filtrageSnapshot.docs.first;
            final data = premierDoc.data();
            debugPrint(
                '📋 Champs disponibles dans /Filtrage/{site}/processus/:');
            data.forEach((key, value) {
              debugPrint('   - $key: $value (${value.runtimeType})');
            });
            debugPrint('==========================================');
          }

          for (final doc in filtrageSnapshot.docs) {
            try {
              final lot = await _convertirFiltrageEnLot(doc, site);
              if (lot != null && lot.peutEtreConditionne) {
                lots.add(lot);
              }
            } catch (e) {
              debugPrint('❌ Erreur conversion lot ${doc.id}: $e');
            }
          }
        } catch (e) {
          debugPrint('⚠️ Erreur accès /Filtrage/{site}/processus/: $e');
        }
      }

      // Si aucun lot trouvé, essayer la structure filtered_products
      if (lots.isEmpty) {
        debugPrint(
            '🔄 [ConditionnementDB] Aucun lot dans /Filtrage/{site}/processus/, essai avec filtered_products...');

        for (final site in sitesToCheck) {
          debugPrint(
              '   📍 Analyse du site: $site (structure filtered_products)');

          try {
            // Requête simple sans orderBy pour éviter l'index
            final filteredProductsSnapshot = await _firestore
                .collection('filtered_products')
                .where('site_origine', isEqualTo: site)
                .where('statut', isEqualTo: 'filtre')
                .get();

            debugPrint(
                '      ✅ ${filteredProductsSnapshot.docs.length} produits filtrés trouvés');

            // 🔍 DIAGNOSTIC DÉTAILLÉ DES CHAMPS
            if (filteredProductsSnapshot.docs.isNotEmpty) {
              debugPrint('🔍 === DIAGNOSTIC FILTERED_PRODUCTS ===');
              final premierDoc = filteredProductsSnapshot.docs.first;
              final data = premierDoc.data();
              debugPrint('📋 Champs disponibles dans filtered_products:');
              data.forEach((key, value) {
                debugPrint('   - $key: $value (${value.runtimeType})');
              });
              debugPrint('==========================================');
            }

            // Grouper les produits par lot
            final Map<String, List<DocumentSnapshot>> lotsGroupes = {};
            for (final doc in filteredProductsSnapshot.docs) {
              final data = doc.data();
              final lotId =
                  data['code_contenant']?.toString() ?? 'LOT-${doc.id}';
              lotsGroupes[lotId] ??= [];
              lotsGroupes[lotId]!.add(doc);
            }

            // Convertir chaque groupe en LotFiltre
            for (final entry in lotsGroupes.entries) {
              try {
                final lot =
                    await _convertirFilteredProductsEnLot(entry.value, site);
                if (lot != null && lot.peutEtreConditionne) {
                  lots.add(lot);
                }
              } catch (e) {
                debugPrint('❌ Erreur conversion groupe ${entry.key}: $e');
              }
            }
          } catch (e) {
            debugPrint('⚠️ Erreur accès filtered_products: $e');
          }
        }
      }

      // 🔥 FILTRER SEULEMENT LES LOTS NON CONDITIONNÉS
      final lotsNonConditionnes =
          lots.where((lot) => lot.peutEtreConditionne).toList();

      _lotsDisponibles.value = lotsNonConditionnes;
      debugPrint(
          '✅ [ConditionnementDB] ${lots.length} lots filtrés trouvés, ${lotsNonConditionnes.length} disponibles pour conditionnement');
    } catch (e) {
      debugPrint('❌ [ConditionnementDB] Erreur chargement lots: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// 🔄 CHARGEMENT DES CONDITIONNEMENTS EXISTANTS
  Future<void> _loadConditionnements() async {
    try {
      debugPrint('🔄 [ConditionnementDB] Chargement conditionnements...');

      final conditionnements = <ConditionnementData>[];
      final sitesAutorises = _getSitesAutorises();

      debugPrint('🔍 [ConditionnementDB] Sites autorisés: $sitesAutorises');

      // 📊 EXPLORATION COMPLÈTE DE TOUTES LES STRUCTURES FIRESTORE POSSIBLES

      // 1. Structure moderne par site : conditionnement/{site}/conditionnements
      int totalModerne = 0;
      for (final site in sitesAutorises) {
        try {
          final conditionnementsSite = await _firestore
              .collection('conditionnement')
              .doc(site)
              .collection('conditionnements')
              .get(); // Enlever orderBy pour éviter les erreurs d'index

          totalModerne += conditionnementsSite.docs.length;
          debugPrint(
              '📊 [ConditionnementDB] Structure moderne - Site $site: ${conditionnementsSite.docs.length} conditionnements');

          for (final doc in conditionnementsSite.docs) {
            try {
              debugPrint(
                  '📄 [ConditionnementDB] Parsing doc ${doc.id} du site $site');
              final conditionnement = ConditionnementData.fromFirestore(doc);
              conditionnements.add(conditionnement);
              debugPrint(
                  '✅ [ConditionnementDB] Conditionnement ajouté: ${conditionnement.lotOrigine.lotOrigine}');
            } catch (e) {
              debugPrint(
                  '❌ [ConditionnementDB] Erreur parsing conditionnement ${doc.id}: $e');
              debugPrint(
                  '🔍 [ConditionnementDB] Données du document: ${doc.data()}');
            }
          }
        } catch (e) {
          debugPrint(
              '❌ [ConditionnementDB] Erreur chargement conditionnements site $site: $e');
        }
      }

      // 2. Structure legacy : conditionnement (collection racine)
      int totalLegacy = 0;
      try {
        final conditionnnementsLegacy = await _firestore
            .collection('conditionnement')
            .get(); // Sans orderBy pour éviter erreurs d'index

        totalLegacy = conditionnnementsLegacy.docs.length;
        debugPrint(
            '📊 [ConditionnementDB] Structure legacy: ${conditionnnementsLegacy.docs.length} documents trouvés');

        for (final doc in conditionnnementsLegacy.docs) {
          try {
            // Vérifier si c'est un document de conditionnement ou un document de site
            final data = doc.data();

            // Si le document a un champ 'date', c'est probablement un conditionnement
            if (data.containsKey('date') && data.containsKey('emballages')) {
              debugPrint(
                  '📄 [ConditionnementDB] Parsing conditionnement legacy ${doc.id}');
              final conditionnement = ConditionnementData.fromFirestore(doc);

              // Éviter les doublons
              if (!conditionnements.any((c) => c.id == conditionnement.id)) {
                conditionnements.add(conditionnement);
                debugPrint(
                    '✅ [ConditionnementDB] Conditionnement legacy ajouté: ${conditionnement.lotOrigine.lotOrigine}');
              } else {
                debugPrint(
                    '⚠️ [ConditionnementDB] Conditionnement ${doc.id} déjà présent (doublon évité)');
              }
            } else {
              debugPrint(
                  '⏭️ [ConditionnementDB] Document ${doc.id} ignoré (pas un conditionnement)');
            }
          } catch (e) {
            debugPrint(
                '❌ [ConditionnementDB] Erreur parsing conditionnement legacy ${doc.id}: $e');
            debugPrint(
                '🔍 [ConditionnementDB] Données du document legacy: ${doc.data()}');
          }
        }
      } catch (e) {
        debugPrint(
            '❌ [ConditionnementDB] Erreur chargement conditionnements legacy: $e');
      }

      // 3. Autres structures possibles - Explorer toutes les collections
      try {
        debugPrint(
            '🔍 [ConditionnementDB] Exploration d\'autres structures possibles...');

        // Chercher dans d'autres collections qui pourraient contenir des conditionnements
        final autresCollections = [
          'conditionnements',
          'stock_conditionne',
          'lots_conditionnes'
        ];

        for (final collectionName in autresCollections) {
          try {
            final snapshot =
                await _firestore.collection(collectionName).limit(5).get();
            if (snapshot.docs.isNotEmpty) {
              debugPrint(
                  '📊 [ConditionnementDB] Collection "$collectionName" trouvée avec ${snapshot.docs.length} documents');
              // Ici on pourrait ajouter une logique de parsing spécifique si besoin
            }
          } catch (e) {
            debugPrint(
                '⚠️ [ConditionnementDB] Collection "$collectionName" non accessible: $e');
          }
        }
      } catch (e) {
        debugPrint(
            '❌ [ConditionnementDB] Erreur exploration autres structures: $e');
      }

      // Trier par date de conditionnement (plus récent en premier)
      conditionnements.sort(
          (a, b) => b.dateConditionnement.compareTo(a.dateConditionnement));

      _conditionnements.value = conditionnements;

      debugPrint('✅ [ConditionnementDB] RÉSUMÉ DU CHARGEMENT:');
      debugPrint('   📊 Structure moderne: $totalModerne documents trouvés');
      debugPrint('   📊 Structure legacy: $totalLegacy documents trouvés');
      debugPrint(
          '   📊 Total conditionnements chargés: ${conditionnements.length}');

      if (conditionnements.isNotEmpty) {
        debugPrint('   🎯 Premiers conditionnements:');
        for (final cond in conditionnements.take(3)) {
          debugPrint(
              '     - ${cond.lotOrigine.lotOrigine} (${cond.dateConditionnement.day}/${cond.dateConditionnement.month}) - ${cond.quantiteConditionnee}kg');
        }
      } else {
        debugPrint('   ⚠️ Aucun conditionnement trouvé dans aucune structure');
      }
    } catch (e) {
      debugPrint(
          '❌ [ConditionnementDB] Erreur générale chargement conditionnements: $e');
    }
  }

  /// 🔄 RECHARGEMENT FORCÉ DES DONNÉES
  Future<void> refreshData() async {
    await _loadLotsDisponibles();
    await _loadConditionnements();
  }

  /// 🏢 DÉTERMINATION DES SITES AUTORISÉS SELON LE RÔLE
  List<String> _getSitesAutorises() {
    final userRole = _userSession.role?.toLowerCase() ?? '';
    final userSite = _userSession.site ?? '';

    // Admin voit tous les sites
    if (userRole == 'admin') {
      return sites;
    }

    // Conditionneur voit seulement son site
    if (userRole == 'conditionneur') {
      return userSite.isNotEmpty ? [userSite] : [];
    }

    // Autres rôles : pas d'accès
    return [];
  }

  /// 🔄 CONVERSION DES FILTERED_PRODUCTS EN LOT FILTRÉ
  Future<LotFiltre?> _convertirFilteredProductsEnLot(
      List<DocumentSnapshot> produits, String site) async {
    try {
      if (produits.isEmpty) return null;

      final premierProduit = produits.first.data() as Map<String, dynamic>;

      // Calculer les quantités totales
      double quantiteTotale = 0.0;
      String predominanceFlorale = 'Mille fleurs';
      DateTime? dateFiltrage;
      String technicien = 'Inconnu';

      for (final doc in produits) {
        final data = doc.data() as Map<String, dynamic>;
        quantiteTotale += (data['poids_filtre'] ?? 0.0).toDouble();

        // Récupérer la prédominance florale
        final florale = data['predominance_florale']?.toString() ?? '';
        if (florale.isNotEmpty && predominanceFlorale == 'Mille fleurs') {
          predominanceFlorale = florale;
        }

        // Récupérer la date de filtrage
        final dateFin = data['date_fin_filtrage']?.toString();
        if (dateFin != null && dateFiltrage == null) {
          try {
            dateFiltrage = DateTime.parse(dateFin);
          } catch (e) {
            debugPrint('⚠️ Erreur parsing date_fin_filtrage: $e');
          }
        }

        // Récupérer le technicien
        final tech = data['attributeur']?.toString();
        if (tech != null && technicien == 'Inconnu') {
          technicien = tech;
        }
      }

      // 🔥 VÉRIFICATION INTELLIGENTE : Vérifier si le lot est déjà conditionné dans TOUTES les collections
      bool estConditionne = false;
      DateTime? dateConditionnementExistant;

      // Vérifier dans la structure moderne par site
      for (final siteCheck in _getSitesAutorises()) {
        final conditionnementExistant = await _firestore
            .collection('conditionnement')
            .doc(siteCheck)
            .collection('conditionnements')
            .where('lotFiltrageId', isEqualTo: premierProduit['code_contenant'])
            .limit(1)
            .get();

        if (conditionnementExistant.docs.isNotEmpty) {
          estConditionne = true;
          // Récupérer la date de conditionnement
          final data = conditionnementExistant.docs.first.data();
          if (data['date'] != null) {
            dateConditionnementExistant = (data['date'] as Timestamp).toDate();
          }
          break;
        }
      }

      // Vérifier aussi dans l'ancienne structure (compatibilité)
      if (!estConditionne) {
        final conditionnementExistantLegacy = await _firestore
            .collection('conditionnement')
            .where('lotFiltrageId', isEqualTo: premierProduit['code_contenant'])
            .limit(1)
            .get();
        if (conditionnementExistantLegacy.docs.isNotEmpty) {
          estConditionne = true;
          // Récupérer la date de conditionnement
          final data = conditionnementExistantLegacy.docs.first.data();
          if (data['date'] != null) {
            dateConditionnementExistant = (data['date'] as Timestamp).toDate();
          }
        }
      }

      final quantiteRestante = estConditionne ? 0.0 : quantiteTotale;

      final lot = LotFiltre(
        id: premierProduit['code_contenant'] ??
            'LOT-${DateTime.now().millisecondsSinceEpoch}',
        lotOrigine: premierProduit['code_contenant'] ??
            'LOT-${DateTime.now().millisecondsSinceEpoch}',
        collecteId: premierProduit['collecte_id'] ?? '',
        quantiteRecue: quantiteTotale,
        quantiteRestante: quantiteRestante,
        predominanceFlorale: predominanceFlorale,
        dateFiltrage: dateFiltrage ?? DateTime.now(),
        dateExpirationFiltrage:
            _calculerDateExpiration(dateFiltrage ?? DateTime.now()),
        estConditionne: estConditionne,
        dateConditionnement: dateConditionnementExistant,
        site: site,
        technicien: technicien,
      );

      debugPrint(
          '   ✅ Lot ${lot.lotOrigine} (filtered_products): ${lot.quantiteRecue}kg, '
          'Peut être conditionné: ${lot.peutEtreConditionne}');

      return lot;
    } catch (e) {
      debugPrint('❌ Erreur conversion filtered_products: $e');
      return null;
    }
  }

  /// 🔄 CONVERSION D'UN DOCUMENT FILTRAGE EN LOT FILTRÉ
  Future<LotFiltre?> _convertirFiltrageEnLot(
      DocumentSnapshot doc, String site) async {
    try {
      final data = doc.data() as Map<String, dynamic>;

      // Récupérer les produits filtrés pour calculer les quantités
      final produitsSnapshot =
          await doc.reference.collection('produits_filtres').get();

      double quantiteTotale = 0.0;
      String predominanceFlorale = 'Mille fleurs';

      for (final produitDoc in produitsSnapshot.docs) {
        final produitData = produitDoc.data();
        quantiteTotale += (produitData['quantiteFiltree'] ?? 0.0).toDouble();

        // Déterminer la prédominance florale depuis les données originales
        final donneesOriginales =
            produitData['donneesOriginales'] as Map<String, dynamic>? ?? {};
        final florale =
            donneesOriginales['predominanceFlorale']?.toString() ?? '';
        if (florale.isNotEmpty && predominanceFlorale == 'Mille fleurs') {
          predominanceFlorale = florale;
        }
      }

      // 🔥 VÉRIFICATION INTELLIGENTE : Vérifier si le lot est déjà conditionné dans TOUTES les collections
      bool estConditionne = false;
      DateTime? dateConditionnementExistant;

      // Vérifier dans la structure moderne par site
      for (final siteCheck in _getSitesAutorises()) {
        final conditionnementExistant = await _firestore
            .collection('conditionnement')
            .doc(siteCheck)
            .collection('conditionnements')
            .where('lotFiltrageId', isEqualTo: doc.id)
            .limit(1)
            .get();

        if (conditionnementExistant.docs.isNotEmpty) {
          estConditionne = true;
          // Récupérer la date de conditionnement
          final dataConditionnement = conditionnementExistant.docs.first.data();
          if (dataConditionnement['date'] != null) {
            dateConditionnementExistant =
                (dataConditionnement['date'] as Timestamp).toDate();
          }
          break;
        }
      }

      // Vérifier aussi dans l'ancienne structure (compatibilité)
      if (!estConditionne) {
        final conditionnementExistantLegacy = await _firestore
            .collection('conditionnement')
            .where('lotFiltrageId', isEqualTo: doc.id)
            .limit(1)
            .get();
        if (conditionnementExistantLegacy.docs.isNotEmpty) {
          estConditionne = true;
          // Récupérer la date de conditionnement
          final dataConditionnement =
              conditionnementExistantLegacy.docs.first.data();
          if (dataConditionnement['date'] != null) {
            dateConditionnementExistant =
                (dataConditionnement['date'] as Timestamp).toDate();
          }
        }
      }

      final quantiteRestante = estConditionne ? 0.0 : quantiteTotale;

      final lot = LotFiltre(
        id: doc.id,
        lotOrigine: data['numeroLot'] ?? doc.id,
        collecteId: data['collecteId'] ?? '',
        quantiteRecue: quantiteTotale,
        quantiteRestante: quantiteRestante,
        predominanceFlorale: predominanceFlorale,
        dateFiltrage:
            (data['dateFiltrage'] as Timestamp?)?.toDate() ?? DateTime.now(),
        dateExpirationFiltrage: _calculerDateExpiration(data['dateFiltrage']),
        estConditionne: estConditionne,
        dateConditionnement: dateConditionnementExistant,
        site: site,
        technicien: data['utilisateur'] ?? 'Inconnu',
      );

      debugPrint('   ✅ Lot ${lot.lotOrigine}: ${lot.quantiteRecue}kg, '
          'Peut être conditionné: ${lot.peutEtreConditionne}');

      return lot;
    } catch (e) {
      debugPrint('❌ Erreur conversion lot ${doc.id}: $e');
      return null;
    }
  }

  /// 📅 CALCUL DE LA DATE D'EXPIRATION (30 jours par défaut)
  String? _calculerDateExpiration(dynamic dateFiltrage) {
    if (dateFiltrage == null) return null;

    DateTime date;
    if (dateFiltrage is Timestamp) {
      date = dateFiltrage.toDate();
    } else if (dateFiltrage is DateTime) {
      date = dateFiltrage;
    } else {
      return null;
    }

    final dateExpiration = date.add(const Duration(days: 30));
    return dateExpiration.toIso8601String();
  }

  /// 📊 MISE À JOUR DES STATISTIQUES DU SITE
  Future<void> _updateStatistiquesSite(WriteBatch batch, String site,
      ConditionnementData conditionnement) async {
    try {
      final statsRef = _firestore
          .collection('conditionnement')
          .doc(site)
          .collection('statistiques')
          .doc('global');

      // Récupérer les statistiques actuelles
      final statsDoc = await statsRef.get();
      final currentStats = statsDoc.exists
          ? statsDoc.data() as Map<String, dynamic>
          : <String, dynamic>{};

      // Calculer les nouvelles statistiques
      final newStats = {
        'totalConditionnements':
            (currentStats['totalConditionnements'] ?? 0) + 1,
        'quantiteTotaleConditionnee':
            (currentStats['quantiteTotaleConditionnee'] ?? 0.0) +
                conditionnement.quantiteConditionnee,
        'valeurTotaleConditionnee':
            (currentStats['valeurTotaleConditionnee'] ?? 0.0) +
                conditionnement.prixTotal,
        'nombreTotalPots': (currentStats['nombreTotalPots'] ?? 0) +
            conditionnement.nbTotalPots,
        'derniereMiseAJour': Timestamp.fromDate(DateTime.now()),
        'site': site,
      };

      // Mettre à jour les statistiques par type de florale
      final predominance = conditionnement.lotOrigine.predominanceFlorale;
      final floraleStats =
          currentStats['repartitionFlorale'] as Map<String, dynamic>? ?? {};
      floraleStats[predominance] = {
        'nombre': (floraleStats[predominance]?['nombre'] ?? 0) + 1,
        'quantite': (floraleStats[predominance]?['quantite'] ?? 0.0) +
            conditionnement.quantiteConditionnee,
        'valeur': (floraleStats[predominance]?['valeur'] ?? 0.0) +
            conditionnement.prixTotal,
      };
      newStats['repartitionFlorale'] = floraleStats;

      // Mettre à jour les statistiques par emballage
      final emballageStats =
          currentStats['repartitionEmballages'] as Map<String, dynamic>? ?? {};
      for (final emballage in conditionnement.emballages) {
        final type = emballage.type.nom;
        emballageStats[type] = {
          'nombre': (emballageStats[type]?['nombre'] ?? 0) +
              emballage.nombreUnitesReelles,
          'quantite':
              (emballageStats[type]?['quantite'] ?? 0.0) + emballage.poidsTotal,
          'valeur':
              (emballageStats[type]?['valeur'] ?? 0.0) + emballage.prixTotal,
        };
      }
      newStats['repartitionEmballages'] = emballageStats;

      batch.set(statsRef, newStats, SetOptions(merge: true));

      debugPrint(
          '✅ [ConditionnementDB] Statistiques du site $site mises à jour');
    } catch (e) {
      debugPrint('❌ [ConditionnementDB] Erreur mise à jour statistiques: $e');
    }
  }

  /// 💾 ENREGISTREMENT D'UN CONDITIONNEMENT
  Future<String> enregistrerConditionnement(
      ConditionnementData conditionnement) async {
    try {
      debugPrint('🔄 [ConditionnementDB] Enregistrement du conditionnement...');

      // Validation stricte
      final erreurs =
          ConditionnementUtils.validerConditionnement(conditionnement);
      if (erreurs.isNotEmpty) {
        throw Exception('Validation échouée: ${erreurs.join(', ')}');
      }

      // 🔥 VÉRIFICATION INTELLIGENTE : Permettre la mise à jour ou confirmer le remplacement
      final conditionnementExistant = await _firestore
          .collection('conditionnement')
          .doc(conditionnement.lotOrigine.site)
          .collection('conditionnements')
          .where('lotFiltrageId', isEqualTo: conditionnement.lotOrigine.id)
          .limit(1)
          .get();

      // Si un conditionnement existe déjà, on remplace plutôt que de bloquer
      String? conditionnementIdExistant;
      if (conditionnementExistant.docs.isNotEmpty) {
        conditionnementIdExistant = conditionnementExistant.docs.first.id;
        debugPrint(
            '⚠️ [ConditionnementDB] Lot déjà conditionné, mise à jour du conditionnement existant: $conditionnementIdExistant');
      }

      // Transaction pour garantir la cohérence
      final batch = _firestore.batch();

      // 1. Enregistrer ou mettre à jour le conditionnement
      final conditionnementRef = _firestore
          .collection('conditionnement')
          .doc(conditionnement.lotOrigine.site)
          .collection('conditionnements')
          .doc(
              conditionnementIdExistant); // Utilise l'ID existant si disponible, sinon Firestore génère un nouveau

      // Utiliser set avec merge:true pour mettre à jour ou créer
      batch.set(conditionnementRef, conditionnement.toFirestore(),
          SetOptions(merge: true));

      // 2. Mettre à jour les statistiques du site
      await _updateStatistiquesSite(
          batch, conditionnement.lotOrigine.site, conditionnement);

      // 3. 🚀 NOUVEAU : Marquer le lot comme conditionné et le déplacer
      await _marquerLotCommeConditionne(batch, conditionnement);

      // 4. 🚀 NOUVEAU : Créer les données pour stocks conditionnés
      await _creerStockConditionne(batch, conditionnement);

      // 5. 🚀 NOUVEAU : Générer les données analytiques (avec l'ID généré)
      await _genererDonneesAnalytiques(
          batch, conditionnement, conditionnementRef.id);

      // 6. Mettre à jour le document filtrage
      final filtrageRef = _firestore
          .collection('Filtrage')
          .doc(conditionnement.lotOrigine.site)
          .collection('processus')
          .doc(conditionnement.lotOrigine.id);

      batch.update(filtrageRef, {
        'statutConditionnement': 'Conditionné',
        'dateConditionnement':
            Timestamp.fromDate(conditionnement.dateConditionnement),
        'quantiteConditionnee': conditionnement.quantiteConditionnee,
        'quantiteRestante': conditionnement.quantiteRestante,
        'conditionnementId': conditionnementRef.id,
      });

      // Exécuter la transaction
      await batch.commit();

      // Recharger les données
      await refreshData();

      debugPrint(
          '✅ [ConditionnementDB] Conditionnement enregistré avec ID: ${conditionnementRef.id}');
      return conditionnementRef.id;
    } catch (e) {
      debugPrint('❌ [ConditionnementDB] Erreur enregistrement: $e');
      rethrow;
    }
  }

  /// 📊 STATISTIQUES DU CONDITIONNEMENT
  Future<Map<String, dynamic>> getStatistiques() async {
    try {
      debugPrint('🔄 [ConditionnementDB] Calcul des statistiques...');

      final lotsDisponibles =
          _lotsDisponibles.where((lot) => lot.peutEtreConditionne).toList();
      final conditionnements = _conditionnements;

      final stats = {
        'lotsDisponibles': lotsDisponibles.length,
        'lotsConditionnes': conditionnements.length,
        'quantiteTotaleDisponible': lotsDisponibles.fold<double>(
            0, (sum, lot) => sum + lot.quantiteRestante),
        'quantiteTotaleConditionnee': conditionnements.fold<double>(
            0, (sum, cond) => sum + cond.quantiteConditionnee),
        'valeurTotaleConditionnee': conditionnements.fold<double>(
            0, (sum, cond) => sum + cond.prixTotal),
        'nombreTotalPots': conditionnements.fold<int>(
            0, (sum, cond) => sum + cond.nbTotalPots),

        // Répartition par type de florale
        'repartitionFlorale': _calculerRepartitionFlorale(conditionnements),

        // Emballages populaires
        'emballagesPopulaires': _calculerEmballagesPopulaires(conditionnements),

        // Répartition par site
        'repartitionParSite': _calculerRepartitionParSite(conditionnements),

        // Évolution mensuelle
        'evolutionMensuelle': _calculerEvolutionMensuelle(conditionnements),
      };

      debugPrint('✅ [ConditionnementDB] Statistiques calculées');
      return stats;
    } catch (e) {
      debugPrint('❌ [ConditionnementDB] Erreur calcul statistiques: $e');
      return {};
    }
  }

  /// Calcule la répartition par type de florale
  Map<String, dynamic> _calculerRepartitionFlorale(
      List<ConditionnementData> conditionnements) {
    final repartition = <TypeFlorale, Map<String, dynamic>>{};

    for (final conditionnement in conditionnements) {
      final type = conditionnement.lotOrigine.typeFlorale;
      repartition[type] ??= {
        'nombre': 0,
        'quantite': 0.0,
        'valeur': 0.0,
      };

      repartition[type]!['nombre'] += 1;
      repartition[type]!['quantite'] += conditionnement.quantiteConditionnee;
      repartition[type]!['valeur'] += conditionnement.prixTotal;
    }

    return repartition.map((type, data) => MapEntry(type.label, data));
  }

  /// Calcule les emballages les plus populaires
  Map<String, int> _calculerEmballagesPopulaires(
      List<ConditionnementData> conditionnements) {
    final popularite = <String, int>{};

    for (final conditionnement in conditionnements) {
      for (final emballage in conditionnement.emballages) {
        popularite[emballage.type.nom] = (popularite[emballage.type.nom] ?? 0) +
            emballage.nombreUnitesReelles;
      }
    }

    // Trier par popularité
    final sorted = Map.fromEntries(popularite.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)));

    return sorted;
  }

  /// Calcule la répartition par site
  Map<String, int> _calculerRepartitionParSite(
      List<ConditionnementData> conditionnements) {
    final repartition = <String, int>{};

    for (final conditionnement in conditionnements) {
      final site = conditionnement.lotOrigine.site;
      repartition[site] = (repartition[site] ?? 0) + 1;
    }

    return repartition;
  }

  /// Calcule l'évolution mensuelle
  Map<String, dynamic> _calculerEvolutionMensuelle(
      List<ConditionnementData> conditionnements) {
    final evolutionMensuelle = <String, Map<String, dynamic>>{};

    for (final conditionnement in conditionnements) {
      final moisKey = '${conditionnement.dateConditionnement.year}-'
          '${conditionnement.dateConditionnement.month.toString().padLeft(2, '0')}';

      evolutionMensuelle[moisKey] ??= {
        'nombre': 0,
        'quantite': 0.0,
        'valeur': 0.0,
      };

      evolutionMensuelle[moisKey]!['nombre'] += 1;
      evolutionMensuelle[moisKey]!['quantite'] +=
          conditionnement.quantiteConditionnee;
      evolutionMensuelle[moisKey]!['valeur'] += conditionnement.prixTotal;
    }

    return evolutionMensuelle;
  }

  /// 🔄 STREAM EN TEMPS RÉEL DES LOTS DISPONIBLES
  Stream<List<LotFiltre>> streamLotsDisponibles() {
    final sitesAutorises = _getSitesAutorises();

    if (sitesAutorises.isEmpty) {
      return Stream.value([]);
    }

    // Pour l'instant, on utilise un stream simple
    // TODO: Implémenter un vrai stream multi-collections
    return Stream.periodic(const Duration(seconds: 30)).asyncMap((_) async {
      await _loadLotsDisponibles();
      return _lotsDisponibles.where((lot) => lot.peutEtreConditionne).toList();
    });
  }

  /// 🗑️ SUPPRESSION D'UN CONDITIONNEMENT (ADMIN SEULEMENT)
  Future<void> supprimerConditionnement(String conditionnementId) async {
    try {
      // Vérifier les permissions
      if (_userSession.role?.toLowerCase() != 'admin') {
        throw Exception(
            'Seuls les administrateurs peuvent supprimer un conditionnement');
      }

      debugPrint(
          '🗑️ [ConditionnementDB] Suppression du conditionnement $conditionnementId...');

      // Récupérer le conditionnement pour avoir l'ID du lot et le site
      // Chercher dans tous les sites autorisés
      final sitesAutorises = _getSitesAutorises();
      DocumentSnapshot? conditionnementDoc;
      String? site;

      for (final siteName in sitesAutorises) {
        final doc = await _firestore
            .collection('conditionnement')
            .doc(siteName)
            .collection('conditionnements')
            .doc(conditionnementId)
            .get();

        if (doc.exists) {
          conditionnementDoc = doc;
          site = siteName;
          break;
        }
      }

      if (conditionnementDoc == null || site == null) {
        throw Exception('Conditionnement introuvable');
      }

      final conditionnementData =
          conditionnementDoc.data() as Map<String, dynamic>;
      final lotId = conditionnementData['lotFiltrageId'];

      // Transaction pour garantir la cohérence
      final batch = _firestore.batch();

      // 1. Supprimer le conditionnement
      batch.delete(_firestore
          .collection('conditionnement')
          .doc(site)
          .collection('conditionnements')
          .doc(conditionnementId));

      // 2. Remettre à jour le statut du lot filtrage
      if (lotId != null) {
        batch.update(
          _firestore
              .collection('Filtrage')
              .doc(site)
              .collection('processus')
              .doc(lotId),
          {
            'statutConditionnement': FieldValue.delete(),
            'dateConditionnement': FieldValue.delete(),
            'quantiteConditionnee': FieldValue.delete(),
            'conditionnementId': FieldValue.delete(),
          },
        );
      }

      await batch.commit();

      // Recharger les données
      await refreshData();

      debugPrint('✅ [ConditionnementDB] Conditionnement supprimé avec succès');
    } catch (e) {
      debugPrint('❌ [ConditionnementDB] Erreur suppression: $e');
      rethrow;
    }
  }

  /// 📊 RÉCUPÉRATION D'UN CONDITIONNEMENT PAR LOT ID
  Future<ConditionnementData?> getConditionnementByLotId(String lotId) async {
    try {
      final sitesAutorises = _getSitesAutorises();

      for (final site in sitesAutorises) {
        final snapshot = await _firestore
            .collection('conditionnement')
            .doc(site)
            .collection('conditionnements')
            .where('lotFiltrageId', isEqualTo: lotId)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          return ConditionnementData.fromFirestore(snapshot.docs.first);
        }
      }

      return null;
    } catch (e) {
      debugPrint(
          '❌ [ConditionnementDB] Erreur récupération conditionnement pour lot $lotId: $e');
      return null;
    }
  }

  /// 📊 RÉCUPÉRATION D'UN LOT SPÉCIFIQUE
  Future<LotFiltre?> getLotById(String lotId) async {
    try {
      // Chercher dans les lots déjà chargés
      final lotExistant =
          _lotsDisponibles.firstWhereOrNull((lot) => lot.id == lotId);
      if (lotExistant != null) {
        return lotExistant;
      }

      // Si pas trouvé, chercher dans la base de données
      final sitesAutorises = _getSitesAutorises();

      for (final site in sitesAutorises) {
        final doc = await _firestore
            .collection('Filtrage')
            .doc(site)
            .collection('processus')
            .doc(lotId)
            .get();

        if (doc.exists) {
          return await _convertirFiltrageEnLot(doc, site);
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ [ConditionnementDB] Erreur récupération lot $lotId: $e');
      return null;
    }
  }

  /// 📊 RÉCUPÉRATION DES STATISTIQUES D'UN SITE
  Future<Map<String, dynamic>?> getStatistiquesSite(String site) async {
    try {
      final statsDoc = await _firestore
          .collection('conditionnement')
          .doc(site)
          .collection('statistiques')
          .doc('global')
          .get();

      if (statsDoc.exists) {
        return statsDoc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint(
          '❌ [ConditionnementDB] Erreur récupération statistiques site $site: $e');
      return null;
    }
  }

  /// 📊 RÉCUPÉRATION DES STATISTIQUES GLOBALES (TOUS SITES)
  Future<Map<String, dynamic>> getStatistiquesGlobales() async {
    try {
      final sitesAutorises = _getSitesAutorises();
      final statsGlobales = <String, dynamic>{
        'totalConditionnements': 0,
        'quantiteTotaleConditionnee': 0.0,
        'valeurTotaleConditionnee': 0.0,
        'nombreTotalPots': 0,
        'repartitionParSite': <String, Map<String, dynamic>>{},
        'repartitionFlorale': <String, Map<String, dynamic>>{},
        'repartitionEmballages': <String, Map<String, dynamic>>{},
      };

      for (final site in sitesAutorises) {
        final statsSite = await getStatistiquesSite(site);
        if (statsSite != null) {
          statsGlobales['totalConditionnements'] +=
              statsSite['totalConditionnements'] ?? 0;
          statsGlobales['quantiteTotaleConditionnee'] +=
              statsSite['quantiteTotaleConditionnee'] ?? 0.0;
          statsGlobales['valeurTotaleConditionnee'] +=
              statsSite['valeurTotaleConditionnee'] ?? 0.0;
          statsGlobales['nombreTotalPots'] += statsSite['nombreTotalPots'] ?? 0;

          statsGlobales['repartitionParSite'][site] = statsSite;

          // Agréger les statistiques florales
          final floraleSite =
              statsSite['repartitionFlorale'] as Map<String, dynamic>? ?? {};
          for (final entry in floraleSite.entries) {
            final type = entry.key;
            final data = entry.value as Map<String, dynamic>;
            statsGlobales['repartitionFlorale'][type] ??= {
              'nombre': 0,
              'quantite': 0.0,
              'valeur': 0.0,
            };
            statsGlobales['repartitionFlorale'][type]['nombre'] +=
                data['nombre'] ?? 0;
            statsGlobales['repartitionFlorale'][type]['quantite'] +=
                data['quantite'] ?? 0.0;
            statsGlobales['repartitionFlorale'][type]['valeur'] +=
                data['valeur'] ?? 0.0;
          }

          // Agréger les statistiques d'emballages
          final emballageSite =
              statsSite['repartitionEmballages'] as Map<String, dynamic>? ?? {};
          for (final entry in emballageSite.entries) {
            final type = entry.key;
            final data = entry.value as Map<String, dynamic>;
            statsGlobales['repartitionEmballages'][type] ??= {
              'nombre': 0,
              'quantite': 0.0,
              'valeur': 0.0,
            };
            statsGlobales['repartitionEmballages'][type]['nombre'] +=
                data['nombre'] ?? 0;
            statsGlobales['repartitionEmballages'][type]['quantite'] +=
                data['quantite'] ?? 0.0;
            statsGlobales['repartitionEmballages'][type]['valeur'] +=
                data['valeur'] ?? 0.0;
          }
        }
      }

      return statsGlobales;
    } catch (e) {
      debugPrint(
          '❌ [ConditionnementDB] Erreur récupération statistiques globales: $e');
      return {};
    }
  }

  /// 🚀 NOUVELLE MÉTHODE : Marque un lot selon le type de conditionnement (complet ou partiel)
  Future<void> _marquerLotCommeConditionne(
      WriteBatch batch, ConditionnementData conditionnement) async {
    try {
      debugPrint(
          '📋 [ConditionnementDB] Marquage lot ${conditionnement.lotOrigine.id}...');

      // Mettre à jour le document filtrage
      final filtrageRef = _firestore
          .collection('Filtrage')
          .doc(conditionnement.lotOrigine.site)
          .collection('processus')
          .doc(conditionnement.lotOrigine.id);

      // 🔄 VÉRIFIER SI CONDITIONNEMENT COMPLET OU PARTIEL
      final quantiteRestante = conditionnement.quantiteRestante;
      final estConditionnementComplet =
          quantiteRestante <= 0.1; // Tolérance de 100g

      if (estConditionnementComplet) {
        // ✅ CONDITIONNEMENT COMPLET : Masquer le lot
        debugPrint(
            '✅ [ConditionnementDB] Conditionnement COMPLET - Lot retiré de la liste');
        batch.update(filtrageRef, {
          'statutConditionnement': 'Conditionné_Complet',
          'dateConditionnement':
              Timestamp.fromDate(conditionnement.dateConditionnement),
          'quantiteConditionnee': conditionnement.quantiteConditionnee,
          'quantiteRestante': 0.0,
          'isVisible': false, // 🚫 Masquer de la liste
          'movedToStock': true, // ✅ Déplacé vers stocks
          'conditionnementComplete': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // 🔄 CONDITIONNEMENT PARTIEL : Garder le lot visible avec quantité mise à jour
        debugPrint(
            '🔄 [ConditionnementDB] Conditionnement PARTIEL - Lot maintenu avec ${quantiteRestante.toStringAsFixed(2)}kg restants');
        batch.update(filtrageRef, {
          'statutConditionnement': 'Conditionné_Partiel',
          'dateDernierConditionnement':
              Timestamp.fromDate(conditionnement.dateConditionnement),
          'quantiteConditionneeTotal':
              FieldValue.increment(conditionnement.quantiteConditionnee),
          'quantiteRestante':
              quantiteRestante, // 🔄 Nouvelle quantité disponible
          'quantiteRecue':
              quantiteRestante, // 🔄 Mettre à jour la quantité "reçue" avec le restant
          'isVisible': true, // ✅ Garder visible dans la liste
          'movedToStock': false, // ❌ Pas encore déplacé complètement
          'conditionnementPartiel': true,
          'nbConditionnementsPartiels': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      debugPrint(
          '✅ [ConditionnementDB] Lot marqué selon le type de conditionnement');
    } catch (e) {
      debugPrint('❌ [ConditionnementDB] Erreur marquage lot: $e');
      throw Exception('Erreur lors du marquage du lot: $e');
    }
  }

  /// 🚀 NOUVELLE MÉTHODE : Crée les données dans la collection stocks conditionnés
  Future<void> _creerStockConditionne(
      WriteBatch batch, ConditionnementData conditionnement) async {
    try {
      debugPrint('📦 [ConditionnementDB] Création stock conditionné...');

      // Créer une entrée dans la collection stocks conditionnés
      final stockRef = _firestore
          .collection('StocksConditionnes')
          .doc(conditionnement.lotOrigine.site)
          .collection('stocks')
          .doc(); // Auto-générer un ID

      /// 🔥 STOCK ULTRA-OPTIMISÉ : Seulement l'essentiel (économie Firestore)
      final stockData = {
        // 🔗 RÉFÉRENCES MINIMALES
        'lotId': conditionnement.lotOrigine.id,
        'lot': conditionnement.lotOrigine.lotOrigine,

        // 🍯 MIEL
        'florale': conditionnement.lotOrigine.predominanceFlorale,
        'type': conditionnement.lotOrigine.typeFlorale.label,

        // 📊 QUANTITÉS ESSENTIELLES
        'kg': conditionnement.quantiteConditionnee,
        'pots': conditionnement.nbTotalPots,
        'prix': conditionnement.prixTotal,

        // 📦 EMBALLAGES (format ultra-compact)
        'emb': conditionnement.emballages
            .map((e) => '${e.type.nom}:${e.nombreSaisi}')
            .join(','),

        // 📅 TEMPS & STATUT
        'date': Timestamp.fromDate(conditionnement.dateConditionnement),
        'dispo': true, // Disponible pour vente
      };

      batch.set(stockRef, stockData);
      debugPrint(
          '✅ [ConditionnementDB] Stock conditionné créé avec ID: ${stockRef.id}');
    } catch (e) {
      debugPrint('❌ [ConditionnementDB] Erreur création stock conditionné: $e');
      throw Exception('Erreur lors de la création du stock: $e');
    }
  }

  /// 🚀 NOUVELLE MÉTHODE : Génère les données analytiques pour rapports
  Future<void> _genererDonneesAnalytiques(WriteBatch batch,
      ConditionnementData conditionnement, String conditionnementId) async {
    try {
      debugPrint('📈 [ConditionnementDB] Génération données analytiques...');

      // Créer une entrée dans la collection rapports analytiques
      final rapportRef = _firestore
          .collection('RapportsAnalytiques')
          .doc(conditionnement.lotOrigine.site)
          .collection('conditionnements')
          .doc(conditionnementId); // 🔧 Utiliser l'ID généré par Firestore

      final analyticsData = {
        /// 🔥 ANALYTICS ULTRA-OPTIMISÉ : Métriques essentielles seulement (économie Firestore)
        // 📅 TEMPS (format compact)
        'mois': conditionnement.dateConditionnement.month,
        'annee': conditionnement.dateConditionnement.year,

        // 📊 MÉTRIQUES CLÉS SEULEMENT
        'kg': conditionnement.quantiteConditionnee,
        'pots': conditionnement.nbTotalPots,
        'prix': conditionnement.prixTotal,
        'rendement': ((conditionnement.quantiteConditionnee /
                    conditionnement.lotOrigine.quantiteRecue) *
                100)
            .round(),

        // 🍯 CARACTÉRISTIQUES ESSENTIELLES
        'florale': conditionnement.lotOrigine.typeFlorale.label,
        'embTop': _getEmballageLePlusUtilise(conditionnement.emballages),
      };

      batch.set(rapportRef, analyticsData);
      debugPrint('✅ [ConditionnementDB] Données analytiques générées');
    } catch (e) {
      debugPrint(
          '❌ [ConditionnementDB] Erreur génération données analytiques: $e');
      throw Exception(
          'Erreur lors de la génération des données analytiques: $e');
    }
  }

  // 🔧 MÉTHODE UTILITAIRE POUR ANALYTICS OPTIMISÉ

  String _getEmballageLePlusUtilise(List<EmballageSelectionne> emballages) {
    if (emballages.isEmpty) return 'Aucun';

    // Trouver l'emballage avec le plus grand poids total
    var maxPoids = 0.0;
    var maxEmballage = '';

    for (final emballage in emballages) {
      final poids = emballage.nombreSaisi * emballage.type.contenanceKg;
      if (poids > maxPoids) {
        maxPoids = poids;
        maxEmballage = emballage.type.nom;
      }
    }

    return maxEmballage;
  }
}
