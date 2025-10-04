import 'dart:async';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'collecte_reference_data.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apisavana_gestion/authentication/user_session.dart';
import 'package:apisavana_gestion/screens/administration/models/metier_models.dart';
import 'package:apisavana_gestion/screens/administration/services/metier_settings_service.dart';

/// Segment de produit utilisé pour déterminer le barème de prix.
enum CollecteProductSegment {
  monoFloral,
  milleFleurs,
}

extension CollecteProductSegmentX on CollecteProductSegment {
  bool get isMono => this == CollecteProductSegment.monoFloral;

  String get label => isMono ? 'Mono-floral' : 'Mille-fleurs';
}

/// Résumé d'un technicien disponible pour une collecte.
class TechnicianSummary {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? site;
  final bool isActive;
  final Map<String, dynamic> rawData;

  const TechnicianSummary({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.site,
    this.isActive = true,
    this.rawData = const <String, dynamic>{},
  });

  factory TechnicianSummary.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    final prenom = data['prenom']?.toString().trim();
    final nom = data['nom']?.toString().trim();
    final fullNameBuffer = <String>[
      if (prenom != null && prenom.isNotEmpty) prenom,
      if (nom != null && nom.isNotEmpty) nom,
    ];

    final fullName = fullNameBuffer.isNotEmpty
        ? fullNameBuffer.join(' ')
        : (data['nomComplet']?.toString() ?? snapshot.id);

    return TechnicianSummary(
      id: snapshot.id,
      fullName: fullName,
      email: data['email']?.toString(),
      phone: data['telephone']?.toString(),
      site: data['site']?.toString(),
      isActive: (data['isActive'] as bool?) ?? (data['actif'] as bool?) ?? true,
      rawData: data,
    );
  }
}

/// Modèle de prix pour un conditionnement de collecte.
class CollectePackagingPrice {
  final String packagingCode;
  final String label;
  final double monoPrice;
  final double milleFleursPrice;

  const CollectePackagingPrice({
    required this.packagingCode,
    required this.label,
    required this.monoPrice,
    required this.milleFleursPrice,
  });

  double priceFor(CollecteProductSegment segment) {
    return segment.isMono ? monoPrice : milleFleursPrice;
  }
}

/// Service centralisant les données de référence nécessaires au module Collecte.
///
/// - Découpage administratif 2025 (régions/provinces)
/// - Tarifs conditionnements issus de la configuration Métier
/// - Prédominances florales définies par l'administrateur
/// - Liste des techniciens enregistrés dans Firestore
class CollecteReferenceService extends GetxService {
  CollecteReferenceService({
    FirebaseFirestore? firestore,
    MetierSettingsService? metierSettingsService,
    UserSession? userSession,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _metierSettingsServiceOverride = metierSettingsService,
        _userSessionOverride = userSession;

  final FirebaseFirestore _firestore;
  final MetierSettingsService? _metierSettingsServiceOverride;
  final UserSession? _userSessionOverride;

  late final MetierSettingsService _metierService;
  late final UserSession _userSession;

  final RxBool _isReady = false.obs;
  final RxnString _lastError = RxnString();

  final RxList<FloralPredominence> _floralPredominences =
      <FloralPredominence>[].obs;
  final RxList<CollectePackagingPrice> _packagingCatalog =
      <CollectePackagingPrice>[].obs;

  // Listeners pour les mises à jour en temps réel
  StreamSubscription<DocumentSnapshot>? _floralPredominenceListener;
  StreamSubscription<DocumentSnapshot>? _packagingPricesListener;
  StreamSubscription<QuerySnapshot>? _techniciansListener;

  @override
  void onInit() {
    super.onInit();
    initialise();
  }

  @override
  void onClose() {
    // Nettoyer les listeners pour éviter les fuites mémoire
    _floralPredominenceListener?.cancel();
    _packagingPricesListener?.cancel();
    _techniciansListener?.cancel();
    super.onClose();
  }

  bool get isReady => _isReady.value;
  String? get lastError => _lastError.value;

  List<FloralPredominence> get floralPredominences =>
      List<FloralPredominence>.unmodifiable(_floralPredominences);

  List<String> get floralPredominenceNames =>
      floralPredominences.map((pred) => pred.name).toList(growable: false);

  List<CollectePackagingPrice> get packagingCatalog =>
      List<CollectePackagingPrice>.unmodifiable(_packagingCatalog);

  List<MetierRegion> get regions => CollecteReferenceData2025.regions;

  /// Obtient la liste des sites disponibles à partir des techniciens actifs
  Future<List<String>> get availableSites async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'technicien')
              .where('active', isEqualTo: true)
              .get();

      final Set<String> sites = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final site = data['site']?.toString().trim();
        if (site != null && site.isNotEmpty) {
          sites.add(site);
        }
      }
      return sites.toList()..sort();
    } catch (e) {
      print('Erreur lors du chargement des sites: $e');
      return [];
    }
  }

  List<MetierProvince> provincesForRegion(String regionCode) =>
      CollecteReferenceData2025.provincesForRegion(regionCode);

  MetierRegion? resolveRegion(String name) =>
      CollecteReferenceData2025.resolveRegion(name);

  MetierProvince? resolveProvince(String name) =>
      CollecteReferenceData2025.resolveProvince(name);

  UserSession get currentSession => _userSession;

  /// Obtient le nom du technicien connecté (pour pré-remplir les formulaires)
  String? get currentTechnicianName {
    // Si l'utilisateur a le rôle technicien, admin ou collecteur, retourner son nom
    final userRoles = _userSession.roles;
    if (userRoles.contains('technicien') ||
        userRoles.contains('admin') ||
        userRoles.contains('collecteur')) {
      // Utiliser le nom disponible dans UserSession
      final nom = _userSession.nom ?? '';

      print(
          '[CollecteReferenceService] 🔄 Préremplissage technicien: $nom (rôles: $userRoles)');
      return nom.isNotEmpty ? nom : null;
    }

    // Sinon retourner null pour laisser le choix
    return null;
  }

  Future<void> initialise() async {
    if (_isReady.value) return;

    _userSession = _userSessionOverride ??
        (Get.isRegistered<UserSession>()
            ? Get.find<UserSession>()
            : Get.put(UserSession(), permanent: true));
    _metierService = _metierSettingsServiceOverride ??
        (Get.isRegistered<MetierSettingsService>()
            ? Get.find<MetierSettingsService>()
            : Get.put(MetierSettingsService(), permanent: true));

    try {
      // Charger les vraies données depuis Firestore au lieu de MetierSettingsService
      await _loadRealFirestoreData();

      // Configurer les listeners en temps réel (temporairement désactivé pour debug Firestore)
      // _setupRealtimeListeners();

      _isReady.value = true;
    } catch (e) {
      _lastError.value = 'Erreur initialisation CollecteReferenceService: $e';
      print('[CollecteReferenceService] ❌ Erreur: $e');

      // Fallback sur l'ancien système en cas d'erreur
      try {
        await _ensureMetierSettingsLoaded();
        _hydrateFromMetierSettings();
        _isReady.value = true;
        print(
            '[CollecteReferenceService] ⚠️ Utilisation fallback MetierSettingsService');
      } catch (fallbackError) {
        print('[CollecteReferenceService] ❌ Erreur fallback: $fallbackError');
        rethrow;
      }
    }
  }

  Future<void> refreshMetierReferences() async {
    await _ensureMetierSettingsLoaded(force: true);
    _hydrateFromMetierSettings();
  }

  /// Configure les listeners en temps réel pour les mises à jour Firestore
  void _setupRealtimeListeners() {
    print(
        '[CollecteReferenceService] 🔄 Configuration des listeners temps réel...');

    // S'assurer d'annuler les listeners existants d'abord
    _floralPredominenceListener?.cancel();
    _packagingPricesListener?.cancel();
    _techniciansListener?.cancel();

    try {
      // Listener pour les prédominances florales
      _floralPredominenceListener = _firestore
          .collection('metiers')
          .doc('predominence_florale')
          .snapshots()
          .handleError((error) {
        print('[CollecteReferenceService] ❌ Erreur listener florales: $error');
      }).listen((snapshot) {
        if (snapshot.exists) {
          print(
              '[CollecteReferenceService] 🔄 Mise à jour prédominances florales détectée');
          _updateFloralPredominencesFromSnapshot(snapshot);
        }
      });

      // Listener pour les prix d'emballage
      _packagingPricesListener = _firestore
          .collection('metiers')
          .doc('prix_produits')
          .snapshots()
          .handleError((error) {
        print('[CollecteReferenceService] ❌ Erreur listener prix: $error');
      }).listen((snapshot) {
        if (snapshot.exists) {
          print(
              '[CollecteReferenceService] 🔄 Mise à jour prix emballage détectée');
          _updatePackagingPricesFromSnapshot(snapshot);
        }
      });

      // Listener pour les techniciens
      _techniciansListener = _firestore
          .collection('users')
          .where('role', isEqualTo: 'technicien')
          .where('active', isEqualTo: true)
          .snapshots()
          .handleError((error) {
        print(
            '[CollecteReferenceService] ❌ Erreur listener techniciens: $error');
      }).listen((snapshot) {
        print(
            '[CollecteReferenceService] 🔄 Mise à jour techniciens détectée (${snapshot.docs.length} techniciens)');
        // Pour les mises à jour temps réel, pas besoin de GetBuilder.update() car on utilise Rx
      });

      print('[CollecteReferenceService] ✅ Listeners temps réel configurés');
    } catch (e) {
      print(
          '[CollecteReferenceService] ❌ Erreur lors de la configuration des listeners: $e');
    }
  }

  /// Met à jour les prédominances florales depuis un snapshot Firestore
  void _updateFloralPredominencesFromSnapshot(DocumentSnapshot snapshot) {
    try {
      print(
          '[CollecteReferenceService] 🔄 Mise à jour des prédominances florales...');
      // Recharger les données complètement
      _loadRealFloralPredominences();
    } catch (e) {
      print('[CollecteReferenceService] ❌ Erreur mise à jour florales: $e');
    }
  }

  /// Met à jour les prix d'emballage depuis un snapshot Firestore
  void _updatePackagingPricesFromSnapshot(DocumentSnapshot snapshot) {
    try {
      print(
          '[CollecteReferenceService] 🔄 Mise à jour des prix d\'emballage...');
      // Recharger les données complètement
      _loadRealPackagingPrices();
    } catch (e) {
      print('[CollecteReferenceService] ❌ Erreur mise à jour prix: $e');
    }
  }

  /// Méthode pour rafraîchir manuellement toutes les données
  Future<void> refreshAllData() async {
    print(
        '[CollecteReferenceService] 🔄 Rafraîchissement manuel des données...');
    try {
      await _loadRealFirestoreData();
      print('[CollecteReferenceService] ✅ Rafraîchissement terminé');
    } catch (e) {
      print('[CollecteReferenceService] ❌ Erreur rafraîchissement: $e');
      _lastError.value = 'Erreur rafraîchissement: $e';
      rethrow;
    }
  }

  Future<List<TechnicianSummary>> fetchTechnicians({String? site}) async {
    Query<Map<String, dynamic>> query = _firestore.collection('utilisateurs');

    query = query.where('roles', arrayContains: 'technicien');
    if (site != null && site.trim().isNotEmpty) {
      query = query.where('site', isEqualTo: site.trim());
    }

    final snapshot = await query.get();
    final technicians = snapshot.docs
        .map(TechnicianSummary.fromSnapshot)
        .where((tech) => tech.isActive)
        .toList();

    technicians.sort((a, b) => a.fullName.compareTo(b.fullName));
    return technicians;
  }

  Stream<List<TechnicianSummary>> watchTechnicians({String? site}) {
    Query<Map<String, dynamic>> query = _firestore.collection('utilisateurs');
    query = query.where('roles', arrayContains: 'technicien');

    if (site != null && site.trim().isNotEmpty) {
      query = query.where('site', isEqualTo: site.trim());
    }

    return query.snapshots().map((snapshot) {
      final technicians = snapshot.docs
          .map(TechnicianSummary.fromSnapshot)
          .where((tech) => tech.isActive)
          .toList();
      technicians.sort((a, b) => a.fullName.compareTo(b.fullName));
      return technicians;
    });
  }

  CollectePackagingPrice? packagingByCode(String code) {
    return _packagingCatalog
        .firstWhereOrNull((entry) => entry.packagingCode == code);
  }

  CollectePackagingPrice? packagingByLabel(String label) {
    final normalized = label.trim().toLowerCase();
    return _packagingCatalog.firstWhereOrNull(
      (entry) => entry.label.toLowerCase() == normalized,
    );
  }

  double? priceForPackaging({
    required String packagingCode,
    CollecteProductSegment segment = CollecteProductSegment.milleFleurs,
  }) {
    final packaging = packagingByCode(packagingCode);
    return packaging?.priceFor(segment);
  }

  double? priceForLabel({
    required String packagingLabel,
    CollecteProductSegment segment = CollecteProductSegment.milleFleurs,
  }) {
    final packaging = packagingByLabel(packagingLabel);
    return packaging?.priceFor(segment);
  }

  /// Tentative de résolution du conditionnement via le poids (kg).
  CollectePackagingPrice? resolvePackagingByWeight(
    double weightKg, {
    double tolerance = 0.05,
  }) {
    if (weightKg <= 0) return null;
    final normalized = double.parse(weightKg.toStringAsFixed(3));

    final Map<String, double> referenceWeights = {
      '7kg': 7.0,
      '1.5kg': 1.5,
      '1kg': 1.0,
      '720g': 0.72,
      '500g': 0.5,
      '250g': 0.25,
      '125g': 0.125,
      '30g': 0.03,
      '20g': 0.02,
    };

    final match = referenceWeights.entries.firstWhereOrNull((entry) {
      final ref = entry.value;
      final delta = (normalized - ref).abs();
      return delta <= math.max(ref * tolerance, 0.01);
    });

    if (match == null) return null;
    return packagingByCode(match.key);
  }

  double? priceForWeight(
    double weightKg, {
    CollecteProductSegment segment = CollecteProductSegment.milleFleurs,
    double tolerance = 0.05,
  }) {
    final packaging = resolvePackagingByWeight(weightKg, tolerance: tolerance);
    return packaging?.priceFor(segment);
  }

  Future<void> _ensureMetierSettingsLoaded({bool force = false}) async {
    if (force || _metierService.predominences.isEmpty) {
      await _metierService.loadMetierSettings();
    }
  }

  /// Charge les vraies données depuis Firestore
  Future<void> _loadRealFirestoreData() async {
    print(
        '[CollecteReferenceService] 🔄 Chargement des vraies données Firestore...');

    await Future.wait([
      _loadRealFloralPredominences(),
      _loadRealPackagingPrices(),
      _loadCurrentUserName(),
    ]);

    print(
        '[CollecteReferenceService] ✅ Vraies données Firestore chargées avec succès');
  }

  /// Charge les prédominances florales depuis /metiers/predominence_florale
  Future<void> _loadRealFloralPredominences() async {
    try {
      final doc = await _firestore
          .collection('metiers')
          .doc('predominence_florale')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final entries = data['entries'] as List<dynamic>?;

        if (entries != null) {
          final List<FloralPredominence> florales = [];

          for (final entry in entries) {
            final entryMap = entry as Map<String, dynamic>;
            final id = entryMap['id'] as String?;
            final name = entryMap['name'] as String?;

            if (id != null && name != null) {
              florales.add(FloralPredominence(
                id: id,
                name: name,
              ));
            }
          }

          _floralPredominences.assignAll(florales);
          print(
              '[CollecteReferenceService] ✅ ${florales.length} prédominances florales chargées depuis Firestore');
          return;
        }
      }

      throw Exception(
          'Prédominances florales non trouvées dans /metiers/predominence_florale');
    } catch (e) {
      print(
          '[CollecteReferenceService] ❌ Erreur chargement prédominances florales: $e');
      throw e;
    }
  }

  /// Charge les prix depuis /metiers/prix_produits
  Future<void> _loadRealPackagingPrices() async {
    try {
      final doc =
          await _firestore.collection('metiers').doc('prix_produits').get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final monoData = data['mono'] as Map<String, dynamic>?;
        final milleFleursData = data['mille_fleurs'] as Map<String, dynamic>?;
        final packagingOrder = data['packagingOrder'] as List<dynamic>?;

        if (monoData != null &&
            milleFleursData != null &&
            packagingOrder != null) {
          final List<CollectePackagingPrice> catalog = [];

          for (final code in packagingOrder) {
            final codeStr = code.toString();
            final monoPrice = (monoData[codeStr] as num?)?.toDouble() ?? 0.0;
            final milleFleursPrice =
                (milleFleursData[codeStr] as num?)?.toDouble() ?? 0.0;

            catalog.add(CollectePackagingPrice(
              packagingCode: codeStr,
              label: _getLabelForPackaging(codeStr),
              monoPrice: monoPrice,
              milleFleursPrice: milleFleursPrice,
            ));
          }

          _packagingCatalog.assignAll(catalog);
          print(
              '[CollecteReferenceService] ✅ ${catalog.length} prix de conditionnement chargés depuis Firestore');
          return;
        }
      }

      throw Exception('Prix produits non trouvés dans /metiers/prix_produits');
    } catch (e) {
      print('[CollecteReferenceService] ❌ Erreur chargement prix produits: $e');
      throw e;
    }
  }

  /// Charge le nom de l'utilisateur connecté depuis Firestore
  Future<void> _loadCurrentUserName() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        print('[CollecteReferenceService] ⚠️ Aucun utilisateur connecté');
        return;
      }

      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final nom = userData['nom'] as String?;

        if (nom != null && nom.isNotEmpty) {
          // Mettre à jour la session utilisateur avec le nom depuis Firestore
          _userSession.nom = nom;
          print(
              '[CollecteReferenceService] ✅ Nom utilisateur connecté chargé depuis Firestore: $nom');
        }
      } else {
        print(
            '[CollecteReferenceService] ⚠️ Document utilisateur non trouvé pour UID: $uid');
      }
    } catch (e) {
      print(
          '[CollecteReferenceService] ❌ Erreur chargement nom utilisateur: $e');
      // Ne pas faire échouer tout le processus pour cette erreur
    }
  }

  /// Récupère le libellé pour un code de conditionnement
  String _getLabelForPackaging(String code) {
    const Map<String, String> labels = {
      '1kg': 'Pot 1kg',
      '1.5kg': 'Pot 1.5kg',
      '720g': 'Pot 720g',
      '500g': 'Pot 500g',
      '250g': 'Pot 250g',
      '30g': 'Pot 30g',
      '20g': 'Pot 20g',
      '125g': 'Pot 125g',
      '7kg': 'Seau 7kg',
    };

    return labels[code] ?? code;
  }

  void _hydrateFromMetierSettings() {
    _floralPredominences.assignAll(_metierService.predominences);

    final mono = _metierService.monoPackagingPrices;
    final multi = _metierService.milleFleursPackagingPrices;

    final List<CollectePackagingPrice> catalog = kHoneyPackagingOrder
        .map((code) => CollectePackagingPrice(
              packagingCode: code,
              label: kHoneyPackagingLabels[code] ?? code,
              monoPrice: (mono[code] ?? 0).toDouble(),
              milleFleursPrice: (multi[code] ?? 0).toDouble(),
            ))
        .toList();

    _packagingCatalog.assignAll(catalog);
  }
}
