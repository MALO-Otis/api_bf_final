import 'dart:async';
import 'vente_service.dart';
import 'package:get/get.dart';
import '../models/vente_models.dart';
import 'package:flutter/foundation.dart';
import '../models/commercial_models.dart';
import '../../../authentication/user_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🏪 SERVICE COMMERCIAL ULTRA-OPTIMISÉ
///
/// Gestion des lots, attributions avec recalcul automatique et cache intelligent
/// Performance ultra-rapide avec pagination et indexation

class CommercialService extends GetxController {
  static final CommercialService _instance = CommercialService._internal();
  factory CommercialService() => _instance;
  CommercialService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserSession _userSession = Get.find<UserSession>();
  final VenteService _venteService = VenteService();

  // ============================================================================
  // 🚀 CACHE ET OPTIMISATION ULTRA
  // ============================================================================

  final RxList<LotProduit> _lotsCache = <LotProduit>[].obs;
  final RxList<AttributionPartielle> _attributionsCache =
      <AttributionPartielle>[].obs;
  final Rx<StatistiquesCommerciales?> _statsCache =
      Rx<StatistiquesCommerciales?>(null);

  // 🚀 OPTIMISATION : Statistiques précalculées pour affichage instantané
  final RxInt _nombreAttributionsPrecompute = 0.obs;
  final RxInt _nombreLotsAttribuesPrecompute = 0.obs;
  final RxDouble _valeurTotalePrecompute = 0.0.obs;
  final RxBool _statsPrecomputeReady = false.obs;

  // 👤 ADMINISTRATION : Gestion des rôles et impersonification
  final Rx<RoleUtilisateur> _roleUtilisateur = RoleUtilisateur.commercial.obs;
  final Rx<PermissionsAdmin?> _permissions = Rx<PermissionsAdmin?>(null);
  final Rx<ContexteImpersonification?> _contexteImpersonification =
      Rx<ContexteImpersonification?>(null);
  final RxList<Map<String, dynamic>> _commerciauxDisponibles =
      <Map<String, dynamic>>[].obs;

  DateTime? _lastCacheUpdate;
  final Duration _cacheDuration =
      const Duration(minutes: 2); // Cache ultra-rapide

  final RxBool _isLoading = false.obs;
  final RxString _searchText = ''.obs;
  final Rx<CriteresFiltrage> _criteresFiltrage = CriteresFiltrage().obs;

  // ============================================================================
  // ⚙️ VERROUS / FUTURES PARTAGÉS & DIAGNOSTICS (PHASE 2 OPTIMISATION)
  // ============================================================================
  Future<List<LotProduit>>? _ongoingLotsFuture; // déduplication chargement lots
  Future<StatistiquesCommerciales?>?
      _ongoingStatsFuture; // déduplication calcul stats
  DateTime? _lastStatsCompute; // dernière génération des stats détaillées
  static const Duration _statsTtl =
      Duration(seconds: 30); // validité stats détaillées

  int _fetchLotsCount = 0; // nombre de fetch lots effectués
  int _attributionsFetchCount = 0; // nombre de fetch attributions effectués
  int _statComputeCount = 0; // nombre de calculs statistiques détaillés
  int get fetchLotsCount => _fetchLotsCount;
  int get attributionsFetchCount => _attributionsFetchCount;
  int get statComputeCount => _statComputeCount;
  // Diagnostics supplémentaires pour l'UI
  Duration? get ageCacheLots => _lastCacheUpdate == null
      ? null
      : DateTime.now().difference(_lastCacheUpdate!);
  int get statistiquesComputations => _statComputeCount;

  // Logging contrôlé (désactiver en production si nécessaire)
  bool verboseLogs = true;
  void _log(String msg) {
    if (verboseLogs) debugPrint(msg);
  }

  // Valeurs agrégées instantanées (utiles pour des widgets légers)
  double get valeurStockTotale =>
      _lotsCache.fold(0.0, (s, l) => s + (l.quantiteInitiale * l.prixUnitaire));
  double get valeurAttribueeTotale =>
      _lotsCache.fold(0.0, (s, l) => s + l.valeurAttribuee);
  double get valeurRestanteTotale =>
      _lotsCache.fold(0.0, (s, l) => s + l.valeurRestante);

  // Getters réactifs
  List<LotProduit> get lots => _lotsCache;
  List<AttributionPartielle> get attributions => _attributionsCache;
  StatistiquesCommerciales? get statistiques => _statsCache.value;
  bool get isLoading => _isLoading.value;

  // 🚀 OPTIMISATION : Getters pour statistiques précalculées
  int get nombreAttributionsPrecompute => _nombreAttributionsPrecompute.value;
  int get nombreLotsAttribuesPrecompute => _nombreLotsAttribuesPrecompute.value;
  double get valeurTotalePrecompute => _valeurTotalePrecompute.value;
  bool get statsPrecomputeReady => _statsPrecomputeReady.value;

  // Getters observables pour l'UI
  RxInt get nombreAttributionsObs => _nombreAttributionsPrecompute;
  RxInt get nombreLotsAttribuesObs => _nombreLotsAttribuesPrecompute;
  RxDouble get valeurTotaleObs => _valeurTotalePrecompute;
  // Getter Rx pour l'état de readiness (utilisé par l'UI: statsPrecomputeReadyObs)
  RxBool get statsPrecomputeReadyObs => _statsPrecomputeReady;

  // 👤 ADMINISTRATION : Getters pour les permissions et l'impersonification
  RoleUtilisateur get roleUtilisateur => _roleUtilisateur.value;
  PermissionsAdmin? get permissions => _permissions.value;
  ContexteImpersonification? get contexteImpersonification =>
      _contexteImpersonification.value;
  List<Map<String, dynamic>> get commerciauxDisponibles =>
      _commerciauxDisponibles;
  bool get estEnModeImpersonification =>
      _contexteImpersonification.value?.estActif == true;
  bool get estAdmin =>
      _roleUtilisateur.value == RoleUtilisateur.admin ||
      _roleUtilisateur.value == RoleUtilisateur.superviseur;

  // == AJOUT: liste filtrée réactive pour éviter de recalculer les lots dans l'UI ==
  final RxList<LotProduit> _filteredLots = <LotProduit>[].obs;
  List<LotProduit> get filteredLots => _filteredLots;

  // == AJOUT: debounce interne pour recherche ==
  Timer? _searchDebounce;

  // Collections centralisées (peuvent être déplacées dans un fichier séparé plus tard)
  // (Anciennes constantes de collection supprimées - accès direct par chaînes restantes)

  // ============================================================================
  // INITIALISATION
  // ============================================================================

  @override
  void onInit() {
    super.onInit();
    _initializeService();
  }

  void _initializeService() {
    _log('🚀 [CommercialService] Initialisation du service commercial...');

    // Auto-refresh cache périodique
    ever(_searchText, (_) => _applyFilters());
    ever(_criteresFiltrage, (_) => _applyFilters());
    // Recalcule la vue filtrée dès que le cache lots change (attribution / suppression / refresh)
    ever(_lotsCache, (_) => _applyFilters());

    // Nettoyage cache expiré toutes les 30 secondes
    Stream.periodic(const Duration(seconds: 30)).listen((_) {
      CacheCommercial.clearExpired();
    });

    // 🔧 CORRECTION : Charger immédiatement les données au démarrage
    Future.delayed(const Duration(milliseconds: 500), () {
      _initializeUserPermissions();
      getLotsAvecCache(forceRefresh: true);
    });

    // Initialiser filteredLots au démarrage
    _filteredLots.assignAll(_lotsCache);
  }

  // Debounce pour recherche
  void updateSearchText(String texte) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      _searchText.value = texte;
    });
  }

  // ============================================================================
  // 📦 GESTION DES LOTS AVEC RECALCUL AUTOMATIQUE
  // ============================================================================

  /// Récupère tous les lots avec mise en cache + déduplication concurrency
  Future<List<LotProduit>> getLotsAvecCache({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      if (_ongoingLotsFuture != null) {
        _log('♻️ Future lots réutilisée');
        return _ongoingLotsFuture!;
      }
      if (_lastCacheUpdate != null &&
          DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration) {
        _log('📱 Cache valide (${_lotsCache.length} lots)');
        return _lotsCache;
      }
    }

    final completer = Completer<List<LotProduit>>();
    _ongoingLotsFuture = completer.future;
    _fetchLotsCount++;
    try {
      _isLoading.value = true;
      _log('🔄 Chargement lots... (force=$forceRefresh)');

      final futures = await Future.wait([
        _venteService.getProduitsConditionnesTotalement(),
        _getAllAttributions(),
      ]);
      final produitsConditionnes = futures[0] as List<ProduitConditionne>;
      final toutesAttributions = futures[1] as List<AttributionPartielle>;

      final Map<String, List<ProduitConditionne>> produitsParLot = {};
      for (final p in produitsConditionnes) {
        final cleLot = '${p.numeroLot}_${p.typeEmballage}_${p.siteOrigine}';
        produitsParLot.putIfAbsent(cleLot, () => []).add(p);
      }
      final attributionsParLot = <String, List<AttributionPartielle>>{};
      for (final a in toutesAttributions) {
        attributionsParLot.putIfAbsent(a.lotId, () => []).add(a);
      }
      _attributionsCache.assignAll(toutesAttributions);
      _log('✅ Attributions: ${_attributionsCache.length}');
      _precomputeStatistiques();

      final List<LotProduit> lotsTemp = [];
      for (final entry in produitsParLot.entries) {
        final produits = entry.value;
        if (produits.isEmpty) continue;
        final ref = produits.first;
        final lotId = CommercialUtils.genererIdLot(
            ref.siteOrigine, ref.typeEmballage, ref.numeroLot);
        final attributions =
            attributionsParLot[lotId] ?? <AttributionPartielle>[];
        final quantiteInitiale =
            produits.fold<int>(0, (s, p) => s + p.quantiteInitiale);
        final quantiteAttribuee =
            attributions.fold<int>(0, (s, a) => s + a.quantiteAttribuee);
        final quantiteRestante = quantiteInitiale - quantiteAttribuee;
        StatutLot statut;
        if (quantiteRestante <= 0) {
          statut = StatutLot.completAttribue;
        } else if (quantiteAttribuee > 0) {
          statut = StatutLot.partielAttribue;
        } else {
          statut = StatutLot.disponible;
        }
        final diffJours = ref.dateExpiration.difference(DateTime.now()).inDays;
        if (diffJours <= 90 && diffJours > 0) statut = StatutLot.expire;
        lotsTemp.add(LotProduit(
          id: lotId,
          numeroLot: ref.numeroLot,
          siteOrigine: ref.siteOrigine,
          typeEmballage: ref.typeEmballage,
          predominanceFlorale: ref.predominanceFlorale,
          contenanceKg: ref.contenanceKg,
          prixUnitaire: ref.prixUnitaire,
          quantiteInitiale: quantiteInitiale,
          quantiteRestante: quantiteRestante,
          quantiteAttribuee: quantiteAttribuee,
          dateConditionnement: ref.dateConditionnement,
          dateExpiration: ref.dateExpiration,
          statut: statut,
          attributions: attributions,
          observations: ref.observations,
        ));
      }
      lotsTemp.sort(
          (a, b) => b.dateConditionnement.compareTo(a.dateConditionnement));
      _lotsCache.assignAll(lotsTemp);
      _lastCacheUpdate = DateTime.now();
      _applyFilters();
      CacheCommercial.set('lots_all', lotsTemp);
      _log('✅ Lots chargés: ${lotsTemp.length}');
      if (!completer.isCompleted) completer.complete(lotsTemp);
      return completer.future;
    } catch (e, st) {
      _log('❌ Erreur chargement lots: $e');
      _log('📍 $st');
      final cachedLots = CacheCommercial.get<List<LotProduit>>('lots_all');
      if (cachedLots != null) {
        _lotsCache.assignAll(cachedLots);
        if (!completer.isCompleted) completer.complete(cachedLots);
        return completer.future;
      }
      if (!completer.isCompleted) completer.complete([]);
      return completer.future;
    } finally {
      _isLoading.value = false;
      _ongoingLotsFuture = null;
    }
  }

  /// ⚡ OPTIMISÉ : Récupère TOUTES les attributions en parcourant les commerciaux connus
  Future<List<AttributionPartielle>> _getAllAttributions() async {
    try {
      final site = _userSession.site ?? 'Site_Inconnu';
      final List<AttributionPartielle> toutesLesAttributions = [];

      debugPrint(
          '🔍 [CommercialService] Récupération attributions pour site: $site');

      // Liste des commerciaux connus (basée sur PersonnelApisavana)
      final commerciauxConnus = [
        'yameogo_rose',
        'kansiemo_marceline',
        'yameogo_angeline',
        'bague_safiata',
        'kientega_sidonie',
        'bara_doukiatou',
        'semde_oumarou',
        'tapsoba_zonabou',
        'semde_karim',
        'yameogo_innocent',
        'zoungrana_hypolite',
      ];

      debugPrint(
          '🔍 [CommercialService] Recherche dans ${commerciauxConnus.length} commerciaux connus');

      // Récupérer les attributions de chaque commercial
      final futures = commerciauxConnus.map((commercialKey) async {
        try {
          final historiqueSnapshot = await _firestore
              .collection('Gestion Commercial')
              .doc(site)
              .collection('attributions')
              .doc(commercialKey)
              .collection('historique')
              .get();

          if (historiqueSnapshot.docs.isNotEmpty) {
            debugPrint(
                '🔍 [CommercialService] ${historiqueSnapshot.docs.length} attributions trouvées pour $commercialKey');

            final attributions = historiqueSnapshot.docs
                .map((doc) {
                  try {
                    final data = doc.data();
                    debugPrint(
                        '📄 [CommercialService] Attribution: ${data['commercialNom']} - ${data['quantiteAttribuee']} unités');
                    return AttributionPartielle.fromMap(data);
                  } catch (e) {
                    debugPrint(
                        '❌ [CommercialService] Erreur parsing attribution ${doc.id}: $e');
                    return null;
                  }
                })
                .where((attribution) => attribution != null)
                .cast<AttributionPartielle>()
                .toList();

            return attributions;
          }
          return <AttributionPartielle>[];
        } catch (e) {
          debugPrint(
              '❌ [CommercialService] Erreur récupération $commercialKey: $e');
          return <AttributionPartielle>[];
        }
      });

      // Attendre toutes les requêtes en parallèle
      final resultats = await Future.wait(futures);

      // Combiner tous les résultats
      for (final attributions in resultats) {
        toutesLesAttributions.addAll(attributions);
      }

      debugPrint(
          '⚡ [CommercialService] ${toutesLesAttributions.length} attributions récupérées en une fois pour le site $site');

      if (toutesLesAttributions.isNotEmpty) {
        debugPrint('🎯 [CommercialService] Premières attributions:');
        for (int i = 0; i < toutesLesAttributions.length && i < 3; i++) {
          final attr = toutesLesAttributions[i];
          debugPrint(
              '  - ${attr.commercialNom}: ${attr.quantiteAttribuee} x ${attr.typeEmballage} (${attr.valeurTotale} FCFA)');
        }
      }

      return toutesLesAttributions;
    } catch (e) {
      debugPrint(
          '❌ [CommercialService] Erreur récupération toutes attributions: $e');
      return [];
    }
  }

  // ============================================================================
  // 🎯 ATTRIBUTION AVEC RECALCUL AUTOMATIQUE
  // ============================================================================

  /// Attribue une quantité d'un lot à un commercial avec recalcul automatique
  Future<bool> attribuerLotCommercial({
    required String lotId,
    required String commercialId,
    required String commercialNom,
    required int quantiteAttribuee,
    String? motif,
  }) async {
    try {
      debugPrint(
          '🎯 [CommercialService] Attribution de $quantiteAttribuee unités du lot $lotId au commercial $commercialNom');

      final site = _userSession.site ?? 'Site_Inconnu';
      final gestionnaire = _userSession.email ?? 'Gestionnaire';

      // 1. Vérifier la disponibilité du lot
      final lot = _lotsCache.firstWhereOrNull((l) => l.id == lotId);
      if (lot == null) {
        debugPrint('❌ Lot non trouvé: $lotId');
        return false;
      }

      if (lot.quantiteRestante < quantiteAttribuee) {
        debugPrint(
            '❌ Quantité insuffisante. Demandé: $quantiteAttribuee, Disponible: ${lot.quantiteRestante}');
        return false;
      }

      // 2. Récupérer le nom du gestionnaire depuis la collection utilisateurs
      final gestionnaireNom = await _recupererNomGestionnaire(gestionnaire);

      // 3. Créer l'attribution complète avec tous les champs requis
      final attributionId = CommercialUtils.genererIdAttribution();
      final now = DateTime.now();
      final searchableText =
          '${lot.numeroLot} ${lot.siteOrigine} ${lot.typeEmballage} ${lot.predominanceFlorale}'
              .toLowerCase();

      final attribution = AttributionPartielle(
        id: attributionId,
        lotId: lotId,
        commercialId: commercialId,
        commercialNom: commercialNom,
        quantiteAttribuee: quantiteAttribuee,
        valeurUnitaire: lot.prixUnitaire,
        valeurTotale: quantiteAttribuee * lot.prixUnitaire,
        dateAttribution: now,
        gestionnaire: gestionnaireNom,
        motifModification: motif,
        // Nouveaux champs détaillés
        contenanceKg: lot.contenanceKg,
        dateConditionnement: lot.dateConditionnement,
        numeroLot: lot.numeroLot,
        predominanceFlorale: lot.predominanceFlorale,
        prixUnitaire: lot.prixUnitaire,
        quantiteInitiale: lot.quantiteInitiale,
        quantiteRestante: lot.quantiteRestante - quantiteAttribuee,
        searchableText: searchableText,
        siteOrigine: lot.siteOrigine,
        statut: lot.quantiteRestante - quantiteAttribuee <= 0
            ? 'completAttribue'
            : 'partielAttribue',
        typeEmballage: lot.typeEmballage,
        observations: lot.observations,
        lastUpdate: now,
      );

      // 4. Transaction atomique pour garantir la cohérence
      await _firestore.runTransaction((transaction) async {
        // Sauvegarder l'attribution dans la nouvelle structure : /attributions/{commercial}/
        final attributionRef = _firestore
            .collection('Gestion Commercial')
            .doc(site)
            .collection('attributions')
            .doc(commercialNom.replaceAll(' ', '_').toLowerCase())
            .collection('historique')
            .doc(attributionId);

        transaction.set(attributionRef, attribution.toMap());

        // Enregistrer/mettre à jour les informations du commercial dans /commerciaux/
        final commercialRef = _firestore
            .collection('Gestion Commercial')
            .doc('commerciaux')
            .collection('actifs')
            .doc(commercialNom.replaceAll(' ', '_').toLowerCase());

        final commercialData = {
          'nom': commercialNom,
          'site': site,
          'gestionnaire': gestionnaireNom,
          'dateCreation': FieldValue.serverTimestamp(),
          'derniereMiseAJour': FieldValue.serverTimestamp(),
          'statut': 'actif',
        };

        transaction.set(commercialRef, commercialData, SetOptions(merge: true));
      });

      // 5. Créer un prélèvement correspondant dans le système de vente (hors transaction)
      await _creerPrelevementDepuisAttribution(attribution, lot);

      // 6. Mettre à jour le cache local
      final index = _lotsCache.indexWhere((l) => l.id == lotId);
      if (index != -1) {
        final lotMisAJour = lot.copyWith(
          quantiteAttribuee: lot.quantiteAttribuee + quantiteAttribuee,
          quantiteRestante: lot.quantiteRestante - quantiteAttribuee,
          statut: lot.quantiteRestante - quantiteAttribuee <= 0
              ? StatutLot.completAttribue
              : StatutLot.partielAttribue,
          attributions: [...lot.attributions, attribution],
        );
        _lotsCache[index] = lotMisAJour;
      }

      // 7. Ajouter à la liste des attributions
      _attributionsCache.add(attribution);

      // 8. Invalider le cache des statistiques et recalculer
      _statsCache.value = null;
      CacheCommercial.clear('statistiques');

      // 🚀 OPTIMISATION : Mettre à jour les statistiques précalculées
      _precomputeStatistiques();

      // Recalcule la liste filtrée après mutation
      _applyFilters();

      debugPrint('✅ [CommercialService] Attribution réussie');
      debugPrint(
          '   💰 Valeur attribuée: ${CommercialUtils.formatPrix(attribution.valeurTotale)}');
      debugPrint(
          '   📊 Nouveau statut lot: ${CommercialUtils.getLibelleStatut(lot.quantiteRestante - quantiteAttribuee <= 0 ? StatutLot.completAttribue : StatutLot.partielAttribue)}');

      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ [CommercialService] Erreur attribution: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return false;
    }
  }

  /// Enregistre ou met à jour les informations d'un commercial
  // _enregistrerCommercial supprimé (non utilisé)

  /// Récupère le nom du gestionnaire depuis la collection utilisateurs
  Future<String> _recupererNomGestionnaire(String email) async {
    try {
      final utilisateurDoc =
          await _firestore.collection('utilisateurs').doc(email).get();

      if (utilisateurDoc.exists) {
        final data = utilisateurDoc.data()!;
        return data['nom'] ?? data['prenom'] ?? email;
      }
    } catch (e) {
      debugPrint('❌ [CommercialService] Erreur récupération gestionnaire: $e');
    }

    return email; // Fallback vers l'email si pas trouvé
  }

  /// Crée un prélèvement dans le système de vente à partir d'une attribution
  Future<void> _creerPrelevementDepuisAttribution(
      AttributionPartielle attribution, LotProduit lot) async {
    try {
      final produitsSelectionnes = [
        {
          'produitId': lot.id,
          'numeroLot': lot.numeroLot,
          'typeEmballage': lot.typeEmballage,
          'contenanceKg': lot.contenanceKg,
          'quantitePreleve': attribution.quantiteAttribuee,
          'prixUnitaire': lot.prixUnitaire,
        }
      ];

      await _venteService.creerPrelevement(
        commercialId: attribution.commercialId,
        commercialNom: attribution.commercialNom,
        produitsSelectionnes: produitsSelectionnes,
        observations:
            'Prélèvement automatique depuis attribution ${attribution.id}',
      );

      debugPrint(
          '✅ Prélèvement créé automatiquement pour l\'attribution ${attribution.id}');
    } catch (e) {
      debugPrint('⚠️ Erreur création prélèvement automatique: $e');
      // Ne pas faire échouer l'attribution si le prélèvement échoue
    }
  }

  /// Modifie une attribution existante avec recalcul automatique
  Future<bool> modifierAttribution({
    required String attributionId,
    required int nouvelleQuantite,
    String? motif,
  }) async {
    try {
      debugPrint(
          '🔄 [CommercialService] Modification attribution $attributionId -> $nouvelleQuantite unités');

      final site = _userSession.site ?? 'Site_Inconnu';

      // Trouver l'attribution actuelle
      final attributionActuelle =
          _attributionsCache.firstWhereOrNull((a) => a.id == attributionId);
      if (attributionActuelle == null) {
        debugPrint('❌ Attribution non trouvée: $attributionId');
        return false;
      }

      // Trouver le lot correspondant
      final lot =
          _lotsCache.firstWhereOrNull((l) => l.id == attributionActuelle.lotId);
      if (lot == null) {
        debugPrint('❌ Lot non trouvé: ${attributionActuelle.lotId}');
        return false;
      }

      final differenteQuantite =
          nouvelleQuantite - attributionActuelle.quantiteAttribuee;

      // Vérifier la disponibilité si on augmente
      if (differenteQuantite > 0 && lot.quantiteRestante < differenteQuantite) {
        debugPrint(
            '❌ Quantité insuffisante pour modification. Différence: $differenteQuantite, Disponible: ${lot.quantiteRestante}');
        return false;
      }

      // Transaction atomique
      await _firestore.runTransaction((transaction) async {
        // Mettre à jour l'attribution
        final now = DateTime.now();
        final attributionMiseAJour = AttributionPartielle(
          id: attributionActuelle.id,
          lotId: attributionActuelle.lotId,
          commercialId: attributionActuelle.commercialId,
          commercialNom: attributionActuelle.commercialNom,
          quantiteAttribuee: nouvelleQuantite,
          valeurUnitaire: attributionActuelle.valeurUnitaire,
          valeurTotale: nouvelleQuantite * attributionActuelle.valeurUnitaire,
          dateAttribution: attributionActuelle.dateAttribution,
          gestionnaire: attributionActuelle.gestionnaire,
          motifModification: motif,
          dateDerniereModification: now,
          // Conserver tous les champs existants
          contenanceKg: attributionActuelle.contenanceKg,
          dateConditionnement: attributionActuelle.dateConditionnement,
          numeroLot: attributionActuelle.numeroLot,
          predominanceFlorale: attributionActuelle.predominanceFlorale,
          prixUnitaire: attributionActuelle.prixUnitaire,
          quantiteInitiale: attributionActuelle.quantiteInitiale,
          quantiteRestante: attributionActuelle.quantiteRestante +
              (attributionActuelle.quantiteAttribuee - nouvelleQuantite),
          searchableText: attributionActuelle.searchableText,
          siteOrigine: attributionActuelle.siteOrigine,
          statut: attributionActuelle.statut,
          typeEmballage: attributionActuelle.typeEmballage,
          observations: attributionActuelle.observations,
          lastUpdate: now,
        );

        final attributionRef = _firestore
            .collection('Gestion Commercial')
            .doc(site)
            .collection('attributions')
            .doc(attributionId);

        transaction.update(attributionRef, attributionMiseAJour.toMap());

        // Recalculer les quantités du lot
        final nouvelleQuantiteAttribuee =
            lot.quantiteAttribuee + differenteQuantite;
        final nouvelleQuantiteRestante =
            lot.quantiteInitiale - nouvelleQuantiteAttribuee;

        // Nouveau statut
        StatutLot nouveauStatut;
        if (nouvelleQuantiteRestante <= 0) {
          nouveauStatut = StatutLot.completAttribue;
        } else if (nouvelleQuantiteAttribuee > 0) {
          nouveauStatut = StatutLot.partielAttribue;
        } else {
          nouveauStatut = StatutLot.disponible;
        }

        // Mettre à jour les attributions du lot
        final attributionsMisesAJour = lot.attributions.map((a) {
          return a.id == attributionId ? attributionMiseAJour : a;
        }).toList();

        final lotMisAJour = lot.copyWith(
          quantiteAttribuee: nouvelleQuantiteAttribuee,
          quantiteRestante: nouvelleQuantiteRestante,
          statut: nouveauStatut,
          attributions: attributionsMisesAJour,
        );

        // Sauvegarder le lot
        final lotRef = _firestore
            .collection('Gestion Commercial')
            .doc(site)
            .collection('lots')
            .doc(lot.id);

        transaction.set(lotRef, lotMisAJour.toMap());
      });

      // Mettre à jour les caches locaux
      final indexLot = _lotsCache.indexWhere((l) => l.id == lot.id);
      if (indexLot != -1) {
        final lotMisAJour = lot.copyWith(
          quantiteAttribuee: lot.quantiteAttribuee + differenteQuantite,
          quantiteRestante: lot.quantiteRestante - differenteQuantite,
          statut: lot.quantiteRestante - differenteQuantite <= 0
              ? StatutLot.completAttribue
              : (lot.quantiteAttribuee + differenteQuantite > 0
                  ? StatutLot.partielAttribue
                  : StatutLot.disponible),
        );
        _lotsCache[indexLot] = lotMisAJour;
      }

      final indexAttribution =
          _attributionsCache.indexWhere((a) => a.id == attributionId);
      if (indexAttribution != -1) {
        final now = DateTime.now();
        final attributionMiseAJour = AttributionPartielle(
          id: attributionActuelle.id,
          lotId: attributionActuelle.lotId,
          commercialId: attributionActuelle.commercialId,
          commercialNom: attributionActuelle.commercialNom,
          quantiteAttribuee: nouvelleQuantite,
          valeurUnitaire: attributionActuelle.valeurUnitaire,
          valeurTotale: nouvelleQuantite * attributionActuelle.valeurUnitaire,
          dateAttribution: attributionActuelle.dateAttribution,
          gestionnaire: attributionActuelle.gestionnaire,
          motifModification: motif,
          dateDerniereModification: now,
          // Conserver tous les champs existants
          contenanceKg: attributionActuelle.contenanceKg,
          dateConditionnement: attributionActuelle.dateConditionnement,
          numeroLot: attributionActuelle.numeroLot,
          predominanceFlorale: attributionActuelle.predominanceFlorale,
          prixUnitaire: attributionActuelle.prixUnitaire,
          quantiteInitiale: attributionActuelle.quantiteInitiale,
          quantiteRestante: attributionActuelle.quantiteRestante +
              (attributionActuelle.quantiteAttribuee - nouvelleQuantite),
          searchableText: attributionActuelle.searchableText,
          siteOrigine: attributionActuelle.siteOrigine,
          statut: attributionActuelle.statut,
          typeEmballage: attributionActuelle.typeEmballage,
          observations: attributionActuelle.observations,
          lastUpdate: now,
        );
        _attributionsCache[indexAttribution] = attributionMiseAJour;
      }

      // Invalider cache statistiques
      _statsCache.value = null;
      CacheCommercial.clear('statistiques');

      debugPrint('✅ [CommercialService] Attribution modifiée avec succès');
      // Recalcule la liste filtrée après mutation
      _applyFilters();
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ [CommercialService] Erreur modification attribution: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return false;
    }
  }

  /// Supprime une attribution avec remise en stock automatique
  Future<bool> supprimerAttribution(String attributionId,
      {String? motif}) async {
    try {
      debugPrint(
          '🗑️ [CommercialService] Suppression attribution $attributionId');

      final site = _userSession.site ?? 'Site_Inconnu';

      // Trouver l'attribution
      final attribution =
          _attributionsCache.firstWhereOrNull((a) => a.id == attributionId);
      if (attribution == null) {
        debugPrint('❌ Attribution non trouvée: $attributionId');
        return false;
      }

      // Trouver le lot correspondant
      final lot = _lotsCache.firstWhereOrNull((l) => l.id == attribution.lotId);
      if (lot == null) {
        debugPrint('❌ Lot non trouvé: ${attribution.lotId}');
        return false;
      }

      // Transaction atomique
      await _firestore.runTransaction((transaction) async {
        // Supprimer l'attribution
        final attributionRef = _firestore
            .collection('Gestion Commercial')
            .doc(site)
            .collection('attributions')
            .doc(attributionId);

        transaction.delete(attributionRef);

        // Recalculer les quantités du lot
        final nouvelleQuantiteAttribuee =
            lot.quantiteAttribuee - attribution.quantiteAttribuee;
        final nouvelleQuantiteRestante =
            lot.quantiteInitiale - nouvelleQuantiteAttribuee;

        // Nouveau statut
        StatutLot nouveauStatut;
        if (nouvelleQuantiteRestante >= lot.quantiteInitiale) {
          nouveauStatut = StatutLot.disponible;
        } else if (nouvelleQuantiteAttribuee > 0) {
          nouveauStatut = StatutLot.partielAttribue;
        } else {
          nouveauStatut = StatutLot.disponible;
        }

        // Retirer l'attribution de la liste
        final attributionsMisesAJour =
            lot.attributions.where((a) => a.id != attributionId).toList();

        final lotMisAJour = lot.copyWith(
          quantiteAttribuee: nouvelleQuantiteAttribuee,
          quantiteRestante: nouvelleQuantiteRestante,
          statut: nouveauStatut,
          attributions: attributionsMisesAJour,
        );

        // Sauvegarder le lot
        final lotRef = _firestore
            .collection('Gestion Commercial')
            .doc(site)
            .collection('lots')
            .doc(lot.id);

        transaction.set(lotRef, lotMisAJour.toMap());
      });

      // Mettre à jour les caches locaux
      final indexLot = _lotsCache.indexWhere((l) => l.id == lot.id);
      if (indexLot != -1) {
        final lotMisAJour = lot.copyWith(
          quantiteAttribuee:
              lot.quantiteAttribuee - attribution.quantiteAttribuee,
          quantiteRestante:
              lot.quantiteRestante + attribution.quantiteAttribuee,
          statut: (lot.quantiteAttribuee - attribution.quantiteAttribuee <= 0)
              ? StatutLot.disponible
              : StatutLot.partielAttribue,
        );
        _lotsCache[indexLot] = lotMisAJour;
      }

      _attributionsCache.removeWhere((a) => a.id == attributionId);

      // Invalider cache statistiques
      _statsCache.value = null;
      CacheCommercial.clear('statistiques');

      debugPrint(
          '✅ [CommercialService] Attribution supprimée et lot remis en stock');
      // Recalcule la liste filtrée après mutation
      _applyFilters();
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ [CommercialService] Erreur suppression attribution: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return false;
    }
  }

  // ============================================================================
  // 🔄 MÉTHODES PUBLIQUES DE RAFRAÎCHISSEMENT
  // ============================================================================

  /// Force le rafraîchissement de toutes les données
  Future<void> rafraichirDonnees() async {
    debugPrint('🔄 [CommercialService] Rafraîchissement forcé des données...');
    await getLotsAvecCache(forceRefresh: true);
  }

  /// Rafraîchit uniquement le cache des attributions
  Future<void> rafraichirAttributions() async {
    debugPrint('🔄 [CommercialService] Rafraîchissement des attributions...');
    final attributions = await _getAllAttributions();
    _attributionsCache.assignAll(attributions);
    _precomputeStatistiques();
  }

  /// 🚀 OPTIMISATION : Précalcule les statistiques en arrière-plan
  Future<void> _precomputeStatistiques() async {
    try {
      debugPrint(
          '🚀 [CommercialService] Précalcul des statistiques en arrière-plan...');

      // Calculer en parallèle sans bloquer l'UI
      await Future.microtask(() {
        // Nombre total d'attributions
        _nombreAttributionsPrecompute.value = _attributionsCache.length;

        // Nombre de lots attribués
        final lotsAttribues =
            _lotsCache.where((l) => l.attributions.isNotEmpty).length;
        _nombreLotsAttribuesPrecompute.value = lotsAttribues;

        // Valeur totale attribuée
        final valeurTotale = _attributionsCache.fold(
            0.0, (sum, attr) => sum + attr.valeurTotale);
        _valeurTotalePrecompute.value = valeurTotale;

        // Marquer comme prêt
        _statsPrecomputeReady.value = true;

        debugPrint('✅ [CommercialService] Statistiques précalculées:');
        debugPrint('   • Attributions: ${_nombreAttributionsPrecompute.value}');
        debugPrint(
            '   • Lots attribués: ${_nombreLotsAttribuesPrecompute.value}');
        debugPrint(
            '   • Valeur totale: ${CommercialUtils.formatPrix(_valeurTotalePrecompute.value)}');
      });
    } catch (e) {
      debugPrint('❌ [CommercialService] Erreur précalcul statistiques: $e');
      _statsPrecomputeReady.value = false;
    }
  }

  // ============================================================================
  // 👤 GESTION DE L'ADMINISTRATION ET IMPERSONIFICATION
  // ============================================================================

  /// Initialise les permissions utilisateur basées sur le rôle
  Future<void> _initializeUserPermissions() async {
    try {
      debugPrint(
          '👤 [CommercialService] Initialisation des permissions utilisateur...');

      // Récupérer le rôle utilisateur depuis la base de données ou la session
      final userEmail = _userSession.email ?? '';
      final role = await _getUserRole(userEmail);

      _roleUtilisateur.value = role;
      _permissions.value = PermissionsAdmin.fromRole(role);

      debugPrint('✅ [CommercialService] Rôle utilisateur: ${role.name}');
      debugPrint('   • Admin: ${estAdmin}');
      debugPrint(
          '   • Peut impersonifier: ${permissions?.peutImpersonifierCommercial}');

      // Charger la liste des commerciaux disponibles pour les admins
      if (estAdmin && permissions?.peutImpersonifierCommercial == true) {
        await _chargerCommerciauxDisponibles();
      }
    } catch (e) {
      debugPrint('❌ [CommercialService] Erreur initialisation permissions: $e');
      // Par défaut, rôle commercial sans permissions étendues
      _roleUtilisateur.value = RoleUtilisateur.commercial;
      _permissions.value =
          PermissionsAdmin.fromRole(RoleUtilisateur.commercial);
    }
  }

  /// Récupère le rôle de l'utilisateur depuis la base de données
  Future<RoleUtilisateur> _getUserRole(String email) async {
    try {
      // Liste des emails admin (à configurer selon votre système)
      const admins = [
        'admin@apisavana.com',
        'gestionnaire@apisavana.com',
        'supervisor@apisavana.com',
      ];

      if (admins.contains(email.toLowerCase())) {
        return RoleUtilisateur.admin;
      }

      // Vérifier dans la base de données utilisateurs
      final userDoc = await _firestore
          .collection('utilisateurs')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userDoc.docs.isNotEmpty) {
        final userData = userDoc.docs.first.data();
        final roleString = userData['role'] as String?;

        switch (roleString?.toLowerCase()) {
          case 'admin':
            return RoleUtilisateur.admin;
          case 'superviseur':
            return RoleUtilisateur.superviseur;
          case 'gestionnaire':
            return RoleUtilisateur.gestionnaire;
          default:
            return RoleUtilisateur.commercial;
        }
      }

      return RoleUtilisateur.commercial;
    } catch (e) {
      debugPrint('❌ [CommercialService] Erreur récupération rôle: $e');
      return RoleUtilisateur.commercial;
    }
  }

  /// Charge la liste des commerciaux disponibles pour l'impersonification
  Future<void> _chargerCommerciauxDisponibles() async {
    try {
      debugPrint(
          '👥 [CommercialService] Chargement des commerciaux disponibles...');

      final commerciauxSnapshot = await _firestore
          .collection('Gestion Commercial')
          .doc('commerciaux')
          .collection('actifs')
          .get();

      final commerciaux = commerciauxSnapshot.docs
          .map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'nom': data['nom'] ?? '',
              'site': data['site'] ?? '',
              'derniereMiseAJour': data['derniereMiseAJour'],
              'statut': data['statut'] ?? 'actif',
            };
          })
          .where((commercial) => commercial['statut'] == 'actif')
          .toList();

      // Trier par nom
      commerciaux
          .sort((a, b) => (a['nom'] as String).compareTo(b['nom'] as String));

      _commerciauxDisponibles.assignAll(commerciaux);
      debugPrint(
          '✅ [CommercialService] ${commerciaux.length} commerciaux disponibles chargés');
    } catch (e) {
      debugPrint('❌ [CommercialService] Erreur chargement commerciaux: $e');
    }
  }

  /// Démarre l'impersonification d'un commercial
  Future<bool> impersonifierCommercial(
      String commercialId, String commercialNom) async {
    try {
      if (permissions?.peutImpersonifierCommercial != true) {
        debugPrint(
            '❌ [CommercialService] Permission refusée pour l\'impersonification');
        return false;
      }

      debugPrint(
          '🎭 [CommercialService] Début impersonification: $commercialNom');

      final adminEmail = _userSession.email ?? '';
      final adminNom = _userSession.nom ?? 'Admin';

      final contexte = ContexteImpersonification(
        commercialId: commercialId,
        commercialNom: commercialNom,
        adminId: adminEmail,
        adminNom: adminNom,
        dateDebut: DateTime.now(),
        estActif: true,
      );

      _contexteImpersonification.value = contexte;

      // Enregistrer dans la base de données pour audit
      await _firestore
          .collection('Gestion Commercial')
          .doc('impersonifications')
          .collection('historique')
          .add(contexte.toMap());

      debugPrint(
          '✅ [CommercialService] Impersonification active pour $commercialNom');
      return true;
    } catch (e) {
      debugPrint('❌ [CommercialService] Erreur impersonification: $e');
      return false;
    }
  }

  /// Arrête l'impersonification et revient au mode admin
  Future<bool> arreterImpersonification() async {
    try {
      if (_contexteImpersonification.value != null) {
        debugPrint(
            '🎭 [CommercialService] Arrêt impersonification: ${_contexteImpersonification.value!.commercialNom}');

        // Mettre à jour l'historique
        final contexteInactif = ContexteImpersonification(
          commercialId: _contexteImpersonification.value!.commercialId,
          commercialNom: _contexteImpersonification.value!.commercialNom,
          adminId: _contexteImpersonification.value!.adminId,
          adminNom: _contexteImpersonification.value!.adminNom,
          dateDebut: _contexteImpersonification.value!.dateDebut,
          estActif: false,
        );

        await _firestore
            .collection('Gestion Commercial')
            .doc('impersonifications')
            .collection('historique')
            .add({
          ...contexteInactif.toMap(),
          'dateFin': Timestamp.now(),
        });

        _contexteImpersonification.value = null;
        debugPrint('✅ [CommercialService] Retour au mode administrateur');
      }
      return true;
    } catch (e) {
      debugPrint('❌ [CommercialService] Erreur arrêt impersonification: $e');
      return false;
    }
  }

  /// Obtient le nom effectif (commercial impersonifié ou utilisateur réel)
  String getNomEffectif() {
    if (estEnModeImpersonification) {
      return _contexteImpersonification.value!.commercialNom;
    }
    return _userSession.nom ?? 'Utilisateur';
  }

  /// Obtient l'ID effectif (commercial impersonifié ou utilisateur réel)
  String getIdEffectif() {
    if (estEnModeImpersonification) {
      return _contexteImpersonification.value!.commercialId;
    }
    return _userSession.email ?? 'user';
  }

  // ============================================================================
  // 🔍 FILTRAGE ET RECHERCHE ULTRA-RAPIDE
  // ============================================================================

  void _applyFilters() {
    final criteria = _criteresFiltrage.value;
    final term = _searchText.value.trim().toLowerCase();
    Iterable<LotProduit> base = _lotsCache;

    if (term.isNotEmpty) {
      base = base.where((l) =>
          l.numeroLot.toLowerCase().contains(term) ||
          l.siteOrigine.toLowerCase().contains(term) ||
          l.typeEmballage.toLowerCase().contains(term) ||
          l.predominanceFlorale.toLowerCase().contains(term));
    }
    if (criteria.site != null && criteria.site!.isNotEmpty) {
      base = base.where((l) => l.siteOrigine == criteria.site);
    }
    if (criteria.typeEmballage != null && criteria.typeEmballage!.isNotEmpty) {
      base = base.where((l) => l.typeEmballage == criteria.typeEmballage);
    }
    if (criteria.predominanceFlorale != null &&
        criteria.predominanceFlorale!.isNotEmpty) {
      base = base
          .where((l) => l.predominanceFlorale == criteria.predominanceFlorale);
    }
    if (criteria.statut != null) {
      base = base.where((l) => l.statut == criteria.statut);
    }
    if (criteria.seulementsRestes == true) {
      base = base.where((l) => l.quantiteRestante > 0);
    }
    if (criteria.seulementsExpires == true) {
      base = base.where((l) =>
          l.estProcheExpiration || l.dateExpiration.isBefore(DateTime.now()));
    }
    if (criteria.prixMin != null) {
      base = base.where((l) => l.prixUnitaire >= criteria.prixMin!);
    }
    if (criteria.prixMax != null) {
      base = base.where((l) => l.prixUnitaire <= criteria.prixMax!);
    }
    if (criteria.quantiteMin != null) {
      base = base.where((l) => l.quantiteRestante >= criteria.quantiteMin!);
    }
    if (criteria.quantiteMax != null) {
      base = base.where((l) => l.quantiteRestante <= criteria.quantiteMax!);
    }

    // Tri léger: plus récents d'abord (déjà triés lors chargement; on réapplique pour cohérence)
    final result = base.toList()
      ..sort((a, b) => b.dateConditionnement.compareTo(a.dateConditionnement));

    _filteredLots.assignAll(result);
  }

  // (Section corrigée: les méthodes originales d'attribution/modification/suppression plus haut restent utilisées.)
  // ============================================================================
  // 🧹 MÉTHODES UTILITAIRES
  // ============================================================================

  /// Force le rafraîchissement de toutes les données
  Future<void> rafraichirToutesLesDonnees() async {
    debugPrint(
        '🔄 [CommercialService] Rafraîchissement complet des données...');

    CacheCommercial.clear();
    _lastCacheUpdate = null;

    await Future.wait(<Future<dynamic>>[
      getLotsAvecCache(forceRefresh: true),
      calculerStatistiques(forceRefresh: true),
    ]);

    _applyFilters();

    debugPrint('✅ [CommercialService] Rafraîchissement terminé');
  }

  /// Nettoie les ressources
  @override
  void onClose() {
    _searchDebounce?.cancel();
    CacheCommercial.clear();
    super.onClose();
  }

  // ============================================================================
  // 📊 CALCUL DES STATISTIQUES DÉTAILLÉES
  // ============================================================================

  /// Calcule (ou renvoie depuis le cache) les statistiques commerciales agrégées.
  /// Utilisé par plusieurs widgets (ex: `StatistiquesSimple`, onglet statistiques, etc.).
  /// Paramètre [forceRefresh] pour obliger un recalcul même si le cache existe.
  Future<StatistiquesCommerciales?> calculerStatistiques(
      {bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _statsCache.value != null) {
        if (_lastStatsCompute != null &&
            DateTime.now().difference(_lastStatsCompute!) < _statsTtl) {
          _log('♻️ Stats cache (<TTL)');
          return _statsCache.value;
        }
      }
      if (!forceRefresh && _ongoingStatsFuture != null) {
        _log('♻️ Future stats réutilisée');
        return _ongoingStatsFuture!;
      }
      final completer = Completer<StatistiquesCommerciales?>();
      _ongoingStatsFuture = completer.future;

      if (_lotsCache.isEmpty) {
        await getLotsAvecCache(forceRefresh: false);
      }

      final maintenant = DateTime.now();
      final periodeFin = maintenant;
      DateTime periodeDebut;
      if (_lotsCache.isNotEmpty) {
        final dates = _lotsCache.map((l) => l.dateConditionnement).toList()
          ..sort();
        periodeDebut = dates.first;
      } else {
        periodeDebut = maintenant.subtract(const Duration(days: 90));
      }

      double valeurTotaleStock = 0,
          valeurTotaleAttribuee = 0,
          valeurTotaleRestante = 0;
      for (final lot in _lotsCache) {
        valeurTotaleStock += lot.quantiteInitiale * lot.prixUnitaire;
        valeurTotaleAttribuee += lot.valeurAttribuee;
        valeurTotaleRestante += lot.valeurRestante;
      }
      final tauxAttribution = valeurTotaleStock > 0
          ? (valeurTotaleAttribuee / valeurTotaleStock) * 100
          : 0.0;

      final Map<String, List<AttributionPartielle>> attrParCommercial = {};
      for (final a in _attributionsCache) {
        attrParCommercial.putIfAbsent(a.commercialNom, () => []).add(a);
      }
      final performancesCommerciaux = <String, StatistiquesCommercial>{};
      attrParCommercial.forEach((nom, liste) {
        final id = liste.first.commercialId;
        final valeurAttrib =
            liste.fold<double>(0.0, (s, a) => s + a.valeurTotale);
        performancesCommerciaux[nom] = StatistiquesCommercial(
          commercialId: id,
          commercialNom: nom,
          nombreAttributions: liste.length,
          valeurTotaleAttribuee: valeurAttrib,
          nombreVentes: 0,
          chiffreAffaires: 0.0,
          tauxConversion: 0.0,
          moyenneVenteParAttribution: 0.0,
        );
      });

      final repartitionSites = <String, StatistiquesSite>{};
      final lotsParSite = <String, List<LotProduit>>{};
      for (final l in _lotsCache) {
        lotsParSite.putIfAbsent(l.siteOrigine, () => []).add(l);
      }
      lotsParSite.forEach((site, lots) {
        double vStock = 0, vAttrib = 0;
        for (final l in lots) {
          vStock += l.quantiteInitiale * l.prixUnitaire;
          vAttrib += l.valeurAttribuee;
        }
        final taux = vStock > 0 ? (vAttrib / vStock) * 100 : 0.0;
        repartitionSites[site] = StatistiquesSite(
          site: site,
          nombreLots: lots.length,
          valeurStock: vStock,
          valeurAttribuee: vAttrib,
          tauxAttribution: taux,
        );
      });

      final repartitionEmballages = <String, StatistiquesEmballage>{};
      final lotsParEmb = <String, List<LotProduit>>{};
      for (final l in _lotsCache) {
        lotsParEmb.putIfAbsent(l.typeEmballage, () => []).add(l);
      }
      lotsParEmb.forEach((type, lots) {
        int qStock = 0, qAttrib = 0;
        double vStock = 0, vAttrib = 0;
        for (final l in lots) {
          qStock += l.quantiteInitiale;
          qAttrib += l.quantiteAttribuee;
          vStock += l.quantiteInitiale * l.prixUnitaire;
          vAttrib += l.valeurAttribuee;
        }
        repartitionEmballages[type] = StatistiquesEmballage(
          typeEmballage: type,
          nombreLots: lots.length,
          quantiteStock: qStock,
          quantiteAttribuee: qAttrib,
          valeurStock: vStock,
          valeurAttribuee: vAttrib,
        );
      });

      final repartitionFlorale = <String, StatistiquesFlorale>{};
      final lotsParFlor = <String, List<LotProduit>>{};
      for (final l in _lotsCache) {
        lotsParFlor.putIfAbsent(l.predominanceFlorale, () => []).add(l);
      }
      lotsParFlor.forEach((pred, lots) {
        double vStock = 0, vAttrib = 0, prixCum = 0;
        for (final l in lots) {
          vStock += l.quantiteInitiale * l.prixUnitaire;
          vAttrib += l.valeurAttribuee;
          prixCum += l.prixUnitaire;
        }
        final prixMoyen = lots.isNotEmpty ? prixCum / lots.length : 0.0;
        repartitionFlorale[pred] = StatistiquesFlorale(
          predominance: pred,
          nombreLots: lots.length,
          valeurStock: vStock,
          valeurAttribuee: vAttrib,
          prixMoyenUnitaire: prixMoyen,
        );
      });

      final tendancesMap = <String, Map<String, dynamic>>{};
      for (final attr in _attributionsCache) {
        final d = attr.dateAttribution;
        final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
        final entry = tendancesMap.putIfAbsent(
            key,
            () => {
                  'annee': d.year,
                  'mois': d.month,
                  'nombreAttributions': 0,
                  'valeurAttribuee': 0.0,
                  'nombreVentes': 0,
                  'chiffreAffaires': 0.0
                });
        entry['nombreAttributions'] = (entry['nombreAttributions'] as int) + 1;
        entry['valeurAttribuee'] =
            (entry['valeurAttribuee'] as double) + attr.valeurTotale;
      }
      final tendancesMensuelles = tendancesMap.values
          .map((m) => TendanceMensuelle(
                annee: m['annee'] as int,
                mois: m['mois'] as int,
                nombreAttributions: m['nombreAttributions'] as int,
                valeurAttribuee: m['valeurAttribuee'] as double,
                nombreVentes: m['nombreVentes'] as int,
                chiffreAffaires: m['chiffreAffaires'] as double,
              ))
          .toList()
        ..sort((a, b) =>
            (a.annee * 100 + a.mois).compareTo(b.annee * 100 + b.mois));

      final stats = StatistiquesCommerciales(
        periodeDebut: periodeDebut,
        periodeFin: periodeFin,
        nombreLots: _lotsCache.length,
        nombreAttributions: _attributionsCache.length,
        valeurTotaleStock: valeurTotaleStock,
        valeurTotaleAttribuee: valeurTotaleAttribuee,
        valeurTotaleRestante: valeurTotaleRestante,
        tauxAttribution: tauxAttribution,
        performancesCommerciaux: performancesCommerciaux,
        repartitionSites: repartitionSites,
        repartitionEmballages: repartitionEmballages,
        repartitionFlorale: repartitionFlorale,
        tendancesMensuelles: tendancesMensuelles,
        derniereMAJ: maintenant,
      );

      _statsCache.value = stats;
      _lastStatsCompute = DateTime.now();
      CacheCommercial.set('statistiques', stats);
      // Compléter le calcul (déduplication active via _ongoingStatsFuture)
      completer.complete(stats);
      _statComputeCount++;
      _ongoingStatsFuture = null;
      return stats;
    } catch (e, st) {
      _log('❌ Erreur calcul statistiques: $e');
      _log('📍 $st');
      _ongoingStatsFuture = null;
      return _statsCache.value;
    }
  }
}
