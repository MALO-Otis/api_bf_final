import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart';
import '../../controle_de_donnes/services/firestore_attribution_service.dart';
import '../../../authentication/user_session.dart';
import '../models/extraction_models_improved.dart';
import 'package:get/get.dart';

/// 🟫 SERVICE D'EXTRACTION AMÉLIORÉ
///
/// Service complet pour la gestion des extractions intégré avec
/// le nouveau système d'attribution unifié
class ExtractionServiceImproved {
  static final ExtractionServiceImproved _instance =
      ExtractionServiceImproved._internal();
  factory ExtractionServiceImproved() => _instance;
  ExtractionServiceImproved._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreAttributionService _attributionService =
      FirestoreAttributionService();

  /// Cache pour optimiser les performances
  final Map<String, ProductControle> _produitsCache = {};
  final Map<String, ExtractionProcess> _extractionsEnCoursCache = {};
  final Map<String, ExtractionResult> _extractionsTermineesCache = {};

  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  /// Récupère tous les produits attribués pour extraction
  Future<List<ProductControle>> getProduitsAttribuesExtraction() async {
    try {
      if (_isCacheValid() && _produitsCache.isNotEmpty) {
        if (kDebugMode) {
          print(
              '✅ EXTRACTION: Utilisation du cache - ${_produitsCache.length} produits');
        }
        return _produitsCache.values.toList();
      }

      if (kDebugMode) {
        print('🔄 EXTRACTION: Rechargement depuis Firestore...');
      }

      final userSession = Get.find<UserSession>();
      final siteUtilisateur = userSession.site ?? 'SiteInconnu';

      // Récupérer les attributions pour extraction vers ce site
      final attributionsStream = _attributionService.getAttributionsPourSite(
        type: AttributionType.extraction,
        siteReceveur: siteUtilisateur,
      );

      final produits = <ProductControle>[];

      // Convertir le stream en future pour obtenir une liste unique
      final attributionsData = await attributionsStream.first;

      for (final attributionData in attributionsData) {
        // Convertir le Map en objet ControlAttribution
        final attribution = ControlAttribution.fromMap(attributionData);

        // Récupérer les détails de chaque contenant attribué
        for (final contenantId in attribution.listeContenants) {
          try {
            // Récupérer le produit depuis la collection controles_qualite
            final produitDoc = await _firestore
                .collection('controles_qualite')
                .doc(contenantId)
                .get();

            if (produitDoc.exists) {
              final data = produitDoc.data()!;
              final produit =
                  _convertQualityControlToProductControle(contenantId, data);

              if (produit.nature == ProductNature.brut) {
                produits.add(produit);
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Erreur récupération produit $contenantId: $e');
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
            '✅ EXTRACTION: ${produits.length} produits bruts chargés pour extraction');
      }

      return produits;
    } catch (e) {
      if (kDebugMode) {
        print('❌ EXTRACTION: Erreur lors du chargement des produits: $e');
      }

      // En cas d'erreur, générer des données de test
      return _generateTestProducts();
    }
  }

  /// Récupère les extractions en cours
  Future<List<ExtractionProcess>> getExtractionsEnCours() async {
    try {
      final userSession = Get.find<UserSession>();
      final siteUtilisateur = userSession.site ?? 'SiteInconnu';

      final snapshot = await _firestore
          .collection('extractions')
          .doc(siteUtilisateur)
          .collection('en_cours')
          .orderBy('dateDebut', descending: true)
          .get();

      final extractions = <ExtractionProcess>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final extraction = ExtractionProcess.fromMap(data);
        extractions.add(extraction);
      }

      // Mettre à jour le cache
      _extractionsEnCoursCache.clear();
      for (final extraction in extractions) {
        _extractionsEnCoursCache[extraction.id] = extraction;
      }

      if (kDebugMode) {
        print(
            '✅ EXTRACTION: ${extractions.length} extractions en cours chargées');
      }

      return extractions;
    } catch (e) {
      if (kDebugMode) {
        print(
            '❌ EXTRACTION: Erreur lors du chargement des extractions en cours: $e');
      }
      return _generateTestExtractions();
    }
  }

  /// Récupère les extractions terminées
  Future<List<ExtractionResult>> getExtractionsTerminees() async {
    try {
      final userSession = Get.find<UserSession>();
      final siteUtilisateur = userSession.site ?? 'SiteInconnu';

      final snapshot = await _firestore
          .collection('extractions')
          .doc(siteUtilisateur)
          .collection('terminees')
          .orderBy('dateFin', descending: true)
          .limit(50) // Limiter pour les performances
          .get();

      final extractions = <ExtractionResult>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final extraction = ExtractionResult.fromMap(data);
        extractions.add(extraction);
      }

      // Mettre à jour le cache
      _extractionsTermineesCache.clear();
      for (final extraction in extractions) {
        _extractionsTermineesCache[extraction.id] = extraction;
      }

      if (kDebugMode) {
        print(
            '✅ EXTRACTION: ${extractions.length} extractions terminées chargées');
      }

      return extractions;
    } catch (e) {
      if (kDebugMode) {
        print(
            '❌ EXTRACTION: Erreur lors du chargement des extractions terminées: $e');
      }
      return _generateTestResults();
    }
  }

  /// Démarre une extraction pour un produit
  Future<void> demarrerExtraction({
    required ProductControle produit,
    required String extracteur,
    required DateTime dateDebut,
    String? instructions,
  }) async {
    try {
      final userSession = Get.find<UserSession>();
      final siteUtilisateur = userSession.site ?? 'SiteInconnu';

      final extractionId =
          'EXT_${DateTime.now().millisecondsSinceEpoch}_${produit.id}';

      final extraction = ExtractionProcess(
        id: extractionId,
        produit: produit,
        extracteur: extracteur,
        dateDebut: dateDebut,
        statut: ExtractionStatus.enCours,
        instructions: instructions,
        site: siteUtilisateur,
      );

      // Sauvegarder dans Firestore
      await _firestore
          .collection('extractions')
          .doc(siteUtilisateur)
          .collection('en_cours')
          .doc(extractionId)
          .set(extraction.toMap());

      // Marquer le produit comme en traitement dans le cache
      if (_produitsCache.containsKey(produit.id)) {
        _produitsCache.remove(produit.id);
      }

      // Ajouter au cache des extractions en cours
      _extractionsEnCoursCache[extractionId] = extraction;

      if (kDebugMode) {
        print(
            '✅ EXTRACTION: Extraction démarrée pour ${produit.codeContenant}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ EXTRACTION: Erreur lors du démarrage de l\'extraction: $e');
      }
      throw Exception('Impossible de démarrer l\'extraction: $e');
    }
  }

  /// Termine une extraction
  Future<void> terminerExtraction({
    required ExtractionProcess extraction,
    required double poidsExtrait,
    required String qualite,
    String? observations,
  }) async {
    try {
      final userSession = Get.find<UserSession>();
      final siteUtilisateur = userSession.site ?? 'SiteInconnu';

      final dateFin = DateTime.now();
      final duree = dateFin.difference(extraction.dateDebut);
      final poidsInitial = extraction.produit.poidsTotal;
      final rendement =
          poidsInitial > 0 ? (poidsExtrait / poidsInitial) * 100 : 0.0;

      final result = ExtractionResult(
        id: extraction.id,
        produit: extraction.produit,
        extracteur: extraction.extracteur,
        dateDebut: extraction.dateDebut,
        dateFin: dateFin,
        duree: duree,
        poidsInitial: poidsInitial,
        poidsExtrait: poidsExtrait,
        rendement: rendement,
        qualite: qualite,
        observations: observations,
        site: siteUtilisateur,
      );

      // Déplacer de 'en_cours' vers 'terminees'
      await _firestore
          .collection('extractions')
          .doc(siteUtilisateur)
          .collection('terminees')
          .doc(extraction.id)
          .set(result.toMap());

      await _firestore
          .collection('extractions')
          .doc(siteUtilisateur)
          .collection('en_cours')
          .doc(extraction.id)
          .delete();

      // Mettre à jour les caches
      _extractionsEnCoursCache.remove(extraction.id);
      _extractionsTermineesCache[extraction.id] = result;

      if (kDebugMode) {
        print(
            '✅ EXTRACTION: Extraction terminée pour ${extraction.produit.codeContenant}');
        print('📊 EXTRACTION: Rendement: ${rendement.toStringAsFixed(1)}%');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ EXTRACTION: Erreur lors de la finalisation: $e');
      }
      throw Exception('Impossible de terminer l\'extraction: $e');
    }
  }

  /// Suspend une extraction
  Future<void> suspendreExtraction({
    required ExtractionProcess extraction,
    required String raison,
  }) async {
    try {
      final userSession = Get.find<UserSession>();
      final siteUtilisateur = userSession.site ?? 'SiteInconnu';

      final extractionSuspendue = extraction.copyWith(
        statut: ExtractionStatus.suspendu,
        observations: raison,
        dateSuspension: DateTime.now(),
      );

      // Mettre à jour dans Firestore
      await _firestore
          .collection('extractions')
          .doc(siteUtilisateur)
          .collection('en_cours')
          .doc(extraction.id)
          .update(extractionSuspendue.toMap());

      // Mettre à jour le cache
      _extractionsEnCoursCache[extraction.id] = extractionSuspendue;

      if (kDebugMode) {
        print(
            '⏸️ EXTRACTION: Extraction suspendue pour ${extraction.produit.codeContenant}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ EXTRACTION: Erreur lors de la suspension: $e');
      }
      throw Exception('Impossible de suspendre l\'extraction: $e');
    }
  }

  /// Démarre une extraction groupée
  Future<void> demarrerExtractionGroupee({
    required List<ProductControle> produits,
    required String extracteur,
    String? instructions,
  }) async {
    try {
      final dateDebut = DateTime.now();

      for (final produit in produits) {
        await demarrerExtraction(
          produit: produit,
          extracteur: extracteur,
          dateDebut: dateDebut,
          instructions: instructions,
        );
      }

      if (kDebugMode) {
        print(
            '✅ EXTRACTION: Extraction groupée démarrée pour ${produits.length} produits');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ EXTRACTION: Erreur lors de l\'extraction groupée: $e');
      }
      throw Exception('Impossible de démarrer l\'extraction groupée: $e');
    }
  }

  /// Invalide le cache pour forcer un rechargement
  void invalidateCache() {
    _produitsCache.clear();
    _extractionsEnCoursCache.clear();
    _extractionsTermineesCache.clear();
    _lastCacheUpdate = null;

    if (kDebugMode) {
      print('🔄 EXTRACTION: Cache invalidé');
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
      print('🧪 EXTRACTION: Génération de données de test pour les produits');
    }

    return [
      ProductControle(
        id: 'TEST-EXT-001',
        codeContenant: 'CT-EXT-001',
        typeCollecte: 'recoltes',
        collecteId: 'RECOLTE-001',
        producteur: 'Jean OUEDRAOGO',
        village: 'Sakoinsé',
        commune: 'Koudougou',
        quartier: 'Secteur 1',
        siteOrigine: 'Koudougou',
        nature: ProductNature.brut,
        typeContenant: 'Bidon 25L',
        numeroContenant: 'CT-001',
        poidsTotal: 24.5,
        poidsMiel: 24.5,
        teneurEau: 18.2,
        predominanceFlorale: 'Karité',
        qualite: 'Excellent',
        dateReception: DateTime.now().subtract(const Duration(days: 2)),
        dateCollecte: DateTime.now().subtract(const Duration(days: 5)),
        dateControle: DateTime.now().subtract(const Duration(days: 1)),
        controleur: 'Marie KONE',
        estConforme: true,
        statutControle: 'valide',
        estControle: true,
        estAttribue: true,
      ),
      ProductControle(
        id: 'TEST-EXT-002',
        codeContenant: 'CT-EXT-002',
        typeCollecte: 'scoop',
        collecteId: 'SCOOP-001',
        producteur: 'SCOOP COAPIK',
        village: 'Koudougou',
        commune: 'Koudougou',
        quartier: 'Centre',
        siteOrigine: 'Koudougou',
        nature: ProductNature.brut,
        typeContenant: 'Bidon 30L',
        numeroContenant: 'CT-002',
        poidsTotal: 28.8,
        poidsMiel: 28.8,
        teneurEau: 17.8,
        predominanceFlorale: 'Néré',
        qualite: 'Très Bon',
        dateReception: DateTime.now().subtract(const Duration(days: 8)),
        dateCollecte: DateTime.now().subtract(const Duration(days: 12)),
        dateControle: DateTime.now().subtract(const Duration(days: 7)),
        controleur: 'Ibrahim SAWADOGO',
        estConforme: true,
        statutControle: 'valide',
        estControle: true,
        estAttribue: true,
      ),
    ];
  }

  /// Génère des données de test pour les extractions en cours
  List<ExtractionProcess> _generateTestExtractions() {
    if (kDebugMode) {
      print(
          '🧪 EXTRACTION: Génération de données de test pour les extractions');
    }

    final produits = _generateTestProducts();
    return [
      ExtractionProcess(
        id: 'EXT-PROCESS-001',
        produit: produits[0],
        extracteur: 'Amadou TRAORE',
        dateDebut: DateTime.now().subtract(const Duration(hours: 2)),
        statut: ExtractionStatus.enCours,
        instructions: 'Extraction standard pour miel de karité',
        site: 'Koudougou',
      ),
    ];
  }

  /// Génère des données de test pour les extractions terminées
  List<ExtractionResult> _generateTestResults() {
    if (kDebugMode) {
      print('🧪 EXTRACTION: Génération de données de test pour les résultats');
    }

    final produits = _generateTestProducts();
    return [
      ExtractionResult(
        id: 'EXT-RESULT-001',
        produit: produits[1],
        extracteur: 'Fatima COMPAORE',
        dateDebut: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        dateFin: DateTime.now().subtract(const Duration(days: 1)),
        duree: const Duration(hours: 3),
        poidsInitial: 28.8,
        poidsExtrait: 25.2,
        rendement: 87.5,
        qualite: 'Excellent',
        observations: 'Extraction réussie avec excellent rendement',
        site: 'Koudougou',
      ),
    ];
  }

  /// Nettoie les ressources
  void dispose() {
    _produitsCache.clear();
    _extractionsEnCoursCache.clear();
    _extractionsTermineesCache.clear();
    _lastCacheUpdate = null;
  }

  /// 🔄 CONVERSION DEPUIS CONTRÔLE QUALITÉ
  ///
  /// Convertit un document de contrôle qualité en ProductControle
  ProductControle _convertQualityControlToProductControle(
      String docId, Map<String, dynamic> data) {
    return ProductControle(
      id: docId,
      codeContenant: data['containerCode'] ?? '',
      dateReception: _parseDateTime(data['receptionDate']),
      producteur: data['producer'] ?? '',
      village: data['apiaryVillage'] ?? '',
      commune: data['commune'] ?? '',
      quartier: data['quartier'] ?? '',
      nature: _convertHoneyNatureToProductNature(data['honeyNature']),
      typeContenant: data['containerType'] ?? '',
      numeroContenant: data['containerNumber'] ?? '',
      poidsTotal: (data['totalWeight'] as num?)?.toDouble() ?? 0.0,
      poidsMiel: (data['honeyWeight'] as num?)?.toDouble() ?? 0.0,
      qualite: data['quality'] ?? '',
      teneurEau: (data['waterContent'] as num?)?.toDouble(),
      predominanceFlorale: data['floralPredominance'] ?? '',
      estConforme: data['conformityStatus'] == 'conforme',
      causeNonConformite: data['nonConformityCause'],
      observations: data['observations'],
      dateControle: _parseDateTime(data['createdAt']),
      controleur: data['controllerName'],
      estAttribue: data['estAttribue'] ?? false,
      attributionId: data['attributionId'],
      typeAttribution: data['typeAttribution'],
      dateAttribution: data['dateAttribution'] != null
          ? _parseDateTime(data['dateAttribution'])
          : null,
      siteOrigine: data['siteOrigine'] ?? 'Site Inconnu',
      collecteId: data['collecteId'] ?? '',
      typeCollecte: data['typeCollecte'] ?? 'Récolte',
      dateCollecte: _parseDateTime(data['dateCollecte'] ?? data['createdAt']),
      estControle: true,
      statutControle: 'valide',
      metadata: data['metadata'],
    );
  }

  /// 🔄 CONVERSION NATURE MIEL
  ///
  /// Convertit HoneyNature vers ProductNature
  ProductNature _convertHoneyNatureToProductNature(String? honeyNature) {
    switch (honeyNature?.toLowerCase()) {
      case 'brut':
        return ProductNature.brut;
      case 'prefilitre':
        return ProductNature.liquide;
      default:
        return ProductNature.brut; // Par défaut
    }
  }

  /// 📅 ANALYSE DES DATES
  ///
  /// Parse les dates depuis différents formats Firestore
  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Erreur parsing date: $value');
        }
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}
