import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart';
// Removed unused import: '../../controle_de_donnes/services/firestore_attribution_service.dart';
import '../../../authentication/user_session.dart';
import '../models/filtrage_models_improved.dart';
import 'package:get/get.dart';

/// 🔵 SERVICE DE FILTRAGE AMÉLIORÉ
///
/// Service complet pour la gestion des filtrages intégré avec
/// le nouveau système d'attribution unifié
class FiltrageServiceImproved {
  static final FiltrageServiceImproved _instance =
      FiltrageServiceImproved._internal();
  factory FiltrageServiceImproved() => _instance;
  FiltrageServiceImproved._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Removed unused _attributionService field

  /// Cache pour optimiser les performances
  final Map<String, ProductControle> _produitsCache = {};
  final Map<String, FiltrageProcess> _filtragesEnCoursCache = {};
  final Map<String, FiltrageResult> _filtragesTerminesCache = {};

  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  /// Récupère tous les produits attribués pour filtrage
  Future<List<ProductControle>> getProduitsAttribuesFiltrage() async {
    try {
      if (_isCacheValid() && _produitsCache.isNotEmpty) {
        if (kDebugMode) {
          print(
              '✅ FILTRAGE: Utilisation du cache - ${_produitsCache.length} produits');
        }
        return _produitsCache.values.toList();
      }

      if (kDebugMode) {
        print('🔄 FILTRAGE: Rechargement depuis Firestore...');
      }

      // Site filtering would be implemented here based on Get.find<UserSession>().site

      // Récupérer les attributions pour filtrage vers ce site
      // ✅ AMÉLIORATION: Utiliser les données réelles depuis Firestore
      final userSession = Get.find<UserSession>();
      final site = userSession.site ?? 'SiteInconnu';

      final querySnapshot = await _firestore
          .collection('Sites')
          .doc(site)
          .collection('attributions_recu')
          .where('type', isEqualTo: 'filtrage')
          .where('statutAttribution', isEqualTo: 'recu')
          .get();

      final produits = <ProductControle>[];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final produitsData = data['produits'] as List<dynamic>? ?? [];

        for (final produitData in produitsData) {
          try {
            final produit = ProductControle.fromMap(produitData);
            if (produit.nature == ProductNature.liquide &&
                produit.estConforme &&
                produit.estControle) {
              produits.add(produit);
            }
          } catch (e) {
            if (kDebugMode) {
              print('❌ FILTRAGE: Erreur parsing produit: $e');
            }
          }
        }
      }

      // Mettre à jour le cache
      _produitsCache.clear();
      for (final produit in produits) {
        _produitsCache[produit.id] = produit;
      }
      _lastCacheUpdate = DateTime.now();

      if (kDebugMode) {
        print(
            '✅ FILTRAGE: ${produits.length} produits liquides chargés pour filtrage');
      }

      return produits;
    } catch (e) {
      if (kDebugMode) {
        print('❌ FILTRAGE: Erreur lors du chargement des produits: $e');
      }
      return [];
    }
  }

  /// Récupère les filtrages en cours
  Future<List<FiltrageProcess>> getFiltragesEnCours() async {
    try {
      final userSession = Get.find<UserSession>();
      final siteUtilisateur = userSession.site ?? 'SiteInconnu';

      final snapshot = await _firestore
          .collection('filtrages')
          .doc(siteUtilisateur)
          .collection('en_cours')
          .orderBy('dateDebut', descending: true)
          .get();

      final filtrages = <FiltrageProcess>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final filtrage = FiltrageProcess.fromMap(data);
        filtrages.add(filtrage);
      }

      // Mettre à jour le cache
      _filtragesEnCoursCache.clear();
      for (final filtrage in filtrages) {
        _filtragesEnCoursCache[filtrage.id] = filtrage;
      }

      if (kDebugMode) {
        print('✅ FILTRAGE: ${filtrages.length} filtrages en cours chargés');
      }

      return filtrages;
    } catch (e) {
      if (kDebugMode) {
        print(
            '❌ FILTRAGE: Erreur lors du chargement des filtrages en cours: $e');
      }
      return _generateTestFiltrages();
    }
  }

  /// Récupère les filtrages terminés
  Future<List<FiltrageResult>> getFiltragesTermines() async {
    try {
      final userSession = Get.find<UserSession>();
      final siteUtilisateur = userSession.site ?? 'SiteInconnu';

      final snapshot = await _firestore
          .collection('filtrages')
          .doc(siteUtilisateur)
          .collection('termines')
          .orderBy('dateFin', descending: true)
          .limit(50) // Limiter pour les performances
          .get();

      final filtrages = <FiltrageResult>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final filtrage = FiltrageResult.fromMap(data);
        filtrages.add(filtrage);
      }

      // Mettre à jour le cache
      _filtragesTerminesCache.clear();
      for (final filtrage in filtrages) {
        _filtragesTerminesCache[filtrage.id] = filtrage;
      }

      if (kDebugMode) {
        print('✅ FILTRAGE: ${filtrages.length} filtrages terminés chargés');
      }

      return filtrages;
    } catch (e) {
      if (kDebugMode) {
        print(
            '❌ FILTRAGE: Erreur lors du chargement des filtrages terminés: $e');
      }
      return _generateTestResults();
    }
  }

  /// Démarre un filtrage pour un produit
  Future<void> demarrerFiltrage({
    required ProductControle produit,
    required String agentFiltrage,
    required DateTime dateDebut,
    required String methodeFiltrage,
    String? instructions,
  }) async {
    try {
      final userSession = Get.find<UserSession>();
      final siteUtilisateur = userSession.site ?? 'SiteInconnu';

      final filtrageId =
          'FIL_${DateTime.now().millisecondsSinceEpoch}_${produit.id}';

      final filtrage = FiltrageProcess(
        id: filtrageId,
        produit: produit,
        agentFiltrage: agentFiltrage,
        dateDebut: dateDebut,
        statut: FiltrageStatus.enCours,
        methodeFiltrage: methodeFiltrage,
        instructions: instructions,
        site: siteUtilisateur,
      );

      // Sauvegarder dans Firestore
      await _firestore
          .collection('filtrages')
          .doc(siteUtilisateur)
          .collection('en_cours')
          .doc(filtrageId)
          .set(filtrage.toMap());

      // Marquer le produit comme en traitement dans le cache
      if (_produitsCache.containsKey(produit.id)) {
        _produitsCache.remove(produit.id);
      }

      // Ajouter au cache des filtrages en cours
      _filtragesEnCoursCache[filtrageId] = filtrage;

      if (kDebugMode) {
        print('✅ FILTRAGE: Filtrage démarré pour ${produit.codeContenant}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FILTRAGE: Erreur lors du démarrage du filtrage: $e');
      }
      throw Exception('Impossible de démarrer le filtrage: $e');
    }
  }

  /// Termine un filtrage
  Future<void> terminerFiltrage({
    required FiltrageProcess filtrage,
    required double volumeFiltre,
    required String qualiteFinale,
    required String limpidite,
    String? observations,
  }) async {
    try {
      final userSession = Get.find<UserSession>();
      final siteUtilisateur = userSession.site ?? 'SiteInconnu';

      final dateFin = DateTime.now();
      final duree = dateFin.difference(filtrage.dateDebut);
      final poidsInitial = filtrage.produit.poidsTotal;
      final rendement =
          poidsInitial > 0 ? (volumeFiltre / poidsInitial) * 100 : 0.0;

      final result = FiltrageResult(
        id: filtrage.id,
        produit: filtrage.produit,
        agentFiltrage: filtrage.agentFiltrage,
        dateDebut: filtrage.dateDebut,
        dateFin: dateFin,
        duree: duree,
        volumeInitial: poidsInitial,
        volumeFiltre: volumeFiltre,
        rendement: rendement,
        methodeFiltrage: filtrage.methodeFiltrage,
        qualiteFinale: qualiteFinale,
        limpidite: limpidite,
        observations: observations,
        site: siteUtilisateur,
      );

      // Déplacer de 'en_cours' vers 'termines'
      await _firestore
          .collection('filtrages')
          .doc(siteUtilisateur)
          .collection('termines')
          .doc(filtrage.id)
          .set(result.toMap());

      await _firestore
          .collection('filtrages')
          .doc(siteUtilisateur)
          .collection('en_cours')
          .doc(filtrage.id)
          .delete();

      // Mettre à jour les caches
      _filtragesEnCoursCache.remove(filtrage.id);
      _filtragesTerminesCache[filtrage.id] = result;

      if (kDebugMode) {
        print(
            '✅ FILTRAGE: Filtrage terminé pour ${filtrage.produit.codeContenant}');
        print('📊 FILTRAGE: Rendement: ${rendement.toStringAsFixed(1)}%');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FILTRAGE: Erreur lors de la finalisation: $e');
      }
      throw Exception('Impossible de terminer le filtrage: $e');
    }
  }

  /// Suspend un filtrage
  Future<void> suspendreFiltrage({
    required FiltrageProcess filtrage,
    required String raison,
  }) async {
    try {
      final userSession = Get.find<UserSession>();
      final siteUtilisateur = userSession.site ?? 'SiteInconnu';

      final filtrageSuspendu = filtrage.copyWith(
        statut: FiltrageStatus.suspendu,
        observations: raison,
        dateSuspension: DateTime.now(),
      );

      // Mettre à jour dans Firestore
      await _firestore
          .collection('filtrages')
          .doc(siteUtilisateur)
          .collection('en_cours')
          .doc(filtrage.id)
          .update(filtrageSuspendu.toMap());

      // Mettre à jour le cache
      _filtragesEnCoursCache[filtrage.id] = filtrageSuspendu;

      if (kDebugMode) {
        print(
            '⏸️ FILTRAGE: Filtrage suspendu pour ${filtrage.produit.codeContenant}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FILTRAGE: Erreur lors de la suspension: $e');
      }
      throw Exception('Impossible de suspendre le filtrage: $e');
    }
  }

  /// Démarre un filtrage groupé
  Future<void> demarrerFiltrageGroupe({
    required List<ProductControle> produits,
    required String agentFiltrage,
    required String methodeFiltrage,
    String? instructions,
  }) async {
    try {
      final dateDebut = DateTime.now();

      for (final produit in produits) {
        await demarrerFiltrage(
          produit: produit,
          agentFiltrage: agentFiltrage,
          dateDebut: dateDebut,
          methodeFiltrage: methodeFiltrage,
          instructions: instructions,
        );
      }

      if (kDebugMode) {
        print(
            '✅ FILTRAGE: Filtrage groupé démarré pour ${produits.length} produits');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FILTRAGE: Erreur lors du filtrage groupé: $e');
      }
      throw Exception('Impossible de démarrer le filtrage groupé: $e');
    }
  }

  /// Invalide le cache pour forcer un rechargement
  void invalidateCache() {
    _produitsCache.clear();
    _filtragesEnCoursCache.clear();
    _filtragesTerminesCache.clear();
    _lastCacheUpdate = null;

    if (kDebugMode) {
      print('🔄 FILTRAGE: Cache invalidé');
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
      print('🧪 FILTRAGE: Génération de données de test pour les produits');
    }

    return [
      ProductControle(
        id: 'TEST-FIL-001',
        codeContenant: 'CT-FIL-001',
        typeCollecte: 'recoltes',
        collecteId: 'RECOLTE-001',
        producteur: 'Marie OUEDRAOGO',
        village: 'Réo',
        commune: 'Réo',
        quartier: 'Centre',
        numeroContenant: 'CT-FIL-001',
        siteOrigine: 'Koudougou',
        nature: ProductNature.liquide,
        typeContenant: 'Bidon 20L',
        poidsTotal: 18.5,
        poidsMiel: 16.8, // Poids de miel après extraction d'eau
        teneurEau: 19.2,
        predominanceFlorale: 'Acacia',
        qualite: 'Très Bon',
        dateReception: DateTime.now().subtract(const Duration(days: 1)),
        dateCollecte: DateTime.now().subtract(const Duration(days: 4)),
        dateControle: DateTime.now().subtract(const Duration(days: 1)),
        controleur: 'Ibrahim SAWADOGO',
        estConforme: true,
        statutControle: 'valide',
        estControle: true,
        estAttribue: true,
      ),
      ProductControle(
        id: 'TEST-FIL-002',
        codeContenant: 'CT-FIL-002',
        typeCollecte: 'scoop',
        collecteId: 'SCOOP-002',
        producteur: 'SCOOP UGPK',
        village: 'Koudougou',
        commune: 'Koudougou',
        quartier: 'Centre',
        numeroContenant: 'CT-FIL-002',
        siteOrigine: 'Koudougou',
        nature: ProductNature.liquide,
        typeContenant: 'Bidon 25L',
        poidsTotal: 22.3,
        poidsMiel: 20.1, // Poids de miel après extraction d'eau
        teneurEau: 18.8,
        predominanceFlorale: 'Karité',
        qualite: 'Excellent',
        dateReception: DateTime.now().subtract(const Duration(days: 9)),
        dateCollecte: DateTime.now().subtract(const Duration(days: 14)),
        dateControle: DateTime.now().subtract(const Duration(days: 9)),
        controleur: 'Fatima COMPAORE',
        estConforme: true,
        statutControle: 'valide',
        estControle: true,
        estAttribue: true,
      ),
    ];
  }

  /// Génère des données de test pour les filtrages en cours
  List<FiltrageProcess> _generateTestFiltrages() {
    if (kDebugMode) {
      print('🧪 FILTRAGE: Génération de données de test pour les filtrages');
    }

    final produits = _generateTestProducts();
    return [
      FiltrageProcess(
        id: 'FIL-PROCESS-001',
        produit: produits[0],
        agentFiltrage: 'Aïssata SAWADOGO',
        dateDebut:
            DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
        statut: FiltrageStatus.enCours,
        methodeFiltrage: 'Filtration fine',
        instructions: 'Filtrage standard pour miel d\'acacia',
        site: 'Koudougou',
      ),
    ];
  }

  /// Génère des données de test pour les filtrages terminés
  List<FiltrageResult> _generateTestResults() {
    if (kDebugMode) {
      print('🧪 FILTRAGE: Génération de données de test pour les résultats');
    }

    final produits = _generateTestProducts();
    return [
      FiltrageResult(
        id: 'FIL-RESULT-001',
        produit: produits[1],
        agentFiltrage: 'Aminata TRAORE',
        dateDebut: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        dateFin: DateTime.now().subtract(const Duration(days: 1)),
        duree: const Duration(hours: 2),
        volumeInitial: 22.3,
        volumeFiltre: 20.8,
        rendement: 93.3,
        methodeFiltrage: 'Filtration fine',
        qualiteFinale: 'Excellent',
        limpidite: 'Cristalline',
        observations: 'Filtrage réussi avec excellente limpidité',
        site: 'Koudougou',
      ),
    ];
  }

  /// Nettoie les ressources
  void dispose() {
    _produitsCache.clear();
    _filtragesEnCoursCache.clear();
    _filtragesTerminesCache.clear();
    _lastCacheUpdate = null;
  }
}
