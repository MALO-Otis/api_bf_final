import 'dart:async';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/vente_models.dart';
import 'package:flutter/foundation.dart';
import '../../caisse/models/caisse_cloture.dart';
import '../../../authentication/user_session.dart';
import '../models/commercial_models.dart' hide Client;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../conditionnement/conditionnement_models.dart';
import '../../conditionnement/services/conditionnement_db_service.dart';

/// 🛒 SERVICE PRINCIPAL DE GESTION DES VENTES
///
/// Gestion complète des produits conditionnés, prélèvements, ventes, restitutions et pertes
/// 🔥 NOUVELLE VERSION INTÉGRÉE AVEC LE MODULE CONDITIONNEMENT

class VenteService {
  static final VenteService _instance = VenteService._internal();
  factory VenteService() => _instance;
  VenteService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserSession _userSession = Get.find<UserSession>();

  // ====== LOGGING & DIAGNOSTICS ======
  /// Active les logs détaillés (bruit élevé). Mettre à false en production.
  bool verboseLogs = false;

  /// Counters diagnostics
  int _produitsBuildCount =
      0; // Nombre de reconstructions complètes de la liste de produits
  int _conditionnementsAnalysesCount =
      0; // Nombre total de conditionnements parcourus
  int _emballagesAnalysesCount = 0; // Nombre d'emballages analysés

  /// Cache produits + métadonnées
  List<ProduitConditionne>? _cachedProduits;
  DateTime? _lastProduitsBuild;
  Duration _produitsTtl = const Duration(
      seconds: 45); // TTL raisonnable (UI réactive mais évite spam)

  /// Future en cours pour dédupliquer les appels concurrents
  Future<List<ProduitConditionne>>? _ongoingProduitsFuture;

  /// Helper log interne
  void _log(String msg) {
    if (verboseLogs) debugPrint(msg);
  }

  // Getters diagnostics publics
  int get produitsBuildCount => _produitsBuildCount;
  int get conditionnementsAnalysesCumule => _conditionnementsAnalysesCount;
  int get emballagesAnalysesCumule => _emballagesAnalysesCount;
  Duration? get ageCacheProduits => _lastProduitsBuild == null
      ? null
      : DateTime.now().difference(_lastProduitsBuild!);
  int get tailleCacheProduits => _cachedProduits?.length ?? 0;

  /// 🔥 SERVICE DE CONDITIONNEMENT INTÉGRÉ
  ConditionnementDbService? _conditionnementService;

  ConditionnementDbService get conditionnementService {
    try {
      _conditionnementService ??= Get.find<ConditionnementDbService>();
      return _conditionnementService!;
    } catch (e) {
      debugPrint(
          '⚠️ [VenteService] ConditionnementDbService non trouvé, création d\'une nouvelle instance: $e');
      _conditionnementService = Get.put(ConditionnementDbService());
      return _conditionnementService!;
    }
  }

  // ====================== CLOTURE (COMMERCIAL -> CAISSIER) ======================
  /// Crée une clôture pour un identifiant de prélèvement/attribution virtuel (prelevementId)
  /// Agrège les ventes, restitutions et pertes correspondantes (via prelevementId)
  /// et enregistre un snapshot dans Vente/{site}/clotures/{id}
  Future<CaisseCloture> cloturerAttribution({
    required String site,
    required String prelevementId,
    required String commercialId,
    required String commercialNom,
  }) async {
    final firestore = FirebaseFirestore.instance;

    // Récupérer toutes les opérations liées à ce prelevementId
    final ventesSnap = await firestore
        .collection('Vente')
        .doc(site)
        .collection('ventes')
        .where('prelevementId', isEqualTo: prelevementId)
        .get();
    final restitsSnap = await firestore
        .collection('Vente')
        .doc(site)
        .collection('restitutions')
        .where('prelevementId', isEqualTo: prelevementId)
        .get();
    final pertesSnap = await firestore
        .collection('Vente')
        .doc(site)
        .collection('pertes')
        .where('prelevementId', isEqualTo: prelevementId)
        .get();

    final ventes = ventesSnap.docs.map((d) => Vente.fromMap(d.data())).toList();
    final restits =
        restitsSnap.docs.map((d) => Restitution.fromMap(d.data())).toList();
    final pertes = pertesSnap.docs.map((d) => Perte.fromMap(d.data())).toList();

    // Construire les résumés
    final ventesResumes = ventes
        .map((v) => CaisseVenteResume(
              id: v.id,
              date: v.dateVente,
              montantTotal: v.montantTotal,
              montantPaye: v.montantPaye,
              montantRestant: v.montantRestant,
              modePaiement: v.modePaiement,
              statut: v.statut,
            ))
        .toList();
    final restitsResumes = restits
        .map((r) => CaisseRestitutionResume(
              id: r.id,
              date: r.dateRestitution,
              valeurTotale: r.valeurTotale,
            ))
        .toList();
    final pertesResumes = pertes
        .map((p) => CaissePerteResume(
              id: p.id,
              date: p.datePerte,
              valeurTotale: p.valeurTotale,
            ))
        .toList();

    // Totaux
    double totalVentes = 0, totalPayes = 0, totalCredits = 0;
    for (final v in ventes) {
      if (v.statut != StatutVente.annulee) {
        totalVentes += v.montantTotal;
        totalPayes += v.montantPaye;
        totalCredits += v.montantRestant;
      }
    }
    final totalRestits = restits.fold<double>(0, (s, r) => s + r.valeurTotale);
    final totalPertes = pertes.fold<double>(0, (s, p) => s + p.valeurTotale);

    // Document de clôture
    final id =
        '${prelevementId}_cloture_${DateTime.now().millisecondsSinceEpoch}';
    final cloture = CaisseCloture(
      id: id,
      site: site,
      commercialId: commercialId,
      commercialNom: commercialNom,
      prelevementId: prelevementId,
      dateCreation: DateTime.now(),
      totalVentes: totalVentes,
      totalPayes: totalPayes,
      totalCredits: totalCredits,
      totalRestitutions: totalRestits,
      totalPertes: totalPertes,
      ventes: ventesResumes,
      restitutions: restitsResumes,
      pertes: pertesResumes,
      statut: ClotureStatut.en_attente,
    );

    await firestore
        .collection('Vente')
        .doc(site)
        .collection('clotures')
        .doc(id)
        .set(cloture.toMap());

    // Marquer le prélèvement et l'attribution comme "en attente" (verrou UI)
    try {
      final prelevRef = firestore
          .collection('Vente')
          .doc(site)
          .collection('prelevements')
          .doc(prelevementId);
      // Utiliser set(merge:true) pour éviter l'erreur not-found
      await prelevRef
          .set({'enAttenteValidation': true}, SetOptions(merge: true));

      // Verrou spécifique à l'attribution: Vente/{site}/locks_attributions/{attributionId}
      // L'attributionId original est souvent la première partie de prelevementId (avant suffixe "_prelevement_temp")
      final attributionId = prelevementId.replaceAll('_prelevement_temp', '');
      await firestore
          .collection('Vente')
          .doc(site)
          .collection('locks_attributions')
          .doc(attributionId)
          .set({
        'enAttenteValidation': true,
        'prelevementId': prelevementId,
        'date': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // ignore if prelevement doc not present
      debugPrint(
          '⚠️ [VenteService] Impossible de marquer prelevement en attente: $e');
    }

    return cloture;
  }

  /// Valider une clôture (caissier)
  Future<void> validerCloture({
    required String site,
    required String clotureId,
    required String validatorId,
  }) async {
    final firestore = FirebaseFirestore.instance;
    await firestore
        .collection('Vente')
        .doc(site)
        .collection('clotures')
        .doc(clotureId)
        .update({
      'statut': ClotureStatut.validee.name,
      'validePar': validatorId,
      'dateValidation': FieldValue.serverTimestamp(),
    });
  }

  /// Sites disponibles
  final List<String> sites = [
    'Koudougou',
    'Ouagadougou',
    'Bobo-Dioulasso',
    'Mangodara',
    'Bagre',
    'Pô'
  ];

  // ====== GESTION DES PRODUITS CONDITIONNÉS ======

  /// Génère un reçu texte détaillé pour une vente (paiement total ou partiel / crédit)
  /// Inclut : en-tête, liste produits, totaux, montants payés, restant, mode de paiement, horodatage
  String generateReceipt(Vente vente, {bool includeHeader = true}) {
    final buffer = StringBuffer();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(vente.dateVente);
    if (includeHeader) {
      buffer.writeln('=========== REÇU DE VENTE ===========');
      buffer.writeln('ID Vente    : ${vente.id}');
      buffer.writeln('Date: $dateStr');
      buffer.writeln('Commercial: ${vente.commercialNom}');
      buffer.writeln('Client: ${vente.clientNom}');
      if (vente.clientTelephone != null && vente.clientTelephone!.isNotEmpty) {
        buffer.writeln('Téléphone: ${vente.clientTelephone}');
      }
      buffer.writeln('-------------------------------------');
    }
    buffer.writeln('Produits:');
    for (final p in vente.produits) {
      buffer.writeln(
          '- ${p.typeEmballage} lot ${p.numeroLot} x${p.quantiteVendue} @${p.prixUnitaire.toStringAsFixed(0)} = ${(p.montantTotal).toStringAsFixed(0)}');
    }
    buffer.writeln('-------------------------------------');
    buffer.writeln(
        'Montant Total : ${vente.montantTotal.toStringAsFixed(0)} FCFA');
    buffer
        .writeln('Payé         : ${vente.montantPaye.toStringAsFixed(0)} FCFA');
    final credit = vente.montantRestant;
    if (credit > 0) {
      buffer.writeln(
          'CRÉDIT       : ${credit.toStringAsFixed(0)} FCFA (à payer)');
    } else {
      buffer.writeln('Solde        : 0 (aucun reste)');
    }
    buffer.writeln('Mode Paiement: ${vente.modePaiement.name}');
    buffer.writeln('Statut       : ${vente.statut.name}');
    if (vente.observations != null && vente.observations!.isNotEmpty) {
      buffer.writeln('Note: ${vente.observations}');
    }
    buffer.writeln('=====================================');
    return buffer.toString();
  }

  /// 🔥 NOUVELLE MÉTHODE - Récupère les produits conditionnés depuis le service conditionnement intégré
  Future<List<ProduitConditionne>> getProduitsConditionnesTotalement({
    String? siteFilter,
    bool forceRefresh = false,
  }) async {
    // 1. Cache short‑circuit
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedProduits != null &&
        _lastProduitsBuild != null) {
      final age = now.difference(_lastProduitsBuild!);
      if (age < _produitsTtl) {
        _log(
            '⚡ [VenteService] Produits depuis cache (age=${age.inSeconds}s, taille=${_cachedProduits!.length})');
        return _cachedProduits!;
      } else {
        _log(
            '⌛ [VenteService] Cache expiré (age=${age.inSeconds}s) – reconstruction');
      }
    }

    // 2. Concurrency guard
    if (_ongoingProduitsFuture != null) {
      _log('⏳ [VenteService] Future produits déjà en cours – réutilisation');
      return _ongoingProduitsFuture!;
    }

    final completer = Completer<List<ProduitConditionne>>();
    _ongoingProduitsFuture = completer.future;

    try {
      final buildStart = DateTime.now();
      _log(
          '[VenteService] Construction liste produits (force=$forceRefresh, filtre=${siteFilter ?? 'Tous'})');

      // Rafraîchir la source (conditionnements) uniquement en force refresh ou si aucune donnée
      if (forceRefresh || conditionnementService.conditionnements.isEmpty) {
        _log('🔄 [VenteService] refreshData() du module conditionnement');
        await conditionnementService.refreshData();
      }

      final conditionnements = conditionnementService.conditionnements;
      if (conditionnements.isEmpty) {
        _log(
            '⚠️ [VenteService] Aucun conditionnement – fallback ancienne méthode Firestore');
        final produitsFallback =
            await getProduitsConditionnes(siteFilter: siteFilter);
        // Mettre en cache quand même
        _cachedProduits = produitsFallback;
        _lastProduitsBuild = DateTime.now();
        _produitsBuildCount++;
        completer.complete(produitsFallback);
        return produitsFallback;
      }

      final List<ProduitConditionne> produits = [];
      int emballagesLocaux = 0;
      int conditionnementsParcourus = 0;

      for (final conditionnement in conditionnements) {
        // Filtre site
        if (siteFilter != null &&
            conditionnement.lotOrigine.site != siteFilter) {
          continue;
        }
        conditionnementsParcourus++;

        for (int i = 0; i < conditionnement.emballages.length; i++) {
          final emballage = conditionnement.emballages[i];
          emballagesLocaux++;
          if (emballage.nombreSaisi > 0) {
            final produit = _convertirConditionnementEnProduit(
                conditionnement, emballage, i);
            if (produit != null) {
              produits.add(produit);
              if (verboseLogs) {
                debugPrint(
                    '   ✅ Produit ${produit.typeEmballage} lot=${produit.numeroLot} qte=${produit.quantiteDisponible}');
              }
            }
          }
        }
      }

      // Diagnostics cumulés
      _produitsBuildCount++;
      _conditionnementsAnalysesCount += conditionnementsParcourus;
      _emballagesAnalysesCount += emballagesLocaux;

      // Cache
      _cachedProduits = produits;
      _lastProduitsBuild = DateTime.now();

      final duration = DateTime.now().difference(buildStart);
      _log(
          '✅ [VenteService] Build produits=${produits.length} en ${duration.inMilliseconds}ms (cond=$conditionnementsParcourus, emb=$emballagesLocaux)');

      completer.complete(produits);
      return produits;
    } catch (e, st) {
      debugPrint('❌ [VenteService] Erreur build produits: $e');
      _ongoingProduitsFuture = null; // Reset avant fallback
      completer.completeError(e, st);
      // Fallback
      return getProduitsConditionnes(siteFilter: siteFilter);
    } finally {
      // Libérer le future partagé
      _ongoingProduitsFuture = null;
    }
  }

  /// 🏭 Convertit un conditionnement en produit pour la vente
  ProduitConditionne? _convertirConditionnementEnProduit(
    ConditionnementData conditionnement,
    EmballageSelectionne emballage,
    int index,
  ) {
    try {
      final produitId = '${conditionnement.id}_emb_$index';
      _log(
          '🏭 [VenteService] Conversion emballage type=${emballage.type.nom} qte=${emballage.nombreSaisi}');

      // Utiliser directement le prix de l'emballage du conditionnement
      final prixUnitaire =
          emballage.type.getPrix(conditionnement.lotOrigine.typeFlorale);

      final produit = ProduitConditionne(
        id: produitId,
        numeroLot: conditionnement.lotOrigine.lotOrigine,
        codeContenant: conditionnement.lotOrigine.collecteId.isNotEmpty
            ? conditionnement.lotOrigine.collecteId
            : 'N/A',
        producteur: conditionnement.lotOrigine.technicien,
        village: conditionnement.lotOrigine.site,
        siteOrigine: conditionnement.lotOrigine.site,
        predominanceFlorale: conditionnement.lotOrigine.predominanceFlorale,
        typeEmballage: emballage.type.nom,
        contenanceKg: emballage.type.contenanceKg,
        quantiteDisponible: emballage.nombreSaisi,
        quantiteInitiale: emballage.nombreSaisi,
        prixUnitaire: prixUnitaire,
        dateConditionnement: conditionnement.dateConditionnement,
        dateExpiration:
            _calculerDateExpiration(conditionnement.dateConditionnement),
        statut: StatutProduit.disponible,
        observations: conditionnement.observations,
      );

      _log(
          '   ✅ Produit créé lot=${produit.numeroLot} type=${produit.typeEmballage} valeur=${produit.valeurTotale.toStringAsFixed(0)}');

      return produit;
    } catch (e, stackTrace) {
      debugPrint(
          '❌ [VenteService] Erreur conversion conditionnement -> produit: $e');
      if (verboseLogs) debugPrint('📍 Stack trace: $stackTrace');
      return null;
    }
  }

  /// Récupère tous les produits conditionnés disponibles pour la vente depuis la vraie collection
  Future<List<ProduitConditionne>> getProduitsConditionnes(
      {String? siteFilter}) async {
    try {
      debugPrint(
          '🛒 ===== RÉCUPÉRATION PRODUITS CONDITIONNÉS (VRAIS DONNÉES) =====');
      debugPrint('   🎯 Site filter: ${siteFilter ?? "Tous"}');

      final List<ProduitConditionne> produits = [];
      final sitesToCheck = siteFilter != null ? [siteFilter] : sites;

      for (final site in sitesToCheck) {
        debugPrint('   📍 Analyse du site: $site');

        // 🔥 RÉCUPÉRER LES VRAIS CONDITIONNEMENTS DE LA NOUVELLE STRUCTURE
        final conditionnementSnapshot = await _firestore
            .collection('conditionnement')
            .doc(site)
            .collection('conditionnements')
            .get();

        debugPrint(
            '      ✅ ${conditionnementSnapshot.docs.length} conditionnements trouvés');

        for (final doc in conditionnementSnapshot.docs) {
          final data = doc.data();

          // Récupérer la liste des emballages directement du document
          final emballagesList = data['emballages'] as List<dynamic>? ?? [];

          for (int i = 0; i < emballagesList.length; i++) {
            final emballageData = emballagesList[i] as Map<String, dynamic>;

            // Créer un produit conditionné pour chaque type d'emballage avec quantité > 0
            final quantite = emballageData['quantite'] ?? 0;
            if (quantite > 0) {
              final produit = _creerProduitConditionneFromVraiData(
                doc.id,
                data,
                i,
                emballageData,
                site,
              );

              if (produit != null) {
                produits.add(produit);
              }
            }
          }
        }
      }

      debugPrint('✅ Total produits conditionnés: ${produits.length}');
      debugPrint(
          '   📊 Valeur totale: ${produits.fold(0.0, (sum, p) => sum + p.valeurTotale)} FCFA');
      debugPrint('=============================================');

      return produits;
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur récupération produits conditionnés: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return [];
    }
  }

  /// Crée un ProduitConditionne à partir des vraies données de conditionnement
  ProduitConditionne? _creerProduitConditionneFromVraiData(
    String conditionnementId,
    Map<String, dynamic> conditionnementData,
    int emballageIndex,
    Map<String, dynamic> emballageData,
    String site,
  ) {
    try {
      // Générer un ID unique pour le produit
      final produitId = '${conditionnementId}_emb_$emballageIndex';

      // Extraire les informations de l'emballage
      final typeEmballage = emballageData['type'] ?? 'Pot';
      final contenanceKg = (emballageData['contenanceKg'] ?? 0.0).toDouble();
      final quantiteDisponible = emballageData['quantite'] ?? 0;

      // Calculer prix unitaire basé sur le type d'emballage (prix standards)
      final prixUnitaire = _calculerPrixUnitaire(typeEmballage, contenanceKg);

      return ProduitConditionne(
        id: produitId,
        numeroLot: conditionnementData['lotOrigine'] ?? conditionnementId,
        codeContenant: conditionnementData['lotFiltrageId'] ?? '',
        producteur: conditionnementData['technicien'] ?? 'Technicien',
        village: site, // Utiliser le site comme village
        siteOrigine: site,
        predominanceFlorale:
            conditionnementData['predominanceFlorale'] ?? 'Mille fleurs',
        typeEmballage: typeEmballage,
        contenanceKg: contenanceKg,
        quantiteDisponible: quantiteDisponible,
        quantiteInitiale: quantiteDisponible, // Initiallement même valeur
        prixUnitaire: prixUnitaire,
        dateConditionnement:
            (conditionnementData['date'] as Timestamp?)?.toDate() ??
                (conditionnementData['createdAt'] as Timestamp?)?.toDate() ??
                DateTime.now(),
        dateExpiration: _calculerDateExpiration(
          (conditionnementData['date'] as Timestamp?)?.toDate() ??
              (conditionnementData['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.now(),
        ),
        statut: StatutProduit.disponible,
        observations: conditionnementData['observations'],
      );
    } catch (e) {
      debugPrint(
          '❌ Erreur création produit conditionné depuis vraies données: $e');
      return null;
    }
  }

  /// Calcule le prix unitaire basé sur le type d'emballage et la contenance
  double _calculerPrixUnitaire(String typeEmballage, double contenanceKg) {
    // Prix de base par kg selon le type d'emballage
    const Map<String, double> prixBaseParKg = {
      'Pot 1kg': 1500.0,
      'Pot 1.5kg': 1500.0,
      'Pot 720g': 1600.0,
      'Pot 500g': 1700.0,
      'Pot 250g': 1800.0,
      'Pot alvéoles 30g': 2000.0,
      'Stick 20g': 2200.0,
      '7kg': 1300.0,
    };

    final prixBase = prixBaseParKg[typeEmballage] ?? 1500.0;
    return (prixBase * contenanceKg).roundToDouble();
  }

  /// Calcule la date d'expiration (2 ans après conditionnement)
  DateTime _calculerDateExpiration(DateTime dateConditionnement) {
    return dateConditionnement.add(const Duration(days: 730)); // 2 ans
  }

  // ====== GESTION DES PRÉLÈVEMENTS ======

  /// Crée un nouveau prélèvement
  Future<bool> creerPrelevement({
    required String commercialId,
    required String commercialNom,
    required List<Map<String, dynamic>> produitsSelectionnes,
    String? observations,
  }) async {
    try {
      final site = _userSession.site ?? 'Site_Inconnu';
      final magazinierId = _userSession.email ?? 'Magazinier_Inconnu';
      final magazinierNom = _userSession.email ?? 'Magazinier';

      final prelevementId = 'PREL_${DateTime.now().millisecondsSinceEpoch}';

      debugPrint('🔄 [VenteService] Création prélèvement: $prelevementId');

      // Calculer la valeur totale
      double valeurTotale = 0.0;
      final List<ProduitPreleve> produitsPreleves = [];

      for (final produitData in produitsSelectionnes) {
        final produitPreleve = ProduitPreleve(
          produitId: produitData['produitId'] ?? '',
          numeroLot: produitData['numeroLot'] ?? '',
          typeEmballage: produitData['typeEmballage'] ?? '',
          contenanceKg: (produitData['contenanceKg'] ?? 0.0).toDouble(),
          quantitePreleve: produitData['quantitePreleve'] ?? 0,
          prixUnitaire: (produitData['prixUnitaire'] ?? 0.0).toDouble(),
          valeurTotale: (produitData['quantitePreleve'] ?? 0) *
              (produitData['prixUnitaire'] ?? 0.0),
        );

        produitsPreleves.add(produitPreleve);
        valeurTotale += produitPreleve.valeurTotale;
      }

      // Créer le prélèvement
      final prelevement = Prelevement(
        id: prelevementId,
        commercialId: commercialId,
        commercialNom: commercialNom,
        magazinierId: magazinierId,
        magazinierNom: magazinierNom,
        datePrelevement: DateTime.now(),
        produits: produitsPreleves,
        valeurTotale: valeurTotale,
        statut: StatutPrelevement.enCours,
        observations: observations,
      );

      // Enregistrer en Firestore
      await _firestore
          .collection('Vente')
          .doc(site)
          .collection('prelevements')
          .doc(prelevementId)
          .set(prelevement.toMap());

      // Mettre à jour les quantités disponibles des produits
      await _mettreAJourQuantitesApresPrelevement(produitsPreleves, site);

      debugPrint('✅ [VenteService] Prélèvement créé: $prelevementId');
      debugPrint(
          '   💰 Valeur totale: ${valeurTotale.toStringAsFixed(0)} FCFA');
      debugPrint('   📦 Produits prélevés: ${produitsPreleves.length}');

      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ [VenteService] Erreur création prélèvement: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return false;
    }
  }

  /// Met à jour les quantités après prélèvement
  Future<void> _mettreAJourQuantitesApresPrelevement(
    List<ProduitPreleve> produits,
    String site,
  ) async {
    try {
      final batch = _firestore.batch();

      for (final produit in produits) {
        // Décomposer l'ID pour retrouver le conditionnement et l'emballage
        final parts = produit.produitId.split('_');
        if (parts.length >= 2) {
          final conditionnementId = parts[0];
          final emballageId = parts.sublist(1).join('_');

          final emballageRef = _firestore
              .collection('Conditionnement')
              .doc(site)
              .collection('processus')
              .doc(conditionnementId)
              .collection('emballages_produits')
              .doc(emballageId);

          batch.update(emballageRef, {
            'quantiteDisponible':
                FieldValue.increment(-produit.quantitePreleve),
            'dernierPrelevement': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
      debugPrint('✅ Quantités mises à jour après prélèvement');
    } catch (e) {
      debugPrint('❌ Erreur mise à jour quantités: $e');
    }
  }

  /// Récupère les prélèvements d'un commercial
  Future<List<Prelevement>> getPrelevementsCommercial(
      String commercialId) async {
    try {
      final site = _userSession.site ?? 'Site_Inconnu';
      // Nouvelle règle : un commercial voit tous les prélèvements de son site
      final prelevementsSnapshot = await _firestore
          .collection('Vente')
          .doc(site)
          .collection('prelevements')
          .orderBy('datePrelevement', descending: true)
          .get();

      final prelevements = prelevementsSnapshot.docs
          .map((doc) => Prelevement.fromMap(doc.data()))
          .toList();

      debugPrint('✅ ${prelevements.length} prélèvements trouvés (site=$site)');
      return prelevements;
    } catch (e) {
      debugPrint('❌ Erreur récupération prélèvements: $e');
      return [];
    }
  }

  // ====== GESTION DES VENTES ======

  /// Enregistre une nouvelle vente
  Future<bool> enregistrerVente(Vente vente) async {
    try {
      final site = _userSession.site ?? 'Site_Inconnu';
      final path = 'Vente/$site/ventes/${vente.id}';

      debugPrint('🟡 [VenteService] Tentative enregistrement vente:');
      debugPrint('   📍 Chemin Firestore: $path');
      debugPrint('   👤 Commercial: ${vente.commercialId}');
      debugPrint('   🏢 Site: $site');

      await _firestore
          .collection('Vente')
          .doc(site)
          .collection('ventes')
          .doc(vente.id)
          .set(vente.toMap());

      debugPrint('✅ [VenteService] Vente enregistrée: ${vente.id}');
      debugPrint(
          '   💰 Montant: ${vente.montantTotal.toStringAsFixed(0)} FCFA');
      debugPrint('   👤 Client: ${vente.clientNom}');

      return true;
    } catch (e) {
      debugPrint('❌ [VenteService] Erreur enregistrement vente: $e');
      return false;
    }
  }

  // ====== GESTION DES CLIENTS ======

  /// Récupère tous les clients
  Future<List<Client>> getClients() async {
    try {
      final site = _userSession.site ?? 'Site_Inconnu';
      // On récupère tout puis on filtre car certains documents anciens utilisent 'actif' au lieu de 'estActif'
      final snap = await _firestore
          .collection('Vente')
          .doc(site)
          .collection('clients')
          .orderBy('nom')
          .get();

      final clients = <Client>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final estActif = (data['estActif'] ?? data['actif'] ?? true) == true;
        if (!estActif) continue;
        clients.add(Client.fromMap(data));
      }
      debugPrint(
          '✅ [VenteService] ${clients.length} clients actifs trouvés (site=$site)');
      return clients;
    } catch (e) {
      debugPrint('❌ Erreur récupération clients: $e');
      return [];
    }
  }

  /// Crée un nouveau client
  Future<bool> creerClient(Client client) async {
    try {
      final site = _userSession.site ?? 'Site_Inconnu';

      // Assurer que le site est injecté si pas déjà présent
      final clientData = client.toMap();
      if (clientData['site'] == null) {
        clientData['site'] = site;
      }

      await _firestore
          .collection('Vente')
          .doc(site)
          .collection('clients')
          .doc(client.id)
          .set(clientData);

      debugPrint('✅ [VenteService] Client créé: ${client.nom} (site=$site)');
      return true;
    } catch (e) {
      debugPrint('❌ [VenteService] Erreur création client: $e');
      return false;
    }
  }

  /// Création rapide d'un client minimal avec localisation (utilisée par le quick form)
  Future<bool> creerClientRapide({
    required String nom,
    required String telephone,
    required String nomBoutique,
    double? latitude,
    double? longitude,
    double? altitude,
    double? precision,
  }) async {
    try {
      final site = _userSession.site ?? 'Site_Inconnu';
      final id = _firestore.collection('tmp').doc().id;
      final now = DateTime.now();
      final data = {
        'id': id,
        'nom': nom,
        'telephone': telephone,
        'nomBoutique': nomBoutique,
        'adresse': '',
        'ville': '',
        'type': 'particulier', // aligné avec Client.fromMap (champ 'type')
        'dateCreation': Timestamp.fromDate(now),
        'site': site,
        'estActif': true, // cohérence avec modèle
        'notes': null,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (altitude != null) 'altitude': altitude,
        if (precision != null) 'precision': precision,
      };
      await _firestore
          .collection('Vente')
          .doc(site)
          .collection('clients')
          .doc(id)
          .set(data);
      debugPrint('✅ [VenteService] Client rapide créé: $nom');
      return true;
    } catch (e) {
      debugPrint('❌ [VenteService] Erreur création client rapide: $e');
      return false;
    }
  }

  // ====== GESTION DES RESTITUTIONS ======

  /// Enregistre une restitution
  Future<bool> enregistrerRestitution(Restitution restitution) async {
    try {
      final site = _userSession.site ?? 'Site_Inconnu';

      await _firestore
          .collection('Vente')
          .doc(site)
          .collection('restitutions')
          .doc(restitution.id)
          .set(restitution.toMap());

      // Remettre les produits en stock
      await _remettreProduitsEnStock(restitution.produits, site);

      debugPrint('✅ [VenteService] Restitution enregistrée: ${restitution.id}');
      return true;
    } catch (e) {
      debugPrint('❌ [VenteService] Erreur enregistrement restitution: $e');
      return false;
    }
  }

  /// Remet les produits restitués en stock
  Future<void> _remettreProduitsEnStock(
    List<ProduitRestitue> produits,
    String site,
  ) async {
    try {
      final batch = _firestore.batch();

      for (final produit in produits) {
        // Décomposer l'ID pour retrouver le conditionnement et l'emballage
        final parts = produit.produitId.split('_');
        if (parts.length >= 2) {
          final conditionnementId = parts[0];
          final emballageId = parts.sublist(1).join('_');

          final emballageRef = _firestore
              .collection('Conditionnement')
              .doc(site)
              .collection('processus')
              .doc(conditionnementId)
              .collection('emballages_produits')
              .doc(emballageId);

          batch.update(emballageRef, {
            'quantiteDisponible':
                FieldValue.increment(produit.quantiteRestituee),
            'derniereRestitution': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
      debugPrint('✅ Produits remis en stock après restitution');
    } catch (e) {
      debugPrint('❌ Erreur remise en stock: $e');
    }
  }

  // ====== GESTION DES PERTES ======

  /// Enregistre une perte
  Future<bool> enregistrerPerte(Perte perte) async {
    try {
      final site = _userSession.site ?? 'Site_Inconnu';

      await _firestore
          .collection('Vente')
          .doc(site)
          .collection('pertes')
          .doc(perte.id)
          .set(perte.toMap());

      debugPrint('✅ [VenteService] Perte enregistrée: ${perte.id}');
      debugPrint(
          '   💔 Valeur perdue: ${perte.valeurTotale.toStringAsFixed(0)} FCFA');

      return true;
    } catch (e) {
      debugPrint('❌ [VenteService] Erreur enregistrement perte: $e');
      return false;
    }
  }

  // ====== STATISTIQUES ======

  // ====== LISTES (VENTES / RESTITUTIONS / PERTES / PRELEVEMENTS) AVEC CACHE TTL ======
  List<Vente>? _cacheVentes;
  DateTime? _lastVentesFetch;
  List<Restitution>? _cacheRestitutions;
  DateTime? _lastRestitutionsFetch;
  List<Perte>? _cachePertes;
  DateTime? _lastPertesFetch;
  List<Prelevement>? _cachePrelevementsAdmin;
  DateTime? _lastPrelevementsAdminFetch;
  final Duration _listsTtl = const Duration(seconds: 40);
  // Diagnostics counters for list fetches (Firestore hits only, not cache)
  int _ventesFetchCount = 0;
  int _restitutionsFetchCount = 0;
  int _pertesFetchCount = 0;
  int _prelevementsFetchCount = 0;

  int get ventesFetchCount => _ventesFetchCount;
  int get restitutionsFetchCount => _restitutionsFetchCount;
  int get pertesFetchCount => _pertesFetchCount;
  int get prelevementsFetchCount => _prelevementsFetchCount;

  bool _isCacheValid(DateTime? last) =>
      last != null && DateTime.now().difference(last) < _listsTtl;

  Future<List<Vente>> getVentes(
      {String? siteFilter,
      bool forceRefresh = false,
      String? commercialId}) async {
    try {
      final siteActuel = _userSession.site;
      final isAdmin = _userSession.role == 'Admin' ||
          _userSession.role == 'Magazinier' ||
          _userSession.role == 'Gestionnaire Commercial';
      if (!forceRefresh &&
          _cacheVentes != null &&
          _isCacheValid(_lastVentesFetch)) {
        _log('⚡ [VenteService] Ventes depuis cache (${_cacheVentes!.length})');
        return _filtrerVentes(
            _cacheVentes!, siteFilter, commercialId, isAdmin, siteActuel);
      }
      // Si admin: multi-site (collection par site). Sinon: site session uniquement
      final sites = (isAdmin && siteFilter == null)
          ? this.sites // liste globale des sites définie plus haut
          : [siteFilter ?? siteActuel ?? 'Site_Inconnu'];
      final List<Vente> toutes = [];
      for (final site in sites) {
        _ventesFetchCount++; // count Firestore site fetch
        final snap = await _firestore
            .collection('Vente')
            .doc(site)
            .collection('ventes')
            .orderBy('dateVente', descending: true)
            .get();
        toutes.addAll(snap.docs.map((d) => Vente.fromMap(d.data())));
      }
      _cacheVentes = toutes;
      _lastVentesFetch = DateTime.now();
      return _filtrerVentes(
          toutes, siteFilter, commercialId, isAdmin, siteActuel);
    } catch (e) {
      debugPrint('❌ [VenteService] Erreur getVentes: $e');
      return [];
    }
  }

  List<Vente> _filtrerVentes(List<Vente> source, String? siteFilter,
      String? commercialId, bool isAdmin, String? siteActuel) {
    return source.where((v) {
      if (!isAdmin) {
        // Si un commercialId est fourni, on filtre dessus. Sinon (ex: Caissier), on ne filtre pas par commercial.
        if (commercialId != null && v.commercialId != commercialId) {
          return false;
        }
      }
      if (siteFilter != null) {
        // Pas de champ site direct dans Vente; on dérive via commercial / TODO: ajouter site lors enregistrement si nécessaire
        // Ici on passe sans filtrer faute de champ fiable.
      }
      if (commercialId != null && v.commercialId != commercialId) return false;
      return true;
    }).toList();
  }

  Future<List<Restitution>> getRestitutions(
      {String? siteFilter,
      bool forceRefresh = false,
      String? commercialId}) async {
    try {
      final siteActuel = _userSession.site;
      final isAdmin = _userSession.role == 'Admin' ||
          _userSession.role == 'Magazinier' ||
          _userSession.role == 'Gestionnaire Commercial';
      if (!forceRefresh &&
          _cacheRestitutions != null &&
          _isCacheValid(_lastRestitutionsFetch)) {
        _log(
            '⚡ [VenteService] Restitutions depuis cache (${_cacheRestitutions!.length})');
        return _filtrerRestitutions(
            _cacheRestitutions!, siteFilter, commercialId, isAdmin, siteActuel);
      }
      final sites = (isAdmin && siteFilter == null)
          ? this.sites
          : [siteFilter ?? siteActuel ?? 'Site_Inconnu'];
      final List<Restitution> toutes = [];
      for (final site in sites) {
        _restitutionsFetchCount++;
        final snap = await _firestore
            .collection('Vente')
            .doc(site)
            .collection('restitutions')
            .orderBy('dateRestitution', descending: true)
            .get();
        toutes.addAll(snap.docs.map((d) => Restitution.fromMap(d.data())));
      }
      _cacheRestitutions = toutes;
      _lastRestitutionsFetch = DateTime.now();
      return _filtrerRestitutions(
          toutes, siteFilter, commercialId, isAdmin, siteActuel);
    } catch (e) {
      debugPrint('❌ [VenteService] Erreur getRestitutions: $e');
      return [];
    }
  }

  List<Restitution> _filtrerRestitutions(
      List<Restitution> source,
      String? siteFilter,
      String? commercialId,
      bool isAdmin,
      String? siteActuel) {
    return source.where((r) {
      if (!isAdmin) {
        if (commercialId != null && r.commercialId != commercialId)
          return false;
        // site non stocké non plus => possibilité d'ajouter plus tard
      }
      if (commercialId != null && r.commercialId != commercialId) return false;
      return true;
    }).toList();
  }

  Future<List<Perte>> getPertes(
      {String? siteFilter,
      bool forceRefresh = false,
      String? commercialId,
      bool? validee}) async {
    try {
      final siteActuel = _userSession.site;
      final isAdmin = _userSession.role == 'Admin' ||
          _userSession.role == 'Magazinier' ||
          _userSession.role == 'Gestionnaire Commercial';
      if (!forceRefresh &&
          _cachePertes != null &&
          _isCacheValid(_lastPertesFetch)) {
        _log('⚡ [VenteService] Pertes depuis cache (${_cachePertes!.length})');
        return _filtrerPertes(_cachePertes!, siteFilter, commercialId, validee,
            isAdmin, siteActuel);
      }
      final sites = (isAdmin && siteFilter == null)
          ? this.sites
          : [siteFilter ?? siteActuel ?? 'Site_Inconnu'];
      final List<Perte> toutes = [];
      for (final site in sites) {
        _pertesFetchCount++;
        final snap = await _firestore
            .collection('Vente')
            .doc(site)
            .collection('pertes')
            .orderBy('datePerte', descending: true)
            .get();
        toutes.addAll(snap.docs.map((d) => Perte.fromMap(d.data())));
      }
      _cachePertes = toutes;
      _lastPertesFetch = DateTime.now();
      return _filtrerPertes(
          toutes, siteFilter, commercialId, validee, isAdmin, siteActuel);
    } catch (e) {
      debugPrint('❌ [VenteService] Erreur getPertes: $e');
      return [];
    }
  }

  List<Perte> _filtrerPertes(List<Perte> source, String? siteFilter,
      String? commercialId, bool? validee, bool isAdmin, String? siteActuel) {
    return source.where((p) {
      if (!isAdmin) {
        if (commercialId != null && p.commercialId != commercialId)
          return false;
      }
      if (commercialId != null && p.commercialId != commercialId) return false;
      if (validee != null && p.estValidee != validee) return false;
      return true;
    }).toList();
  }

  Future<List<Prelevement>> getPrelevementsAdmin(
      {String? siteFilter,
      bool forceRefresh = false,
      String? commercialId}) async {
    try {
      final siteActuel = _userSession.site;
      final isAdmin = _userSession.role == 'Admin' ||
          _userSession.role == 'Magazinier' ||
          _userSession.role == 'Gestionnaire Commercial';
      if (!isAdmin) {
        return getPrelevementsCommercial(
            commercialId ?? _userSession.email ?? '');
      }
      if (!forceRefresh &&
          _cachePrelevementsAdmin != null &&
          _isCacheValid(_lastPrelevementsAdminFetch)) {
        _log(
            '⚡ [VenteService] Prelevements (admin) depuis cache (${_cachePrelevementsAdmin!.length})');
        return _filtrerPrelevements(_cachePrelevementsAdmin!, siteFilter,
            commercialId, true, siteActuel);
      }
      final sites = (siteFilter == null) ? this.sites : [siteFilter];
      final List<Prelevement> tous = [];
      for (final site in sites) {
        _prelevementsFetchCount++;
        final snap = await _firestore
            .collection('Vente')
            .doc(site)
            .collection('prelevements')
            .orderBy('datePrelevement', descending: true)
            .get();
        tous.addAll(snap.docs.map((d) => Prelevement.fromMap(d.data())));
      }
      _cachePrelevementsAdmin = tous;
      _lastPrelevementsAdminFetch = DateTime.now();
      return _filtrerPrelevements(
          tous, siteFilter, commercialId, true, siteActuel);
    } catch (e) {
      debugPrint('❌ [VenteService] Erreur getPrelevementsAdmin: $e');
      return [];
    }
  }

  List<Prelevement> _filtrerPrelevements(
      List<Prelevement> source,
      String? siteFilter,
      String? commercialId,
      bool isAdmin,
      String? siteActuel) {
    return source.where((pr) {
      if (!isAdmin) {
        if (commercialId != null && pr.commercialId != commercialId)
          return false;
      }
      if (commercialId != null && pr.commercialId != commercialId) return false;
      return true;
    }).toList();
  }

  /// 🔥 NOUVELLES STATISTIQUES - Intégration complète avec le module conditionnement
  Future<Map<String, dynamic>> getStatistiquesVenteComplete(
      {String? siteFilter}) async {
    try {
      _log(
          '📊 [VenteService] Calcul statistiques complètes (filtre=${siteFilter ?? 'Tous'})');

      // Reuse cache (pas de forceRefresh ici pour rapidité UI)
      final produits = await getProduitsConditionnesTotalement(
        siteFilter: siteFilter,
        forceRefresh: false,
      );
      final conditionnements = conditionnementService.conditionnements;

      // Calculer les statistiques en temps réel
      final totalProduits = produits.length;
      final valeurStock = produits.fold(0.0, (sum, p) => sum + p.valeurTotale);
      final quantiteStock =
          produits.fold(0, (sum, p) => sum + p.quantiteDisponible);

      // Analyser la répartition par type d'emballage
      final Map<String, Map<String, dynamic>> repartitionEmballages = {};
      for (final produit in produits) {
        final type = produit.typeEmballage;
        if (!repartitionEmballages.containsKey(type)) {
          repartitionEmballages[type] = {
            'quantite': 0,
            'valeur': 0.0,
            'nombreLots': 0,
          };
        }
        repartitionEmballages[type]!['quantite'] += produit.quantiteDisponible;
        repartitionEmballages[type]!['valeur'] += produit.valeurTotale;
        repartitionEmballages[type]!['nombreLots'] += 1;
      }

      // Analyser la répartition par site
      final Map<String, Map<String, dynamic>> repartitionSites = {};
      for (final produit in produits) {
        final site = produit.siteOrigine;
        if (!repartitionSites.containsKey(site)) {
          repartitionSites[site] = {
            'quantite': 0,
            'valeur': 0.0,
            'nombreLots': 0,
          };
        }
        repartitionSites[site]!['quantite'] += produit.quantiteDisponible;
        repartitionSites[site]!['valeur'] += produit.valeurTotale;
        repartitionSites[site]!['nombreLots'] += 1;
      }

      // Analyser la répartition par prédominance florale
      final Map<String, Map<String, dynamic>> repartitionFlorale = {};
      for (final produit in produits) {
        final florale = produit.predominanceFlorale;
        if (!repartitionFlorale.containsKey(florale)) {
          repartitionFlorale[florale] = {
            'quantite': 0,
            'valeur': 0.0,
            'nombreLots': 0,
          };
        }
        repartitionFlorale[florale]!['quantite'] += produit.quantiteDisponible;
        repartitionFlorale[florale]!['valeur'] += produit.valeurTotale;
        repartitionFlorale[florale]!['nombreLots'] += 1;
      }

      // Calculer les moyennes
      final prixMoyenUnitaire = totalProduits > 0
          ? produits.fold(0.0, (sum, p) => sum + p.prixUnitaire) / totalProduits
          : 0.0;
      final valeurMoyenneParLot =
          totalProduits > 0 ? valeurStock / totalProduits : 0.0;

      // Analyser les dates de conditionnement
      final now = DateTime.now();
      int produitsRecents = 0; // Moins de 30 jours
      int produitsAnciens = 0; // Plus de 6 mois

      for (final produit in produits) {
        final ageJours = now.difference(produit.dateConditionnement).inDays;
        if (ageJours <= 30) {
          produitsRecents++;
        } else if (ageJours >= 180) {
          produitsAnciens++;
        }
      }

      final statistiques = {
        // Métriques principales
        'totalProduits': totalProduits,
        'valeurStock': valeurStock,
        'quantiteStock': quantiteStock,
        'nombreConditionnements': conditionnements.length,

        // Moyennes et analyses
        'prixMoyenUnitaire': prixMoyenUnitaire,
        'valeurMoyenneParLot': valeurMoyenneParLot,
        'produitsRecents': produitsRecents,
        'produitsAnciens': produitsAnciens,

        // Répartitions détaillées
        'repartitionEmballages': repartitionEmballages,
        'repartitionSites': repartitionSites,
        'repartitionFlorale': repartitionFlorale,

        // Métadonnées
        'lastUpdate': DateTime.now().toIso8601String(),
        'siteFilter': siteFilter,
      };

      debugPrint('✅ [VenteService] Statistiques calculées:');
      debugPrint('   📦 Total produits: $totalProduits');
      debugPrint('   💰 Valeur stock: ${valeurStock.toStringAsFixed(0)} FCFA');
      debugPrint('   🏪 Sites actifs: ${repartitionSites.length}');
      debugPrint('   📊 Types emballages: ${repartitionEmballages.length}');

      return statistiques;
    } catch (e, stackTrace) {
      debugPrint('❌ [VenteService] Erreur calcul statistiques complètes: $e');
      debugPrint('📍 Stack trace: $stackTrace');

      // Fallback vers les anciennes statistiques
      return getStatistiquesVente(siteFilter: siteFilter);
    }
  }

  /// Récupère les statistiques globales de vente
  Future<Map<String, dynamic>> getStatistiquesVente(
      {String? siteFilter}) async {
    try {
      debugPrint('📊 Calcul statistiques vente...');

      final sitesToCheck = siteFilter != null ? [siteFilter] : sites;
      final Map<String, dynamic> stats = {
        'totalProduits': 0,
        'valeurStock': 0.0,
        'totalPrelevements': 0,
        'valeurPrelevements': 0.0,
        'totalVentes': 0,
        'chiffredAffaire': 0.0,
        'totalRestitutions': 0,
        'valeurRestitutions': 0.0,
        'totalPertes': 0,
        'valeurPertes': 0.0,
        'repartitionParSite': <String, Map<String, dynamic>>{},
      };

      for (final site in sitesToCheck) {
        // Statistiques par site
        final statsSite = await _getStatistiquesSite(site);
        stats['repartitionParSite'][site] = statsSite;

        // Agrégation globale
        stats['totalProduits'] += statsSite['totalProduits'] ?? 0;
        stats['valeurStock'] += statsSite['valeurStock'] ?? 0.0;
        stats['totalPrelevements'] += statsSite['totalPrelevements'] ?? 0;
        stats['valeurPrelevements'] += statsSite['valeurPrelevements'] ?? 0.0;
        stats['totalVentes'] += statsSite['totalVentes'] ?? 0;
        stats['chiffredAffaire'] += statsSite['chiffredAffaire'] ?? 0.0;
        stats['totalRestitutions'] += statsSite['totalRestitutions'] ?? 0;
        stats['valeurRestitutions'] += statsSite['valeurRestitutions'] ?? 0.0;
        stats['totalPertes'] += statsSite['totalPertes'] ?? 0;
        stats['valeurPertes'] += statsSite['valeurPertes'] ?? 0.0;
      }

      debugPrint('✅ Statistiques calculées');
      debugPrint('   📦 Total produits: ${stats['totalProduits']}');
      debugPrint('   💰 Valeur stock: ${stats['valeurStock']} FCFA');
      debugPrint('   🛒 Chiffre d\'affaire: ${stats['chiffredAffaire']} FCFA');

      return stats;
    } catch (e) {
      debugPrint('❌ Erreur calcul statistiques: $e');
      return {};
    }
  }

  /// Récupère les statistiques d'un site spécifique
  Future<Map<String, dynamic>> _getStatistiquesSite(String site) async {
    try {
      // Compter les produits conditionnés disponibles
      final produits = await getProduitsConditionnes(siteFilter: site);
      final totalProduits = produits.length;
      final valeurStock = produits.fold(0.0, (sum, p) => sum + p.valeurTotale);

      // Compter les prélèvements
      final prelevementsSnapshot = await _firestore
          .collection('Vente')
          .doc(site)
          .collection('prelevements')
          .get();

      final totalPrelevements = prelevementsSnapshot.docs.length;
      final valeurPrelevements =
          prelevementsSnapshot.docs.fold(0.0, (sum, doc) {
        return sum + ((doc.data()['valeurTotale'] ?? 0.0) as double);
      });

      // Compter les ventes
      final ventesSnapshot = await _firestore
          .collection('Vente')
          .doc(site)
          .collection('ventes')
          .get();

      final totalVentes = ventesSnapshot.docs.length;
      final chiffredAffaire = ventesSnapshot.docs.fold(0.0, (sum, doc) {
        return sum + ((doc.data()['montantTotal'] ?? 0.0) as double);
      });

      // Compter les restitutions
      final restitutionsSnapshot = await _firestore
          .collection('Vente')
          .doc(site)
          .collection('restitutions')
          .get();

      final totalRestitutions = restitutionsSnapshot.docs.length;
      final valeurRestitutions =
          restitutionsSnapshot.docs.fold(0.0, (sum, doc) {
        return sum + ((doc.data()['valeurTotale'] ?? 0.0) as double);
      });

      // Compter les pertes
      final pertesSnapshot = await _firestore
          .collection('Vente')
          .doc(site)
          .collection('pertes')
          .get();

      final totalPertes = pertesSnapshot.docs.length;
      final valeurPertes = pertesSnapshot.docs.fold(0.0, (sum, doc) {
        return sum + ((doc.data()['valeurTotale'] ?? 0.0) as double);
      });

      return {
        'totalProduits': totalProduits,
        'valeurStock': valeurStock,
        'totalPrelevements': totalPrelevements,
        'valeurPrelevements': valeurPrelevements,
        'totalVentes': totalVentes,
        'chiffredAffaire': chiffredAffaire,
        'totalRestitutions': totalRestitutions,
        'valeurRestitutions': valeurRestitutions,
        'totalPertes': totalPertes,
        'valeurPertes': valeurPertes,
      };
    } catch (e) {
      debugPrint('❌ Erreur statistiques site $site: $e');
      return {};
    }
  }

  // ====== GESTION DES ATTRIBUTIONS ======

  /// Récupère les attributions pour le commercial actuel
  Future<List<AttributionPartielle>> getAttributionsCommercial() async {
    try {
      final site = _userSession.site ?? '';
      final email = _userSession.email;

      if (site.isEmpty || email == null) {
        debugPrint('⚠️ Site ou email manquant pour charger les attributions');
        return [];
      }

      debugPrint(
          '🔍 Chargement des attributions pour $email sur le site $site');

      final attributions = <AttributionPartielle>[];

      // Liste des commerciaux connus (même liste que dans le controller)
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

      // Parcourir toutes les sous-collections d'attributions
      for (final commercial in commerciauxConnus) {
        final snapshot = await _firestore
            .collection('Gestion Commercial')
            .doc(site)
            .collection('attributions')
            .doc(commercial)
            .collection('historique')
            .get();

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final attribution = AttributionPartielle.fromMap(data);

          // Ne garder que les attributions pour ce commercial
          if (attribution.commercialId == email) {
            attributions.add(attribution);
          }
        }
      }

      debugPrint('✅ ${attributions.length} attributions trouvées pour $email');
      return attributions;
    } catch (e) {
      debugPrint(
          '❌ Erreur lors du chargement des attributions commerciales: $e');
      return [];
    }
  }

  /// Récupère toutes les attributions pour les admins
  Future<List<AttributionPartielle>> getAllAttributionsAdmin() async {
    try {
      final site = _userSession.site ?? '';

      if (site.isEmpty) {
        debugPrint('⚠️ Site manquant pour charger toutes les attributions');
        return [];
      }

      debugPrint(
          '🔍 Chargement de toutes les attributions admin sur le site $site');

      final attributions = <AttributionPartielle>[];

      // Liste des commerciaux connus
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

      // Parcourir toutes les sous-collections d'attributions
      for (final commercial in commerciauxConnus) {
        final snapshot = await _firestore
            .collection('Gestion Commercial')
            .doc(site)
            .collection('attributions')
            .doc(commercial)
            .collection('historique')
            .get();

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final attribution = AttributionPartielle.fromMap(data);
          attributions.add(attribution);
        }
      }

      debugPrint(
          '✅ ${attributions.length} attributions totales trouvées pour admin');
      return attributions;
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement de toutes les attributions: $e');
      return [];
    }
  }
}
