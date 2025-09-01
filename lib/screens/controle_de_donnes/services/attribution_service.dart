// Service pour gérer les attributions intelligentes de produits
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/attribution_models_v2.dart';
import '../models/quality_control_models.dart';
import '../models/collecte_models.dart';
import '../services/quality_control_service.dart';
import '../services/firestore_data_service.dart';

/// Service pour la gestion des attributions de produits
class AttributionService {
  static final AttributionService _instance = AttributionService._internal();
  factory AttributionService() => _instance;
  AttributionService._internal();

  // Stockage en mémoire pour la démonstration
  final Map<String, ProductControle> _produits = {};
  final Map<String, AttributionProduits> _attributions = {};
  final QualityControlService _qualityService = QualityControlService();

  /// Initialise le service avec les vraies données depuis Firestore
  Future<void> initialiserDonnees() async {
    await _chargerProduitsOptimise();
  }

  /// 🚀 NOUVELLE MÉTHODE OPTIMISÉE - Charge uniquement les contrôles qualité
  Future<void> _chargerProduitsOptimise() async {
    try {
      print('');
      print('🚀🚀🚀 ATTRIBUTION OPTIMISÉ: DÉBUT DU CHARGEMENT 🚀🚀🚀');
      print('🚀🚀🚀 ATTRIBUTION OPTIMISÉ: DÉBUT DU CHARGEMENT 🚀🚀🚀');
      print('');

      final stopwatch = Stopwatch()..start();

      // 1. Charger UNIQUEMENT les contrôles qualité depuis Firestore
      final qualityService = QualityControlService();
      final allControls =
          await qualityService.getAllQualityControlsFromFirestore();

      print(
          '⚡ ATTRIBUTION: ${allControls.length} contrôles qualité chargés en ${stopwatch.elapsedMilliseconds}ms');

      // 2. Vider les produits existants
      _produits.clear();

      // 3. Créer directement les produits depuis les contrôles qualité
      for (int i = 0; i < allControls.length; i++) {
        final control = allControls[i];

        final produit = ProductControle(
          id: 'PROD_${(i + 1).toString().padLeft(4, '0')}',
          codeContenant: control.containerCode,
          typeCollecte:
              _determinerTypeCollecteDepuisCode(control.containerCode),
          collecteId: 'COLLECTE_${control.containerCode}',
          producteur: control.producer,
          village: control.apiaryVillage,
          nature: control.honeyNature == HoneyNature.brut
              ? ProductNature.brut
              : ProductNature.filtre,
          typeContenant: control.containerType,
          poids: control.honeyWeight,
          teneurEau: control.waterContent,
          predominanceFlorale: control.floralPredominance ?? 'Non spécifiée',
          qualite: control.quality,
          dateReception: control.receptionDate,
          dateCollecte: control.collectionStartDate ?? control.receptionDate,
          collecteur: control.controllerName ?? 'Contrôleur inconnu',
          siteOrigine: _determinerSiteOrigine(control.apiaryVillage),
          estConforme: control.conformityStatus == ConformityStatus.conforme,
          causeNonConformite: control.nonConformityCause,
          observations: control.observations,
          estAttribue: false,
          attributionId: null,
        );

        _produits[produit.id] = produit;
      }

      stopwatch.stop();

      print('');
      print('🎯🎯🎯 ATTRIBUTION OPTIMISÉ: RÉSUMÉ FINAL 🎯🎯🎯');
      print('⚡ Temps total de chargement: ${stopwatch.elapsedMilliseconds}ms');
      print('✅ Produits contrôlés disponibles: ${_produits.length}');
      print('');

      if (_produits.isEmpty) {
        print('❌ ATTRIBUTION: AUCUN PRODUIT CONTRÔLÉ TROUVÉ !');
        print(
            '❌ Pour voir des produits ici, vous devez d\'abord effectuer des contrôles qualité');
      } else {
        print(
            '✅ ATTRIBUTION: ${_produits.length} produits prêts pour attribution !');

        // Statistiques par type
        final recoltes =
            _produits.values.where((p) => p.typeCollecte == 'recoltes').length;
        final scoop =
            _produits.values.where((p) => p.typeCollecte == 'scoop').length;
        final individuel = _produits.values
            .where((p) => p.typeCollecte == 'individuel')
            .length;
        final miellerie =
            _produits.values.where((p) => p.typeCollecte == 'miellerie').length;

        print('📊 Répartition:');
        if (recoltes > 0) print('   - Récoltes: $recoltes');
        if (scoop > 0) print('   - SCOOP: $scoop');
        if (individuel > 0) print('   - Individuel: $individuel');
        if (miellerie > 0) print('   - Miellerie: $miellerie');
      }
      print('🎯🎯🎯 FIN DU RÉSUMÉ OPTIMISÉ 🎯🎯🎯');
      print('');
    } catch (e) {
      print('❌ ATTRIBUTION OPTIMISÉ: Erreur lors du chargement: $e');
      _produits.clear();
    }
  }

  /// Détermine le type de collecte depuis le code du contenant
  String _determinerTypeCollecteDepuisCode(String containerCode) {
    if (containerCode.contains('_recolte')) return 'recoltes';
    if (containerCode.contains('_scoop')) return 'scoop';
    if (containerCode.contains('_individuel')) return 'individuel';
    if (containerCode.contains('_miellerie')) return 'miellerie';

    // Fallback - essayer de deviner depuis le préfixe
    if (containerCode.startsWith('REF')) return 'recoltes';
    if (containerCode.startsWith('SCO')) return 'scoop';
    if (containerCode.startsWith('IND')) return 'individuel';
    if (containerCode.startsWith('MIE')) return 'miellerie';

    return 'recoltes'; // Par défaut
  }

  /// 🆕 Charge les produits depuis Firestore (ANCIENNE MÉTHODE - NON OPTIMISÉE)
  Future<void> _chargerProduitsDepuisFirestore() async {
    try {
      print('');
      print('🚀🚀🚀 ATTRIBUTION SERVICE: DÉBUT DU CHARGEMENT 🚀🚀🚀');
      print('🚀🚀🚀 ATTRIBUTION SERVICE: DÉBUT DU CHARGEMENT 🚀🚀🚀');
      print('🚀🚀🚀 ATTRIBUTION SERVICE: DÉBUT DU CHARGEMENT 🚀🚀🚀');
      print('');

      if (kDebugMode) {
        print('🔄 ATTRIBUTION: Chargement des données depuis Firestore...');
      }

      // 1. Récupérer toutes les collectes depuis Firestore
      final allCollectes =
          await FirestoreDataService.getCollectesFromFirestore();

      if (kDebugMode) {
        print('📊 ATTRIBUTION: Collectes chargées:');
        for (final section in allCollectes.keys) {
          final collectes = allCollectes[section] ?? [];
          print('   - ${section.name}: ${collectes.length} collectes');
        }
      }

      // 2. Récupérer les contrôles qualité depuis le service
      final qualityService = QualityControlService();

      // 🧹 FORCER LE RECHARGEMENT DES DONNÉES DEPUIS FIRESTORE
      print(
          '🧹 ATTRIBUTION: Nettoyage du cache et rechargement depuis Firestore...');
      await qualityService.refreshAllData();

      if (kDebugMode) {
        final allControls = qualityService.getAllQualityControls();
        print(
            '🔬 ATTRIBUTION: ${allControls.length} contrôles qualité disponibles (après rechargement)');

        // Lister les premiers contrôles pour diagnostic
        if (allControls.isNotEmpty) {
          print('📋 ATTRIBUTION: Exemples de contrôles disponibles:');
          for (int i = 0; i < allControls.length.clamp(0, 5); i++) {
            final control = allControls[i];
            print('   - ${control.containerCode} (${control.receptionDate})');
          }
        } else {
          print(
              '⚠️ ATTRIBUTION: Aucun contrôle qualité trouvé dans le service !');
        }
      }

      // 3. Convertir chaque collecte en produits contrôlés
      int produitIndex = 1;
      int totalContenants = 0;
      int contenantsAvecControle = 0;
      _produits.clear();

      for (final section in allCollectes.keys) {
        final collectes = allCollectes[section] ?? [];

        for (final collecte in collectes) {
          // Pour chaque contenant de la collecte
          final contenants = _getContenantsFromCollecte(collecte);

          if (kDebugMode) {
            print(
                '📦 ATTRIBUTION: Collecte ${collecte.id} (${section.name}) - ${contenants.length} contenants');
          }

          for (int i = 0; i < contenants.length; i++) {
            final contenant = contenants[i];
            totalContenants++;

            // Vérifier s'il y a un contrôle qualité pour ce contenant
            final originalContainerCode = contenant['id']?.toString() ??
                'C${(i + 1).toString().padLeft(3, '0')}';

            // ✅ CORRECTION: Extraire le code de base pour correspondre aux contrôles qualité
            String containerCode = originalContainerCode;

            // Si le code contient un suffixe de type (_recolte, _scoop, etc.), on l'enlève
            if (containerCode.contains('_')) {
              final parts = containerCode.split('_');
              if (parts.isNotEmpty) {
                containerCode =
                    parts[0]; // Garder seulement la première partie (ex: C001)
              }
            }

            if (kDebugMode) {
              print(
                  '🔍 ATTRIBUTION: Vérification du contenant pour collecte ${collecte.id}...');
              print('   📝 Code original: $originalContainerCode');
              print('   🎯 Code pour recherche: $containerCode');
              if (originalContainerCode != containerCode) {
                print(
                    '   🔧 TRANSFORMATION APPLIQUÉE: $originalContainerCode → $containerCode');
              } else {
                print('   ✅ CODE INCHANGÉ: $containerCode');
              }
            }

            final controlInfo =
                qualityService.getContainerControlInfoFromCollecteData(
                    collecte, containerCode);

            // 📊 RÉCUPÉRER LES CONTRÔLES QUALITÉ DEPUIS FIRESTORE
            final controleQualite = await qualityService.getQualityControl(
                containerCode, collecte.date);

            if (kDebugMode) {
              if (controleQualite != null) {
                print(
                    '✅ ATTRIBUTION: Contenant $containerCode CONTRÔLÉ - Statut: ${controleQualite.conformityStatus}, Nature: ${controleQualite.honeyNature}');
                contenantsAvecControle++;
              } else {
                print(
                    '❌ ATTRIBUTION: Contenant $containerCode NON CONTRÔLÉ - Recherche avec code: $containerCode, date: ${collecte.date}');
              }
            }

            // ✅ NOUVEAU FILTRE: Ne prendre que les produits contrôlés
            if (controleQualite == null) {
              if (kDebugMode) {
                print(
                    '⏭️ ATTRIBUTION: Contenant $containerCode ignoré - pas de contrôle qualité');
              }
              continue; // Ignorer ce contenant s'il n'est pas contrôlé
            }

            // Créer le produit contrôlé
            final produit = _createProductFromCollecte(
              collecte: collecte,
              contenant: contenant,
              containerCode: containerCode,
              index: i,
              produitIndex: produitIndex++,
              section: section,
              controleQualite: controleQualite,
              controlInfo: controlInfo,
            );

            _produits[produit.id] = produit;

            if (kDebugMode) {
              print(
                  '🎯 ATTRIBUTION: Produit ${produit.id} créé - ${produit.producteur} (${produit.typeCollecte})');
            }
          }
        }
      }

      print('');
      print('🎯🎯🎯 ATTRIBUTION: RÉSUMÉ FINAL DU CHARGEMENT 🎯🎯🎯');
      print('🎯🎯🎯 ATTRIBUTION: RÉSUMÉ FINAL DU CHARGEMENT 🎯🎯🎯');
      print('   - Total contenants traités: $totalContenants');
      print('   - Contenants avec contrôle: $contenantsAvecControle');
      print('   - Produits créés pour attribution: ${_produits.length}');
      print('');
      if (_produits.isEmpty) {
        print('❌ ATTRIBUTION: AUCUN PRODUIT CONTRÔLÉ TROUVÉ !');
        print('❌ Pour voir des produits ici, vous devez d\'abord :');
        print('❌ 1. Aller dans le module de contrôle');
        print('❌ 2. Effectuer des contrôles qualité sur vos contenants');
        print('❌ 3. Revenir dans l\'attribution');
      } else {
        print(
            '✅ ATTRIBUTION: ${_produits.length} produits contrôlés prêts pour attribution !');
        print('📊 Répartition par section:');
        for (final section in allCollectes.keys) {
          final count = _produits.values
              .where((p) => p.typeCollecte == section.name)
              .length;
          if (count > 0) {
            print('   ${section.name}: $count produits');
          }
        }
      }
      print('🎯🎯🎯 FIN DU RÉSUMÉ 🎯🎯🎯');
      print('');
    } catch (e) {
      if (kDebugMode) {
        print('❌ ATTRIBUTION: Erreur lors du chargement depuis Firestore: $e');
      }
      // Fallback supprimé - ne plus utiliser de données de test
      if (kDebugMode) {
        print(
            '❌ ATTRIBUTION: Impossible de charger les données depuis Firestore');
      }
    }
  }

  /// MÉTHODE DÉSACTIVÉE : _genererProduitsTest()
  /// Cette méthode générait des produits de test comme fallback
  /// Elle a été désactivée pour éviter la pollution de la base avec des données de test
  /*
  Future<void> _genererProduitsTest() async {
    if (kDebugMode) {
      print('⚠️ ATTRIBUTION: Utilisation des données de test (fallback)');
    }

    // S'assurer que le service qualité a des données
    _qualityService.generateTestData();

    // Récupérer les contrôles qualité
    final controles = _qualityService.getQualityControlsByDateRange(
      DateTime.now().subtract(const Duration(days: 30)),
      DateTime.now(),
    );

    // Convertir en produits contrôlés
    for (int i = 0; i < controles.length; i++) {
      final controle = controles[i];
      final produit = ProductControle(
        id: 'PROD_${i + 1}',
        codeContenant: controle.containerCode,
        typeCollecte: _determinerTypeCollecte(controle.containerCode),
        collecteId:
            'COLLECTE_${controle.containerCode.substring(0, 3)}_${i ~/ 3 + 1}',
        producteur: controle.producer,
        village: controle.apiaryVillage,
        nature: AttributionUtils.determinerNature(
            controle.honeyNature == HoneyNature.brut ? 'Brut' : 'Filtré'),
        typeContenant: controle.containerType,
        poids: controle.honeyWeight,
        teneurEau: controle.waterContent,
        predominanceFlorale: controle.floralPredominance,
        qualite: controle.quality,
        dateReception: controle.receptionDate,
        dateCollecte: controle.collectionStartDate ??
            controle.receptionDate.subtract(Duration(days: 7)),
        collecteur: controle.controllerName ?? 'Collecteur inconnu',
        siteOrigine: _determinerSiteOrigine(controle.apiaryVillage),
        estConforme: controle.conformityStatus == ConformityStatus.conforme,
        causeNonConformite: controle.nonConformityCause,
        observations: controle.observations,
      );

      _produits[produit.id] = produit;
    }

    // Ajouter quelques produits cire supplémentaires
    _ajouterProduitsCireTest();

    if (kDebugMode) {
      print('✅ ${_produits.length} produits contrôlés générés');
    }
  }
  */

  /// 🆕 Récupère les contenants d'une collecte selon son type
  List<Map<String, dynamic>> _getContenantsFromCollecte(BaseCollecte collecte) {
    if (collecte is Recolte) {
      return collecte.contenants
          .map((c) => {
                'id': c.id,
                'typeRuche': c.hiveType,
                'typeContenant': c.containerType,
                'poids': c.weight,
                'prixUnitaire': c.unitPrice,
                'montantTotal': c.total,
              })
          .toList();
    } else if (collecte is Scoop) {
      return collecte.contenants
          .map((c) => {
                'id': c.id,
                'typeContenant': c.typeContenant,
                'typeMiel': c.typeMiel,
                'quantite': c.quantite,
                'prixUnitaire': c.prixUnitaire,
                'montantTotal': c.montantTotal,
                'predominanceFlorale': c.predominanceFlorale,
              })
          .toList();
    } else if (collecte is Individuel) {
      return collecte.contenants
          .map((c) => {
                'id': c.id,
                'typeContenant': c.typeContenant,
                'typeMiel': c.typeMiel,
                'quantite': c.quantite,
                'prixUnitaire': c.prixUnitaire,
                'montantTotal': c.montantTotal,
                'predominanceFlorale':
                    'Non spécifiée', // Champ non disponible pour individuels
              })
          .toList();
    } else if (collecte is Miellerie) {
      return collecte.contenants
          .map((c) => {
                'id': c.id,
                'typeContenant': c.typeContenant,
                'typeMiel': c.typeMiel,
                'quantite': c.quantite,
                'prixUnitaire': c.prixUnitaire,
                'montantTotal': c.montantTotal,
                'observations': c.observations,
              })
          .toList();
    }
    return [];
  }

  /// 🆕 Crée un ProductControle à partir d'une collecte et d'un contenant
  ProductControle _createProductFromCollecte({
    required BaseCollecte collecte,
    required Map<String, dynamic> contenant,
    required String containerCode,
    required int index,
    required int produitIndex,
    required Section section,
    QualityControlData? controleQualite,
    ContainerControlInfo? controlInfo,
  }) {
    // Déterminer la nature du produit selon le type de collecte
    ProductNature nature = ProductNature.brut;
    if (section == Section.scoop) {
      nature = ProductNature.filtre; // Les SCOOP sont souvent filtrés
    }

    // Utiliser les données du contrôle qualité si disponible
    if (controleQualite != null) {
      nature = controleQualite.honeyNature == HoneyNature.brut
          ? ProductNature.brut
          : ProductNature.filtre;
    }

    return ProductControle(
      id: 'PROD_${produitIndex.toString().padLeft(4, '0')}',
      codeContenant: containerCode,
      typeCollecte: section.name,
      collecteId: collecte.id,
      producteur: _extractProducteurFromCollecte(collecte),
      village: _extractVillageFromCollecte(collecte),
      nature: nature,
      typeContenant: contenant['typeContenant']?.toString() ?? 'Inconnu',
      poids: _extractPoidsFromContenant(contenant),
      teneurEau: controleQualite?.waterContent,
      predominanceFlorale: contenant['predominanceFlorale']?.toString() ??
          controleQualite?.floralPredominance ??
          'Non spécifiée',
      qualite: controleQualite?.quality ?? 'Non contrôlée',
      dateReception: collecte.date,
      dateCollecte: collecte.date,
      collecteur: collecte.technicien ?? 'Collecteur inconnu',
      siteOrigine: collecte.site,
      estConforme: controlInfo?.isControlled == true
          ? (controlInfo?.conformityStatus == 'conforme')
          : true, // Par défaut conforme si pas encore contrôlé
      causeNonConformite: controleQualite?.nonConformityCause,
      observations: controleQualite?.observations,
      estAttribue: false, // Sera mis à jour lors des attributions
      attributionId: null,
    );
  }

  /// 🆕 Extrait le village d'une collecte selon son type
  String _extractVillageFromCollecte(BaseCollecte collecte) {
    if (collecte is Recolte) {
      return collecte.village ?? collecte.site;
    } else if (collecte is Scoop) {
      return collecte.village ?? collecte.site;
    } else if (collecte is Individuel) {
      return collecte.village ?? collecte.site;
    } else if (collecte is Miellerie) {
      return collecte.localite;
    }
    return collecte.site;
  }

  /// 🆕 Extrait le producteur d'une collecte selon son type
  String _extractProducteurFromCollecte(BaseCollecte collecte) {
    if (collecte is Recolte) {
      return collecte.technicien ?? 'Producteur inconnu';
    } else if (collecte is Scoop) {
      return collecte.scoopNom;
    } else if (collecte is Individuel) {
      return collecte.nomProducteur;
    } else if (collecte is Miellerie) {
      return collecte.miellerieNom;
    }
    return collecte.technicien ?? 'Producteur inconnu';
  }

  /// 🆕 Extrait le poids d'un contenant selon son type
  double _extractPoidsFromContenant(Map<String, dynamic> contenant) {
    // Essayer différents champs selon le type de collecte
    if (contenant['poids'] != null) {
      return (contenant['poids'] as num).toDouble();
    } else if (contenant['quantite'] != null) {
      return (contenant['quantite'] as num).toDouble();
    } else if (contenant['weight'] != null) {
      return (contenant['weight'] as num).toDouble();
    }
    return 0.0; // Par défaut
  }

  /// 🆕 Obtient l'état de contrôle d'une collecte
  Future<Map<String, dynamic>> getCollecteControlStatus(
      BaseCollecte collecte) async {
    final contenants = _getContenantsFromCollecte(collecte);
    int totalContenants = contenants.length;
    int contenantsControles = 0;
    int contenantsConformes = 0;
    int contenantsNonConformes = 0;

    for (int i = 0; i < contenants.length; i++) {
      final contenant = contenants[i];
      final containerCode = contenant['id']?.toString() ??
          'C${(i + 1).toString().padLeft(3, '0')}_${collecte.runtimeType.toString().toLowerCase()}';

      final controleQualite =
          await _qualityService.getQualityControl(containerCode, collecte.date);

      if (controleQualite != null) {
        contenantsControles++;
        if (controleQualite.conformityStatus == ConformityStatus.conforme) {
          contenantsConformes++;
        } else {
          contenantsNonConformes++;
        }
      }
    }

    return {
      'totalContenants': totalContenants,
      'contenantsControles': contenantsControles,
      'contenantsNonControles': totalContenants - contenantsControles,
      'contenantsConformes': contenantsConformes,
      'contenantsNonConformes': contenantsNonConformes,
      'estTotalementControle': contenantsControles == totalContenants,
      'pourcentageControle': totalContenants > 0
          ? (contenantsControles / totalContenants * 100).round()
          : 0,
    };
  }

  /// Détermine le type de collecte basé sur le code contenant
  String _determinerTypeCollecte(String codeContenant) {
    final prefix = codeContenant.substring(0, 3).toUpperCase();
    switch (prefix) {
      case 'REF':
        return 'recolte';
      case 'IND':
        return 'individuel';
      case 'SCO':
        return 'scoop';
      case 'MIE':
        return 'miellerie';
      default:
        return 'individuel';
    }
  }

  /// Détermine le site d'origine basé sur le village
  String _determinerSiteOrigine(String village) {
    final villageMap = {
      'saaba': 'Koudougou',
      'réo': 'Koudougou',
      'reo': 'Koudougou',
      'bobo': 'Bobo-Dioulasso',
      'sindou': 'Sindou',
      'bagré': 'Bagré',
      'bagre': 'Bagré',
      'koudougou': 'Koudougou',
      'pô': 'Pô',
      'po': 'Pô',
      'mangodara': 'Mangodara',
    };

    final key = village.toLowerCase();
    return villageMap[key] ?? 'Koudougou';
  }

  /// MÉTHODE DÉSACTIVÉE : _ajouterProduitsCireTest()
  /// Cette méthode ajoutait des produits cire fictifs pour les tests
  /// Elle a été désactivée pour éviter la pollution de la base avec des données de test
  /*
  void _ajouterProduitsCireTest() {
    final produitsCire = [
      ProductControle(
        id: 'PROD_CIRE_1',
        codeContenant: 'CIR001',
        typeCollecte: 'recolte',
        collecteId: 'COLLECTE_CIR_1',
        producteur: 'SCOOP Orodara',
        village: 'Orodara',
        nature: ProductNature.cire,
        typeContenant: 'Sac plastique',
        poids: 3.5,
        teneurEau: null,
        predominanceFlorale: 'Karité',
        qualite: 'Excellente',
        dateReception: DateTime.now().subtract(Duration(days: 3)),
        dateCollecte: DateTime.now().subtract(Duration(days: 10)),
        collecteur: 'Moussa TRAORE',
        siteOrigine: 'Orodara',
        estConforme: true,
      ),
      ProductControle(
        id: 'PROD_CIRE_2',
        codeContenant: 'CIR002',
        typeCollecte: 'scoop',
        collecteId: 'COLLECTE_CIR_2',
        producteur: 'Coopérative Léo',
        village: 'Léo',
        nature: ProductNature.cire,
        typeContenant: 'Boîte métallique',
        poids: 2.8,
        teneurEau: null,
        predominanceFlorale: 'Acacia',
        qualite: 'Bonne',
        dateReception: DateTime.now().subtract(Duration(days: 6)),
        dateCollecte: DateTime.now().subtract(Duration(days: 12)),
        collecteur: 'Fatima KONE',
        siteOrigine: 'Léo',
        estConforme: true,
        observations: 'Cire de première qualité',
      ),
    ];

    for (final produit in produitsCire) {
      _produits[produit.id] = produit;
    }
  }
  */

  /// Récupère tous les produits contrôlés
  List<ProductControle> getTousLesProduits() {
    return _produits.values.toList()
      ..sort((a, b) => b.dateReception.compareTo(a.dateReception));
  }

  /// Récupère un produit par son ID
  Future<ProductControle?> getProduit(String id) async {
    return _produits[id];
  }

  /// Récupère les produits filtrés par type d'attribution
  List<ProductControle> getProduitsParType(AttributionType type) {
    final produits = getTousLesProduits();
    return AttributionUtils.filtrerProduitsParType(produits, type);
  }

  /// Regroupe les produits par collecte
  List<CollecteGroup> regrouperParCollecte(List<ProductControle> produits) {
    final groupes = <String, List<ProductControle>>{};

    for (final produit in produits) {
      groupes.putIfAbsent(produit.collecteId, () => []).add(produit);
    }

    return groupes.entries.map((entry) {
      final collecteId = entry.key;
      final produitsCollecte = entry.value;
      final premier = produitsCollecte.first;

      return CollecteGroup(
        collecteId: collecteId,
        typeCollecte: premier.typeCollecte,
        producteur: premier.producteur,
        dateCollecte: premier.dateCollecte,
        collecteur: premier.collecteur,
        siteOrigine: premier.siteOrigine,
        produits: produitsCollecte,
      );
    }).toList()
      ..sort((a, b) => b.dateCollecte.compareTo(a.dateCollecte));
  }

  /// Crée une nouvelle attribution
  Future<String> creerAttribution({
    required AttributionType type,
    required SiteAttribution siteDestination,
    required List<String> produitsIds,
    required String attributeurId,
    required String attributeurNom,
    String? instructions,
    String? observations,
  }) async {
    try {
      // Vérifier que tous les produits existent et peuvent être attribués
      final produitsValides = <ProductControle>[];
      for (final id in produitsIds) {
        final produit = _produits[id];
        if (produit == null) {
          throw Exception('Produit $id introuvable');
        }
        if (!AttributionUtils.peutEtreAttribue(produit, type)) {
          throw Exception(
              'Le produit ${produit.codeContenant} ne peut pas être attribué pour ${type.label}');
        }
        produitsValides.add(produit);
      }

      // Générer un ID unique pour l'attribution
      final attributionId = 'ATTR_${DateTime.now().millisecondsSinceEpoch}';

      // Créer l'attribution
      final attribution = AttributionProduits(
        id: attributionId,
        type: type,
        siteDestination: siteDestination,
        produitsIds: produitsIds,
        dateAttribution: DateTime.now(),
        attributeurId: attributeurId,
        attributeurNom: attributeurNom,
        instructions: instructions,
        observations: observations,
      );

      // Sauvegarder l'attribution
      _attributions[attributionId] = attribution;

      // Marquer les produits comme attribués
      for (final produit in produitsValides) {
        _produits[produit.id] = produit.copyWith(
          estAttribue: true,
          attributionId: attributionId,
        );
      }

      // Sauvegarder dans le module d'extraction/filtration approprié
      await _sauvegarderDansModuleDestination(attribution, produitsValides);

      if (kDebugMode) {
        print('✅ Attribution créée: $attributionId');
        print(
            '📦 ${produitsIds.length} produits attribués à ${siteDestination.nom}');
      }

      return attributionId;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur création attribution: $e');
      }
      rethrow;
    }
  }

  /// Sauvegarde l'attribution dans le module de destination approprié
  Future<void> _sauvegarderDansModuleDestination(
    AttributionProduits attribution,
    List<ProductControle> produits,
  ) async {
    // Simuler la sauvegarde dans le module approprié
    // Dans une vraie application, ceci se connecterait aux services Firestore

    final moduleData = {
      'attribution_id': attribution.id,
      'type': attribution.type.name,
      'site_destination': attribution.siteDestination.nom,
      'date_attribution': attribution.dateAttribution.toIso8601String(),
      'attributeur': attribution.attributeurNom,
      'instructions': attribution.instructions,
      'observations': attribution.observations,
      'produits': produits
          .map((p) => {
                'id': p.id,
                'code_contenant': p.codeContenant,
                'producteur': p.producteur,
                'village': p.village,
                'poids': p.poids,
                'qualite': p.qualite,
                'nature': p.nature.name,
                'type_contenant': p.typeContenant,
                'predominance_florale': p.predominanceFlorale,
                'est_conforme': p.estConforme,
                'collecte_origine': {
                  'id': p.collecteId,
                  'type': p.typeCollecte,
                  'date': p.dateCollecte.toIso8601String(),
                  'collecteur': p.collecteur,
                  'site': p.siteOrigine,
                },
              })
          .toList(),
      'statistiques': {
        'nombre_produits': produits.length,
        'poids_total': produits.fold<double>(0.0, (sum, p) => sum + p.poids),
        'produits_conformes': produits.where((p) => p.estConforme).length,
        'types_contenants':
            produits.map((p) => p.typeContenant).toSet().toList(),
        'predominances':
            produits.map((p) => p.predominanceFlorale).toSet().toList(),
      },
    };

    // Simuler un délai de sauvegarde
    await Future.delayed(Duration(milliseconds: 500));

    if (kDebugMode) {
      print('💾 Données sauvées dans module ${attribution.type.name}:');
      print(jsonEncode(moduleData));
    }
  }

  /// Récupère les attributions créées
  List<AttributionProduits> getAttributions() {
    return _attributions.values.toList()
      ..sort((a, b) => b.dateAttribution.compareTo(a.dateAttribution));
  }

  /// Récupère une attribution par ID
  AttributionProduits? getAttribution(String id) {
    return _attributions[id];
  }

  /// Récupère les statistiques des attributions
  Map<String, dynamic> getStatistiquesAttributions() {
    final attributions = getAttributions();
    final produits = getTousLesProduits();

    return {
      'total_produits': produits.length,
      'produits_attribues': produits.where((p) => p.estAttribue).length,
      'produits_disponibles':
          produits.where((p) => !p.estAttribue && p.estConforme).length,
      'produits_non_conformes': produits.where((p) => !p.estConforme).length,
      'total_attributions': attributions.length,
      'attributions_par_type': {
        for (final type in AttributionType.values)
          type.name: attributions.where((a) => a.type == type).length,
      },
      'attributions_par_site': {
        for (final site in SiteAttribution.values)
          site.name:
              attributions.where((a) => a.siteDestination == site).length,
      },
      'poids_total_attribue': attributions.fold<double>(0.0, (sum, attr) {
        final produitsAttr = attr.produitsIds
            .map((id) => _produits[id])
            .where((p) => p != null)
            .cast<ProductControle>();
        return sum + produitsAttr.fold<double>(0.0, (s, p) => s + p.poids);
      }),
    };
  }

  /// Récupère les attributions par type
  Future<List<AttributionProduits>> getAttributionsByType(
      AttributionType type) async {
    return _attributions.values.where((attr) => attr.type == type).toList();
  }

  /// Récupère les produits d'une attribution
  Future<List<ProductControle>> getProduitsAttribution(
      String attributionId) async {
    final attribution = _attributions[attributionId];
    if (attribution == null) return [];

    final produits = <ProductControle>[];
    for (final produitId in attribution.produitsIds) {
      final produit = _produits[produitId];
      if (produit != null) {
        produits.add(produit);
      }
    }
    return produits;
  }

  /// Annule une attribution
  Future<bool> annulerAttribution(String attributionId) async {
    try {
      final attribution = _attributions[attributionId];
      if (attribution == null) {
        throw Exception('Attribution introuvable');
      }

      // Remettre les produits à l'état non attribué
      for (final produitId in attribution.produitsIds) {
        final produit = _produits[produitId];
        if (produit != null) {
          _produits[produitId] = produit.copyWith(
            estAttribue: false,
            attributionId: null,
          );
        }
      }

      // Supprimer l'attribution
      _attributions.remove(attributionId);

      if (kDebugMode) {
        print('🗑️ Attribution $attributionId annulée');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur annulation attribution: $e');
      }
      return false;
    }
  }

  /// Recherche des produits
  List<ProductControle> rechercherProduits(String query) {
    if (query.isEmpty) return getTousLesProduits();

    final queryLower = query.toLowerCase();
    return getTousLesProduits().where((produit) {
      return produit.codeContenant.toLowerCase().contains(queryLower) ||
          produit.producteur.toLowerCase().contains(queryLower) ||
          produit.village.toLowerCase().contains(queryLower) ||
          produit.predominanceFlorale.toLowerCase().contains(queryLower) ||
          produit.collecteur.toLowerCase().contains(queryLower);
    }).toList();
  }

  /// Filtre les produits selon plusieurs critères
  List<ProductControle> filtrerProduits({
    AttributionType? type,
    List<String>? typesCollecte,
    List<String>? sitesOrigine,
    bool? seulement_conformes,
    bool? seulement_disponibles,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) {
    var produits = getTousLesProduits();

    if (type != null) {
      produits = AttributionUtils.filtrerProduitsParType(produits, type);
    }

    if (typesCollecte != null && typesCollecte.isNotEmpty) {
      produits = produits
          .where((p) => typesCollecte.contains(p.typeCollecte))
          .toList();
    }

    if (sitesOrigine != null && sitesOrigine.isNotEmpty) {
      produits =
          produits.where((p) => sitesOrigine.contains(p.siteOrigine)).toList();
    }

    if (seulement_conformes == true) {
      produits = produits.where((p) => p.estConforme).toList();
    }

    if (seulement_disponibles == true) {
      produits = produits.where((p) => !p.estAttribue).toList();
    }

    if (dateDebut != null) {
      produits = produits
          .where((p) =>
              p.dateReception.isAfter(dateDebut.subtract(Duration(days: 1))))
          .toList();
    }

    if (dateFin != null) {
      produits = produits
          .where(
              (p) => p.dateReception.isBefore(dateFin.add(Duration(days: 1))))
          .toList();
    }

    return produits;
  }

  /// Récupère tous les produits contrôlés disponibles
  List<ProductControle> obtenirTousLesProduits() {
    return _produits.values.toList();
  }
}
