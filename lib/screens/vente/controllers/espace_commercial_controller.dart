import 'dart:async';
import 'package:get/get.dart';
import '../models/vente_models.dart';
import '../services/vente_service.dart';
import 'package:flutter/foundation.dart';
import '../models/commercial_models.dart';
import '../services/commercial_service.dart';
import '../../../authentication/user_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Controller central pour l'Espace Commercial
/// Gère : prélevements, ventes, restitutions, pertes avec logique rôle/site
class EspaceCommercialController extends GetxController {
  final UserSession _session = Get.find<UserSession>();
  final VenteService _venteService = VenteService();
  final CommercialService _commercialService =
      CommercialService(); // pourra servir pour stats spécifiques

  // Etat réactif
  final RxBool isLoading = false.obs;
  final RxString selectedSite = ''.obs; // admin peut changer
  final RxString search = ''.obs;
  final RxInt currentTab = 0.obs;

  // ===================== NOUVELLE SOURCE : ATTRIBUTIONS =====================
  // On remplace progressivement la logique basée sur les prélèvements par les attributions
  final RxList<Prelevement> prelevements =
      <Prelevement>[].obs; // legacy (sera retiré)
  final RxList<AttributionPartielle> attributions =
      <AttributionPartielle>[].obs; // nouvelle base stock
  // Vue réconciliée des attributions : produits restants (quantité) par attribution
  final RxMap<String, int> attributionRestant =
      <String, int>{}.obs; // attributionId -> restant
  final RxMap<String, int> attributionConsomme =
      <String, int>{}.obs; // attributionId -> consommé
  final RxMap<String, double> attributionProgression =
      <String, double>{}.obs; // 0-100
  // Version "réconciliée" : produits restants après ventes/pertes/restitutions
  final RxMap<String, List<ProduitPreleve>> prelevementProduitsRestants =
      <String, List<ProduitPreleve>>{}.obs;
  // Statut calculé dynamiquement (partiel / terminé) sans altérer le modèle original Firestore
  final RxMap<String, StatutPrelevement> prelevementStatutsDynamiques =
      <String, StatutPrelevement>{}.obs;
  // Progression en pourcentage (0-100) pour chaque prélèvement
  final RxMap<String, double> prelevementProgressions = <String, double>{}.obs;
  final RxList<Vente> ventes = <Vente>[].obs;
  final RxList<Restitution> restitutions = <Restitution>[].obs;
  final RxList<Perte> pertes = <Perte>[].obs;
  final RxList<ClientLight> clients = <ClientLight>[].obs;
  int get clientsCount => clients.length;

  // Attribution scope (for non-admin)
  final RxSet<String> _attributedKeys =
      <String>{}.obs; // key format: lotId or numeroLot_type_site
  int get attributedLotsCount => _attributedKeys.length;

  // Diagnostics
  DateTime? _lastFullLoad;
  Duration get ageSinceLastLoad => _lastFullLoad == null
      ? Duration.zero
      : DateTime.now().difference(_lastFullLoad!);
  double get valeurStockCommercial => _commercialService.valeurStockTotale;
  List<String> get availableSites => _venteService.sites;
  // Diagnostics vente service counters
  int get ventesFetchCount => _venteService.ventesFetchCount;
  int get restitutionsFetchCount => _venteService.restitutionsFetchCount;
  int get pertesFetchCount => _venteService.pertesFetchCount;
  int get prelevementsFetchCount => _venteService.prelevementsFetchCount;
  int get attributionLotsCount => attributedLotsCount;
  int get clientsLoaded => clients.length;
  // Avec le refactor : un commercial ne voit QUE ses attributions + opérations liées
  bool get _useAttributionsRefactor =>
      true; // flag unique (peut être rendu paramétrable si besoin

  // ================= UTILISATEURS (résolution noms depuis emails) =================
  final Map<String, String> _userDisplayNameCache = {}; // email -> 'Prenom Nom'
  DateTime? _lastUserFetch;
  final Duration _userCacheTtl = const Duration(minutes: 5);
  bool _userFetchInProgress = false;

  String displayNameForEmail(String? email) {
    if (email == null || email.isEmpty) return 'Inconnu';
    return _userDisplayNameCache[email] ??
        email; // fallback email si pas encore résolu
  }

  Future<void> _resolveUserNamesFromData() async {
    // Collect all emails we need (commercialId + magazinierId + validateur + etc.)
    final Set<String> emails = {};
    for (final p in prelevements) {
      emails.add(p.commercialId);
      emails.add(p.magazinierId);
    }
    for (final v in ventes) {
      emails.add(v.commercialId);
    }
    for (final r in restitutions) {
      emails.add(r.commercialId);
    }
    for (final p in pertes) {
      emails.add(p.commercialId);
      if (p.validateurId != null) emails.add(p.validateurId!);
    }

    emails.removeWhere((e) => e.isEmpty);

    // Filter emails already cached & still valid
    if (_lastUserFetch != null &&
        DateTime.now().difference(_lastUserFetch!) < _userCacheTtl) {
      emails.removeWhere((e) => _userDisplayNameCache.containsKey(e));
      if (emails.isEmpty) return; // nothing new to resolve
    }
    if (emails.isEmpty) return;
    if (_userFetchInProgress) return; // avoid duplicate overlapping fetch
    _userFetchInProgress = true;
    try {
      final firestore = FirebaseFirestore.instance;
      // Firestore whereIn limit: 10 entries. We chunk.
      final List<String> all = emails.toList();
      for (int i = 0; i < all.length; i += 10) {
        final chunk = all.sublist(i, i + 10 > all.length ? all.length : i + 10);
        final snap = await firestore
            .collection('utilisateurs')
            .where('email', whereIn: chunk)
            .get();
        for (final doc in snap.docs) {
          final data = doc.data();
          final email = (data['email'] ?? '') as String;
          final prenom = (data['prenom'] ?? '') as String;
          final nom = (data['nom'] ?? '') as String;
          final full = ([prenom, nom].where((s) => s.trim().isNotEmpty))
              .join(' ')
              .trim();
          if (email.isNotEmpty && full.isNotEmpty) {
            _userDisplayNameCache[email] = full;
          }
        }
      }
      _lastUserFetch = DateTime.now();
      // Déclencher un refresh UI (rx assign pour forcer Obx rebuild si nécessaire)
      prelevements.refresh();
      ventes.refresh();
      restitutions.refresh();
      pertes.refresh();
    } catch (_) {
      // Ignore silently; fallback remains email
    } finally {
      _userFetchInProgress = false;
    }
  }

  bool get isAdminRole {
    final r = _session.role ?? '';
    return r == 'Admin' || r == 'Magazinier' || r == 'Gestionnaire Commercial';
  }

  String get effectiveSite => isAdminRole
      ? (selectedSite.value.isNotEmpty
          ? selectedSite.value
          : (_session.site ?? ''))
      : (_session.site ?? '');

  @override
  void onInit() {
    super.onInit();
    if (!isAdminRole) selectedSite.value = _session.site ?? '';
    _setupRealtimeListeners();
    loadAll();
    if (_useAttributionsRefactor && !isAdminRole) {
      _setupAttributionsListenerCommercial();
    }
  }

  @override
  void onClose() {
    _disposeRealtimeListeners();
    super.onClose();
  }

  Future<void> loadAll({bool forceRefresh = false}) async {
    isLoading.value = true;
    try {
      // 1. Ensure attributions are loaded (populate attribution cache)
      await _commercialService.getLotsAvecCache(forceRefresh: forceRefresh);
      _buildAttributionScope();

      final siteFilter = isAdminRole
          ? (selectedSite.value.isEmpty ? null : selectedSite.value)
          : _session.site;
      final commercialId = isAdminRole ? null : _session.email;

      final futures = await Future.wait([
        if (!_useAttributionsRefactor)
          _venteService.getPrelevementsAdmin(
              siteFilter: siteFilter,
              forceRefresh: forceRefresh,
              commercialId: commercialId),
        _venteService.getVentes(
            siteFilter: siteFilter,
            forceRefresh: forceRefresh,
            commercialId: commercialId),
        _venteService.getRestitutions(
            siteFilter: siteFilter,
            forceRefresh: forceRefresh,
            commercialId: commercialId),
        _venteService.getPertes(
            siteFilter: siteFilter,
            forceRefresh: forceRefresh,
            commercialId: commercialId),
        _fetchClients(siteFilter: siteFilter, forceRefresh: forceRefresh),
      ]);

      int offset = 0;
      if (!_useAttributionsRefactor) {
        prelevements.assignAll(futures[offset] as List<Prelevement>);
        offset++;
      }
      ventes.assignAll(futures[offset] as List<Vente>);
      offset++;
      restitutions.assignAll(futures[offset] as List<Restitution>);
      offset++;
      pertes.assignAll(futures[offset] as List<Perte>);
      offset++;
      clients.assignAll(futures[offset] as List<ClientLight>);

      if (_useAttributionsRefactor) {
        if (!isAdminRole) _filtrerOperationsParCommercial();
        _reconcilierAttributions();
      } else {
        if (!isAdminRole) _applyAttributionFilter();
        _reconcilierPrelevements();
      }
      // Résolution des noms après filtrage
      await _resolveUserNamesFromData();
      _lastFullLoad = DateTime.now();
    } catch (e) {
      // Ignore, UI montrera message via snackbar si voulu
    } finally {
      isLoading.value = false;
    }
  }

  /// 🎯 NOUVELLE MÉTHODE : Charge les vraies attributions depuis Gestion Commercial
  /// Remplace la logique des prélèvements pour "Mes Prélèvements"
  Future<void> ensureAttributionsLoaded({bool forceRefresh = false}) async {
    // Si déjà chargé et pas de refresh forcé on ne refait rien
    if (attributions.isNotEmpty && !forceRefresh) return;

    try {
      debugPrint(
          '🔄 ensureAttributionsLoaded (forceRefresh=$forceRefresh) démarré');
      debugPrint(
          '👤 Mode utilisateur: ${isAdminRole ? 'ADMIN' : 'COMMERCIAL'}');

      List<AttributionPartielle> data;

      if (isAdminRole) {
        // 👑 ADMIN : Récupérer TOUTES les attributions de TOUS les commerciaux
        debugPrint('👑 Mode ADMIN : récupération de toutes les attributions');
        final site =
            selectedSite.value.isEmpty ? _session.site : selectedSite.value;
        debugPrint('📍 Site sélectionné pour admin: $site');

        data = await _venteService.getAllAttributionsAdmin(site: site);
        debugPrint('👑 ADMIN : ${data.length} attributions totales récupérées');
      } else {
        // 👨‍💼 COMMERCIAL : Récupérer seulement ses attributions
        final userEmail = _session.email ?? '';
        if (userEmail.isEmpty) {
          debugPrint(
              '❌ Email utilisateur manquant pour récupérer les attributions');
          return;
        }

        // Convertir l'email en clé commercial (kansiemo_marceline@exemple.com -> kansiemo_marceline)
        final commercialKey = userEmail.split('@').first.toLowerCase();
        final site = _session.site ?? 'Koudougou';

        debugPrint('👨‍� COMMERCIAL : $commercialKey sur site: $site');

        data = await _venteService.getAttributionsCommercial(
          commercialKey: commercialKey,
          site: site,
        );
        debugPrint(
            '👨‍💼 COMMERCIAL : ${data.length} attributions personnelles récupérées');
      }

      attributions.assignAll(data);
      debugPrint(
          '✅ ensureAttributionsLoaded -> ${attributions.length} attributions chargées');

      // Debug détaillé du contenu
      if (attributions.isNotEmpty) {
        debugPrint('📋 CONTENU DES ATTRIBUTIONS RÉCUPÉRÉES:');
        for (int i = 0; i < attributions.length && i < 5; i++) {
          final attr = attributions[i];
          debugPrint(
              '   ${i + 1}. ${attr.commercialNom} - Lot: ${attr.numeroLot} - Qté: ${attr.quantiteAttribuee} - Valeur: ${attr.valeurTotale} FCFA');
        }
        if (attributions.length > 5) {
          debugPrint(
              '   ... et ${attributions.length - 5} autres attributions');
        }
      } else {
        debugPrint('⚠️ AUCUNE ATTRIBUTION TROUVÉE !');
      }

      // 🎯 PLUS DE CONVERSION FICTIVE ! Les attributions sont utilisées directement
    } catch (e) {
      debugPrint('❌ ensureAttributionsLoaded erreur: $e');
    }
  }

  // 🗑️ SUPPRIMÉ : Plus de conversion fictive !

  /// Assure que la liste `prelevements` est chargée même lorsque
  /// le refactor attributions est actif (legacy UI qui en dépend encore)
  Future<void> ensurePrelevementsLoaded({bool forceRefresh = false}) async {
    // 🎯 NOUVELLE LOGIQUE : On charge les attributions au lieu des prélèvements
    await ensureAttributionsLoaded(forceRefresh: forceRefresh);
  }

  // ================= LISTENERS TEMPS RÉEL =================
  final List<StreamSubscription<QuerySnapshot>> _realtimeSubscriptions = [];

  void _setupRealtimeListeners() {
    _disposeRealtimeListeners(); // Cleanup existing

    final site = effectiveSite;
    debugPrint(
        '🔧 [EspaceCommercialController] Configuration listeners temps réel pour site: $site');
    if (site.isEmpty) {
      debugPrint(
          '❌ [EspaceCommercialController] Site vide - pas de listeners configurés');
      return;
    }

    final firestore = FirebaseFirestore.instance;
    // Listener pour les prélèvements (ajouté)
    if (!_useAttributionsRefactor) {
      final prelevementsStream = firestore
          .collection('Vente')
          .doc(site)
          .collection('prelevements')
          .snapshots();

      _realtimeSubscriptions.add(prelevementsStream.listen((snapshot) {
        final prelevs = snapshot.docs
            .map((doc) => Prelevement.fromMap(doc.data()))
            .toList();
        prelevements.assignAll(prelevs);
        _reconcilierPrelevements();
      }));
    }

    // Listener pour les ventes
    debugPrint(
        '🔧 [EspaceCommercialController] Configuration listener ventes: Vente/$site/ventes');
    final ventesStream = firestore
        .collection('Vente')
        .doc(site)
        .collection('ventes')
        .snapshots();

    _realtimeSubscriptions.add(ventesStream.listen((snapshot) {
      debugPrint(
          '🔥 [EspaceCommercialController] Listener ventes déclenché - ${snapshot.docs.length} documents');
      final ventesFromSnapshot =
          snapshot.docs.map((doc) => Vente.fromMap(doc.data())).toList();

      debugPrint(
          '🔥 [EspaceCommercialController] Ventes récupérées: ${ventesFromSnapshot.length}');
      for (final v in ventesFromSnapshot) {
        debugPrint(
            '   - Vente ${v.id}: commercial=${v.commercialId}, client=${v.clientNom}');
      }

      // Filtrer selon les permissions
      final siteFilter = isAdminRole ? null : site;
      final commercialId = isAdminRole ? null : _session.email;
      debugPrint(
          '🔥 [EspaceCommercialController] Filtrage: isAdmin=$isAdminRole, commercialId=$commercialId');
      final filtered =
          _filtrerVentesLocal(ventesFromSnapshot, siteFilter, commercialId);

      debugPrint(
          '🔥 [EspaceCommercialController] Ventes après filtrage: ${filtered.length}');
      ventes.assignAll(filtered);
      if (_useAttributionsRefactor) {
        _reconcilierAttributions();
      } else {
        _reconcilierPrelevements();
      }
    }));

    // Listener pour les restitutions
    final restitutionsStream = firestore
        .collection('Vente')
        .doc(site)
        .collection('restitutions')
        .snapshots();

    _realtimeSubscriptions.add(restitutionsStream.listen((snapshot) {
      final restitutionsFromSnapshot =
          snapshot.docs.map((doc) => Restitution.fromMap(doc.data())).toList();

      final siteFilter = isAdminRole ? null : site;
      final commercialId = isAdminRole ? null : _session.email;
      final filtered = _filtrerRestitutionsLocal(
          restitutionsFromSnapshot, siteFilter, commercialId);

      restitutions.assignAll(filtered);
      if (_useAttributionsRefactor) {
        _reconcilierAttributions();
      } else {
        _reconcilierPrelevements();
      }
    }));

    // Listener pour les pertes
    final pertesStream = firestore
        .collection('Vente')
        .doc(site)
        .collection('pertes')
        .snapshots();

    _realtimeSubscriptions.add(pertesStream.listen((snapshot) {
      final pertesFromSnapshot =
          snapshot.docs.map((doc) => Perte.fromMap(doc.data())).toList();

      final siteFilter = isAdminRole ? null : site;
      final commercialId = isAdminRole ? null : _session.email;
      final filtered =
          _filtrerPertesLocal(pertesFromSnapshot, siteFilter, commercialId);

      pertes.assignAll(filtered);
      if (_useAttributionsRefactor) {
        _reconcilierAttributions();
      } else {
        _reconcilierPrelevements();
      }
    }));
  }

  void _disposeRealtimeListeners() {
    for (final subscription in _realtimeSubscriptions) {
      subscription.cancel();
    }
    _realtimeSubscriptions.clear();
  }

  // Méthodes de filtrage local (sans passer par le service)
  List<Vente> _filtrerVentesLocal(
      List<Vente> source, String? siteFilter, String? commercialId) {
    debugPrint('🔍 [EspaceCommercialController] Filtrage ventes:');
    debugPrint('   📋 Source: ${source.length} ventes');
    debugPrint('   👤 CommercialId attendu: $commercialId');
    debugPrint('   🏢 SiteFilter: $siteFilter');
    debugPrint('   👑 IsAdmin: $isAdminRole');

    final result = source.where((v) {
      // TEMPORAIRE : désactivons le filtrage pour diagnostiquer
      debugPrint(
          '   ✓ Vente ${v.id}: commercial=${v.commercialId} (pas de filtrage appliqué)');
      return true;

      // Code original commenté :
      // if (!isAdminRole && commercialId != null) {
      //   final match = v.commercialId == commercialId;
      //   debugPrint('   ✓ Vente ${v.id}: commercial=${v.commercialId} ${match ? "✅" : "❌"}');
      //   if (!match) return false;
      // }
      // return true;
    }).toList();

    debugPrint('   🎯 Résultat filtrage: ${result.length} ventes conservées');
    return result;
  }

  List<Restitution> _filtrerRestitutionsLocal(
      List<Restitution> source, String? siteFilter, String? commercialId) {
    return source.where((r) {
      if (!isAdminRole && commercialId != null) {
        if (r.commercialId != commercialId) return false;
      }
      return true;
    }).toList();
  }

  List<Perte> _filtrerPertesLocal(
      List<Perte> source, String? siteFilter, String? commercialId) {
    return source.where((p) {
      if (!isAdminRole && commercialId != null) {
        if (p.commercialId != commercialId) return false;
      }
      return true;
    }).toList();
  }

  /// Construit la vue des produits restants pour chaque prélèvement après ventes / restitutions / pertes.
  void _reconcilierPrelevements() {
    // Indexer les quantités vendues par produitId
    final Map<String, int> quantitesVendues = {};
    for (final v in ventes) {
      for (final pv in v.produits) {
        quantitesVendues.update(pv.produitId, (q) => q + pv.quantiteVendue,
            ifAbsent: () => pv.quantiteVendue);
      }
    }
    // Indexer restitutions (on les ajoute aux quantités "sorties" du prélèvement – elles ne doivent plus apparaître comme disponibles)
    final Map<String, int> quantitesRestituees = {};
    for (final r in restitutions) {
      for (final pr in r.produits) {
        quantitesRestituees.update(
            pr.produitId, (q) => q + pr.quantiteRestituee,
            ifAbsent: () => pr.quantiteRestituee);
      }
    }
    // Indexer pertes
    final Map<String, int> quantitesPerdues = {};
    for (final p in pertes) {
      for (final pp in p.produits) {
        quantitesPerdues.update(pp.produitId, (q) => q + pp.quantitePerdue,
            ifAbsent: () => pp.quantitePerdue);
      }
    }

    prelevementProduitsRestants.clear();

    for (final prelevement in prelevements) {
      final List<ProduitPreleve> restants = [];
      int totalInitial = 0;
      int totalRestant = 0;
      for (final prod in prelevement.produits) {
        totalInitial += prod.quantitePreleve;
        final vendue = quantitesVendues[prod.produitId] ?? 0;
        final restituee = quantitesRestituees[prod.produitId] ?? 0;
        final perdue = quantitesPerdues[prod.produitId] ?? 0;
        final sortie = vendue + restituee + perdue;
        final restant = prod.quantitePreleve - sortie;
        if (restant > 0) {
          totalRestant += restant;
          // On recrée un ProduitPreleve avec la quantité restante pour l'affichage
          restants.add(ProduitPreleve(
            produitId: prod.produitId,
            numeroLot: prod.numeroLot,
            typeEmballage: prod.typeEmballage,
            contenanceKg: prod.contenanceKg,
            quantitePreleve: restant,
            prixUnitaire: prod.prixUnitaire,
            valeurTotale: prod.prixUnitaire * restant,
          ));
        }
      }
      prelevementProduitsRestants[prelevement.id] = restants;

      // Statut dynamique prioritaire sur le statut Firestore initial
      final statutDynamique = (totalRestant == 0)
          ? StatutPrelevement.termine
          : (totalRestant < totalInitial)
              ? StatutPrelevement.partiel
              : StatutPrelevement.enCours;
      prelevementStatutsDynamiques[prelevement.id] = statutDynamique;

      // Stocker le pourcentage de progression pour l'affichage
      final progression = totalInitial > 0
          ? ((totalInitial - totalRestant) / totalInitial * 100)
          : 100.0;
      prelevementProgressions[prelevement.id] = progression;
    }
    prelevements.refresh();
    prelevementProduitsRestants.refresh();
    prelevementStatutsDynamiques.refresh();
    prelevementProgressions.refresh();
  }

  // ================= RÉCONCILIATION BASÉE SUR LES ATTRIBUTIONS =================
  void _reconcilierAttributions() {
    if (attributions.isEmpty) {
      attributionRestant.clear();
      attributionConsomme.clear();
      attributionProgression.clear();
      return;
    }
    // Indexer consommations par (numeroLot + typeEmballage + site)
    final Map<String, int> consommeParCle = {};
    String buildKey(String numeroLot, String typeEmb, String site) =>
        '${numeroLot}_${typeEmb}_${site}'.toLowerCase();
    final siteCourant = _session.site ?? '';

    for (final v in ventes) {
      for (final p in v.produits) {
        final cle = buildKey(p.numeroLot, p.typeEmballage, siteCourant);
        consommeParCle.update(cle, (q) => q + p.quantiteVendue,
            ifAbsent: () => p.quantiteVendue);
      }
    }
    for (final r in restitutions) {
      for (final pr in r.produits) {
        final cle = buildKey(pr.numeroLot, pr.typeEmballage, siteCourant);
        consommeParCle.update(cle, (q) => q + pr.quantiteRestituee,
            ifAbsent: () => pr.quantiteRestituee);
      }
    }
    for (final p in pertes) {
      for (final pp in p.produits) {
        final cle = buildKey(pp.numeroLot, pp.typeEmballage, siteCourant);
        consommeParCle.update(cle, (q) => q + pp.quantitePerdue,
            ifAbsent: () => pp.quantitePerdue);
      }
    }

    attributionRestant.clear();
    attributionConsomme.clear();
    attributionProgression.clear();

    for (final a in attributions) {
      final cle = buildKey(a.numeroLot, a.typeEmballage, a.siteOrigine);
      final consomme = consommeParCle[cle] ?? 0;
      final restant =
          (a.quantiteAttribuee - consomme).clamp(0, a.quantiteAttribuee);
      attributionConsomme[a.id] = consomme;
      attributionRestant[a.id] = restant;
      final progression = a.quantiteAttribuee > 0
          ? ((consomme / a.quantiteAttribuee) * 100).clamp(0, 100).toDouble()
          : 100.0;
      attributionProgression[a.id] = progression;
    }
    attributionRestant.refresh();
    attributionConsomme.refresh();
    attributionProgression.refresh();
  }

  // ================= LISTENER ATTRIBUTIONS (COMMERCIAL COURANT) =================
  void _setupAttributionsListenerCommercial() {
    if (isAdminRole) return; // admin: TODO multi-listeners plus tard
    final site = _session.site ?? '';
    final email = _session.email;
    if (site.isEmpty || email == null) return;
    // Normalisation clé commercial : déjà utilisée dans CommercialService (nom complet normalisé)
    // Ici on ne connaît que l'email => il nous faut une résolution Nom->clé.
    // Hypothèse: commercialNom est stocké dans les ventes avec email commercialId.
    // Pour éviter un appel complexe : on fait une requête sur toutes les sous-collections d'attributions et on filtre par commercialId.
    final firestore = FirebaseFirestore.instance;
    final parent = firestore
        .collection('Gestion Commercial')
        .doc(site)
        .collection('attributions');
    // Option minimaliste: écouter toutes les sous-collections des commerciaux connus (liste courte) => réutiliser la même liste que CommercialService.
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

    // On attache un listener par commercial, on filtre ensuite par commercialId = email courant
    for (final key in commerciauxConnus) {
      final stream = parent.doc(key).collection('historique').snapshots();
      _realtimeSubscriptions.add(stream.listen((snap) {
        bool changed = false;
        for (final doc in snap.docs) {
          final data = doc.data();
          final attribution = AttributionPartielle.fromMap(data);
          if (attribution.commercialId == email) {
            final idx = attributions.indexWhere((x) => x.id == attribution.id);
            if (idx >= 0) {
              attributions[idx] = attribution;
            } else {
              attributions.add(attribution);
            }
            changed = true;
          }
        }
        if (changed) {
          attributions
              .sort((a, b) => b.dateAttribution.compareTo(a.dateAttribution));
          _reconcilierAttributions();
        }
      }));
    }
  }

  // Filtrage strict des opérations pour le commercial courant (sans legacy prélèvements)
  void _filtrerOperationsParCommercial() {
    if (isAdminRole) return;
    final commercialId = _session.email;
    if (commercialId == null) return;
    ventes.assignAll(ventes.where((v) => v.commercialId == commercialId));
    restitutions
        .assignAll(restitutions.where((r) => r.commercialId == commercialId));
    pertes.assignAll(pertes.where((p) => p.commercialId == commercialId));
  }

  void _buildAttributionScope() {
    _attributedKeys.clear();
    if (isAdminRole) return; // full access
    final userId = _session.email;
    if (userId == null) return;
    for (final a in _commercialService.attributions) {
      if (a.commercialId == userId) {
        // lotId already unique (constructed previously). Also include fallback composite key
        _attributedKeys.add(a.lotId);
        final composite = '${a.numeroLot}_${a.typeEmballage}_${a.siteOrigine}';
        _attributedKeys.add(composite);
      }
    }
  }

  bool _isAllowedByAttribution(
      {required String numeroLot,
      required String typeEmballage,
      required String site,
      required String lotId}) {
    if (isAdminRole) return true;
    if (_attributedKeys.isEmpty) return false; // no attribution => no access
    final composite = '${numeroLot}_${typeEmballage}_${site}';
    return _attributedKeys.contains(lotId) ||
        _attributedKeys.contains(composite);
  }

  void _applyAttributionFilter() {
    if (isAdminRole) return;
    final site = _session.site ?? '';

    bool produitsAutorises(List produitsDyn) {
      if (produitsDyn.isEmpty) return false;
      // every product must be in scope (strict policy)
      for (final prod in produitsDyn) {
        // dynamic access (ProduitPreleve / ProduitVendu / ProduitRestitue / ProduitPerdu all share numeroLot & typeEmballage)
        final numeroLot = (prod as dynamic).numeroLot as String? ?? '';
        final typeEmballage = (prod as dynamic).typeEmballage as String? ?? '';
        final lotId =
            CommercialUtils.genererIdLot(site, typeEmballage, numeroLot);
        if (!_isAllowedByAttribution(
            numeroLot: numeroLot,
            typeEmballage: typeEmballage,
            site: site,
            lotId: lotId)) {
          return false;
        }
      }
      return true;
    }

    // ⚠️ Nouvelle règle: un commercial voit tous les prélèvements de son site
    // Donc on NE filtre PAS la liste prelevements par attribution.
    ventes.assignAll(ventes.where((v) => produitsAutorises(v.produits)));
    restitutions
        .assignAll(restitutions.where((r) => produitsAutorises(r.produits)));
    pertes.assignAll(pertes.where((p) => produitsAutorises(p.produits)));
  }

  List<T> _applySearch<T>(List<T> source) {
    final q = search.value.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source.where((item) {
      if (item is Vente) {
        return item.clientNom.toLowerCase().contains(q) ||
            item.commercialNom.toLowerCase().contains(q);
      }
      if (item is Prelevement) {
        return item.commercialNom.toLowerCase().contains(q) ||
            item.id.toLowerCase().contains(q);
      }
      if (item is Restitution) {
        return item.commercialNom.toLowerCase().contains(q) ||
            item.motif.toLowerCase().contains(q);
      }
      if (item is Perte) {
        return item.commercialNom.toLowerCase().contains(q) ||
            item.motif.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  List<Prelevement> get filteredPrelevements =>
      _applySearch(prelevements); // legacy
  List<AttributionPartielle> get filteredAttributions =>
      _applySearch(attributions);

  // ==================== MÉTRIQUES ATTRIBUTIONS ====================
  int get totalQuantiteAttribuee =>
      attributions.fold(0, (sum, a) => sum + a.quantiteAttribuee);
  int get totalQuantiteConsommee =>
      attributions.fold(0, (sum, a) => sum + (attributionConsomme[a.id] ?? 0));
  int get totalQuantiteRestante => attributions.fold(
      0,
      (sum, a) =>
          sum +
          (attributionRestant[a.id] ??
              (a.quantiteAttribuee - (attributionConsomme[a.id] ?? 0))));
  double get tauxConsommationGlobal => totalQuantiteAttribuee == 0
      ? 0
      : (totalQuantiteConsommee / totalQuantiteAttribuee) * 100;
  List<Vente> get filteredVentes => _applySearch(ventes);
  List<Restitution> get filteredRestitutions => _applySearch(restitutions);
  List<Perte> get filteredPertes => _applySearch(pertes);
  List<ClientLight> get filteredClients => _applySearch(clients);
}

/// Modèle léger client pour la liste
class ClientLight {
  final String id;
  final String nom;
  final String? nomBoutique;
  final String? telephone;
  final double? latitude;
  final double? longitude;
  final List<String> commercials; // emails des commerciaux liés
  final DateTime? dateCreation;
  ClientLight({
    required this.id,
    required this.nom,
    this.nomBoutique,
    this.telephone,
    this.latitude,
    this.longitude,
    required this.commercials,
    this.dateCreation,
  });
}

extension _ClientFromMap on ClientLight {
  static ClientLight fromFirestore(Map<String, dynamic> data, String id) {
    return ClientLight(
      id: id,
      nom: (data['nomGerant'] ?? data['nom'] ?? data['nomBoutique'] ?? 'Client')
          .toString(),
      nomBoutique: data['nomBoutique']?.toString(),
      telephone: (data['telephone'] ?? data['telephone1'])?.toString(),
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      commercials: _extractCommercials(data),
      dateCreation: (data['dateCreation'] as Timestamp?)?.toDate(),
    );
  }

  static List<String> _extractCommercials(Map<String, dynamic> d) {
    final set = <String>{};
    for (final key in [
      'commercialId',
      'createdBy',
      'commercialEmail',
      'auteur',
    ]) {
      final v = d[key];
      if (v is String && v.isNotEmpty) set.add(v);
    }
    // champs multiples éventuels
    if (d['commerciaux'] is List) {
      for (final c in (d['commerciaux'] as List)) {
        if (c is String && c.isNotEmpty) set.add(c);
      }
    }
    return set.toList();
  }
}

extension _ClientsLoader on EspaceCommercialController {
  Future<List<ClientLight>> _fetchClients({
    String? siteFilter,
    bool forceRefresh = false,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final List<ClientLight> results = [];
      // Source 1: Collection hiérarchique Vente/{site}/clients si site connu
      if (siteFilter != null && siteFilter.isNotEmpty) {
        final snap = await firestore
            .collection('Vente')
            .doc(siteFilter)
            .collection('clients')
            .limit(500)
            .get();
        for (final doc in snap.docs) {
          results.add(_ClientFromMap.fromFirestore(doc.data(), doc.id));
        }
      }
      // Source 2: Collection racine 'clients' (legacy?) filtrée par site si champ présent
      final snapRoot = await firestore.collection('clients').limit(500).get();
      for (final doc in snapRoot.docs) {
        final data = doc.data();
        if (siteFilter != null && siteFilter.isNotEmpty) {
          final siteDoc = (data['site'] ?? data['siteClient'])?.toString();
          if (siteDoc != null && siteDoc != siteFilter) continue;
        }
        results.add(_ClientFromMap.fromFirestore(data, doc.id));
      }
      // Déduplication par id
      final map = <String, ClientLight>{};
      for (final c in results) {
        map[c.id] = c;
      }
      return map.values.toList();
    } catch (_) {
      return [];
    }
  }

  /// 🔧 MÉTHODE SPÉCIFIQUE POUR FORCER LE CHARGEMENT DES PRÉLÈVEMENTS
  /// Utilisée par la page "Mes Prélèvements" même avec le refactor activé
  Future<void> loadPrelevements({bool forceRefresh = false}) async {
    try {
      final siteFilter = isAdminRole
          ? (selectedSite.value.isEmpty ? null : selectedSite.value)
          : _session.site;
      final commercialId = isAdminRole ? null : _session.email;

      final prelevementsData = await _venteService.getPrelevementsAdmin(
          siteFilter: siteFilter,
          forceRefresh: forceRefresh,
          commercialId: commercialId);

      prelevements.assignAll(prelevementsData);

      // Appliquer le filtrage par commercial si nécessaire
      if (!isAdminRole) {
        _applyAttributionFilter();
      }

      debugPrint('✅ Prélèvements chargés: ${prelevements.length}');
    } catch (e) {
      debugPrint('❌ Erreur chargement prélèvements: $e');
    }
  }
}
