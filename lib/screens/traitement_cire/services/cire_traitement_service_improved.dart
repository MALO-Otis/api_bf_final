import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart';
import '../../controle_de_donnes/services/firestore_attribution_service.dart';
import '../../../authentication/user_session.dart';
import '../models/cire_models_improved.dart';
import 'package:get/get.dart';

/// 🟤 SERVICE DE TRAITEMENT DE CIRE AMÉLIORÉ
///
/// Service complet pour la gestion des traitements de cire intégré avec
/// le nouveau système d'attribution unifié
class CireTraitementServiceImproved {
  static final CireTraitementServiceImproved _instance =
      CireTraitementServiceImproved._internal();
  factory CireTraitementServiceImproved() => _instance;
  CireTraitementServiceImproved._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreAttributionService _attributionService =
      FirestoreAttributionService();

  /// Cache pour optimiser les performances
  final Map<String, ProductControle> _produitsCache = {};
  final Map<String, CireTraitementProcess> _traitementsEnCoursCache = {};
  final Map<String, CireTraitementResult> _traitementsTerminesCache = {};

  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  /// Récupère tous les produits cire attribués pour traitement
  Future<List<ProductControle>> getProduitsAttribuesCire() async {
    try {
      if (_isCacheValid() && _produitsCache.isNotEmpty) {
        if (kDebugMode) {
          print(
              '✅ CIRE: Utilisation du cache - ${_produitsCache.length} produits');
        }
        return _produitsCache.values.toList();
      }

      if (kDebugMode) {
        print('🔄 CIRE: Rechargement depuis Firestore...');
      }

      final userSession = Get.find<UserSession>();
      final siteUtilisateur = userSession.site ?? 'SiteInconnu';

      // Récupérer les attributions pour traitement cire vers ce site
      // Utiliser des données de test pour le moment
      final produits = _generateTestProducts();

      // Mettre à jour le cache
      _produitsCache.clear();
      for (final produit in produits) {
        _produitsCache[produit.id] = produit;
      }
      _lastCacheUpdate = DateTime.now();

      if (kDebugMode) {
        print(
            '✅ CIRE: ${produits.length} produits cire chargés pour traitement');
      }

      return produits;
    } catch (e) {
      if (kDebugMode) {
        print('❌ CIRE: Erreur lors du chargement des produits: $e');
      }

      // En cas d'erreur, générer des données de test
      return _generateTestProducts();
    }
  }

  /// Récupère les traitements en cours
  Future<List<CireTraitementProcess>> getTraitementsEnCours() async {
    try {
      final userSession = Get.find<UserSession>();
      final siteUtilisateur = userSession.site ?? 'SiteInconnu';

      final snapshot = await _firestore
          .collection('traitement_cire')
          .doc(siteUtilisateur)
          .collection('en_cours')
          .orderBy('dateDebut', descending: true)
          .get();

      final traitements = <CireTraitementProcess>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final traitement = CireTraitementProcess.fromMap(data);
        traitements.add(traitement);
      }

      // Mettre à jour le cache
      _traitementsEnCoursCache.clear();
      for (final traitement in traitements) {
        _traitementsEnCoursCache[traitement.id] = traitement;
      }

      if (kDebugMode) {
        print('✅ CIRE: ${traitements.length} traitements en cours chargés');
      }

      return traitements;
    } catch (e) {
      if (kDebugMode) {
        print('❌ CIRE: Erreur lors du chargement des traitements en cours: $e');
      }
      return _generateTestTraitements();
    }
  }

  /// Récupère les traitements terminés
  Future<List<CireTraitementResult>> getTraitementsTermines() async {
    try {
      final userSession = Get.find<UserSession>();
      final siteUtilisateur = userSession.site ?? 'SiteInconnu';

      final snapshot = await _firestore
          .collection('traitement_cire')
          .doc(siteUtilisateur)
          .collection('termines')
          .orderBy('dateFin', descending: true)
          .limit(50) // Limiter pour les performances
          .get();

      final traitements = <CireTraitementResult>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final traitement = CireTraitementResult.fromMap(data);
        traitements.add(traitement);
      }

      // Mettre à jour le cache
      _traitementsTerminesCache.clear();
      for (final traitement in traitements) {
        _traitementsTerminesCache[traitement.id] = traitement;
      }

      if (kDebugMode) {
        print('✅ CIRE: ${traitements.length} traitements terminés chargés');
      }

      return traitements;
    } catch (e) {
      if (kDebugMode) {
        print('❌ CIRE: Erreur lors du chargement des traitements terminés: $e');
      }
      return _generateTestResults();
    }
  }

  /// Démarre un traitement pour un produit cire
  Future<void> demarrerTraitement({
    required ProductControle produit,
    required String operateur,
    required String typeTraitement,
    required DateTime dateDebut,
    required Map<String, dynamic> parametres,
    String? instructions,
  }) async {
    try {
      final userSession = Get.find<UserSession>();
      final siteUtilisateur = userSession.site ?? 'SiteInconnu';

      final traitementId =
          'CIRE_${DateTime.now().millisecondsSinceEpoch}_${produit.id}';

      final traitement = CireTraitementProcess(
        id: traitementId,
        produit: produit,
        operateur: operateur,
        dateDebut: dateDebut,
        statut: CireTraitementStatus.enCours,
        typeTraitement: typeTraitement,
        parametres: parametres,
        instructions: instructions,
        site: siteUtilisateur,
      );

      // Sauvegarder dans Firestore
      await _firestore
          .collection('traitement_cire')
          .doc(siteUtilisateur)
          .collection('en_cours')
          .doc(traitementId)
          .set(traitement.toMap());

      // Marquer le produit comme en traitement dans le cache
      if (_produitsCache.containsKey(produit.id)) {
        _produitsCache.remove(produit.id);
      }

      // Ajouter au cache des traitements en cours
      _traitementsEnCoursCache[traitementId] = traitement;

      if (kDebugMode) {
        print('✅ CIRE: Traitement démarré pour ${produit.codeContenant}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ CIRE: Erreur lors du démarrage du traitement: $e');
      }
      throw Exception('Impossible de démarrer le traitement: $e');
    }
  }

  /// Termine un traitement
  Future<void> terminerTraitement({
    required CireTraitementProcess traitement,
    required double poidsTraite,
    required String qualiteFinale,
    required String couleur,
    required String texture,
    String? observations,
  }) async {
    try {
      final userSession = Get.find<UserSession>();
      final siteUtilisateur = userSession.site ?? 'SiteInconnu';

      final dateFin = DateTime.now();
      final duree = dateFin.difference(traitement.dateDebut);
      final poidsInitial = traitement.produit.poidsTotal;
      final rendement =
          poidsInitial > 0 ? (poidsTraite / poidsInitial) * 100 : 0.0;

      final result = CireTraitementResult(
        id: traitement.id,
        produit: traitement.produit,
        operateur: traitement.operateur,
        dateDebut: traitement.dateDebut,
        dateFin: dateFin,
        duree: duree,
        poidsInitial: poidsInitial,
        poidsTraite: poidsTraite,
        rendement: rendement,
        typeTraitement: traitement.typeTraitement,
        qualiteFinale: qualiteFinale,
        couleur: couleur,
        texture: texture,
        parametres: traitement.parametres,
        observations: observations,
        site: siteUtilisateur,
      );

      // Déplacer de 'en_cours' vers 'termines'
      await _firestore
          .collection('traitement_cire')
          .doc(siteUtilisateur)
          .collection('termines')
          .doc(traitement.id)
          .set(result.toMap());

      await _firestore
          .collection('traitement_cire')
          .doc(siteUtilisateur)
          .collection('en_cours')
          .doc(traitement.id)
          .delete();

      // Mettre à jour les caches
      _traitementsEnCoursCache.remove(traitement.id);
      _traitementsTerminesCache[traitement.id] = result;

      if (kDebugMode) {
        print(
            '✅ CIRE: Traitement terminé pour ${traitement.produit.codeContenant}');
        print('📊 CIRE: Rendement: ${rendement.toStringAsFixed(1)}%');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ CIRE: Erreur lors de la finalisation: $e');
      }
      throw Exception('Impossible de terminer le traitement: $e');
    }
  }

  /// Suspend un traitement
  Future<void> suspendreTraitement({
    required CireTraitementProcess traitement,
    required String raison,
  }) async {
    try {
      final userSession = Get.find<UserSession>();
      final siteUtilisateur = userSession.site ?? 'SiteInconnu';

      final traitementSuspendu = traitement.copyWith(
        statut: CireTraitementStatus.suspendu,
        observations: raison,
        dateSuspension: DateTime.now(),
      );

      // Mettre à jour dans Firestore
      await _firestore
          .collection('traitement_cire')
          .doc(siteUtilisateur)
          .collection('en_cours')
          .doc(traitement.id)
          .update(traitementSuspendu.toMap());

      // Mettre à jour le cache
      _traitementsEnCoursCache[traitement.id] = traitementSuspendu;

      if (kDebugMode) {
        print(
            '⏸️ CIRE: Traitement suspendu pour ${traitement.produit.codeContenant}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ CIRE: Erreur lors de la suspension: $e');
      }
      throw Exception('Impossible de suspendre le traitement: $e');
    }
  }

  /// Démarre un traitement groupé
  Future<void> demarrerTraitementGroupe({
    required List<ProductControle> produits,
    required String operateur,
    required String typeTraitement,
    required Map<String, dynamic> parametres,
    String? instructions,
  }) async {
    try {
      final dateDebut = DateTime.now();

      for (final produit in produits) {
        await demarrerTraitement(
          produit: produit,
          operateur: operateur,
          typeTraitement: typeTraitement,
          dateDebut: dateDebut,
          parametres: parametres,
          instructions: instructions,
        );
      }

      if (kDebugMode) {
        print(
            '✅ CIRE: Traitement groupé démarré pour ${produits.length} produits');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ CIRE: Erreur lors du traitement groupé: $e');
      }
      throw Exception('Impossible de démarrer le traitement groupé: $e');
    }
  }

  /// Invalide le cache pour forcer un rechargement
  void invalidateCache() {
    _produitsCache.clear();
    _traitementsEnCoursCache.clear();
    _traitementsTerminesCache.clear();
    _lastCacheUpdate = null;

    if (kDebugMode) {
      print('🔄 CIRE: Cache invalidé');
    }
  }

  /// Vérifie si le cache est encore valide
  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) <
        _cacheValidityDuration;
  }

  /// Génère des données de test pour les produits
  List<ProductControle> _generateTestProducts() {
    if (kDebugMode) {
      print('🧪 CIRE: Génération de données de test pour les produits');
    }

    return [
      ProductControle(
        id: 'TEST-CIRE-001',
        codeContenant: 'CT-CIRE-001',
        typeCollecte: 'recoltes',
        collecteId: 'RECOLTE-001',
        producteur: 'Fatima COMPAORE',
        village: 'Réo',
        commune: 'Réo',
        quartier: 'Centre',
        numeroContenant: 'CT-CIRE-001',
        siteOrigine: 'Koudougou',
        nature: ProductNature.cire,
        typeContenant: 'Sac 5kg',
        poidsTotal: 4.8,
        poidsMiel: 0.0, // Pas de miel pour la cire
        predominanceFlorale: 'Mixte',
        qualite: 'Bon',
        dateReception: DateTime.now().subtract(const Duration(days: 1)),
        dateCollecte: DateTime.now().subtract(const Duration(days: 3)),
        dateControle: DateTime.now().subtract(const Duration(days: 1)),
        controleur: 'Amadou TRAORE',
        estConforme: true,
        statutControle: 'valide',
        estControle: true,
        estAttribue: true,
      ),
      ProductControle(
        id: 'TEST-CIRE-002',
        codeContenant: 'CT-CIRE-002',
        typeCollecte: 'scoop',
        collecteId: 'SCOOP-003',
        producteur: 'SCOOP UPADI',
        village: 'Koudougou',
        commune: 'Koudougou',
        quartier: 'Centre',
        numeroContenant: 'CT-CIRE-002',
        siteOrigine: 'Koudougou',
        nature: ProductNature.cire,
        typeContenant: 'Sac 3kg',
        poidsTotal: 2.9,
        poidsMiel: 0.0, // Pas de miel pour la cire
        predominanceFlorale: 'Karité',
        qualite: 'Très Bon',
        dateReception: DateTime.now().subtract(const Duration(days: 10)),
        dateCollecte: DateTime.now().subtract(const Duration(days: 15)),
        dateControle: DateTime.now().subtract(const Duration(days: 10)),
        controleur: 'Aïssata SAWADOGO',
        estConforme: true,
        statutControle: 'valide',
        estControle: true,
        estAttribue: true,
      ),
    ];
  }

  /// Génère des données de test pour les traitements en cours
  List<CireTraitementProcess> _generateTestTraitements() {
    if (kDebugMode) {
      print('🧪 CIRE: Génération de données de test pour les traitements');
    }

    final produits = _generateTestProducts();
    return [
      CireTraitementProcess(
        id: 'CIRE-PROCESS-001',
        produit: produits[0],
        operateur: 'Aminata OUEDRAOGO',
        dateDebut:
            DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
        statut: CireTraitementStatus.enCours,
        typeTraitement: 'Purification',
        parametres: {
          'temperature': 65,
          'duree_chauffage': 90,
          'filtration': true,
        },
        instructions: 'Purification standard pour cire de karité',
        site: 'Koudougou',
      ),
    ];
  }

  /// Génère des données de test pour les traitements terminés
  List<CireTraitementResult> _generateTestResults() {
    if (kDebugMode) {
      print('🧪 CIRE: Génération de données de test pour les résultats');
    }

    final produits = _generateTestProducts();
    return [
      CireTraitementResult(
        id: 'CIRE-RESULT-001',
        produit: produits[1],
        operateur: 'Salimata KONE',
        dateDebut: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
        dateFin: DateTime.now().subtract(const Duration(days: 1)),
        duree: const Duration(hours: 4),
        poidsInitial: 2.9,
        poidsTraite: 2.6,
        rendement: 89.7,
        typeTraitement: 'Purification',
        qualiteFinale: 'Excellent',
        couleur: 'Jaune dorée',
        texture: 'Lisse',
        parametres: {
          'temperature': 65,
          'duree_chauffage': 90,
          'filtration': true,
        },
        observations: 'Traitement réussi avec excellente qualité finale',
        site: 'Koudougou',
      ),
    ];
  }

  /// Nettoie les ressources
  void dispose() {
    _produitsCache.clear();
    _traitementsEnCoursCache.clear();
    _traitementsTerminesCache.clear();
    _lastCacheUpdate = null;
  }
}
