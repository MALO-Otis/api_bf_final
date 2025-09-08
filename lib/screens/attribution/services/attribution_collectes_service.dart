/// 🎯 SERVICE POUR L'ATTRIBUTION DES COLLECTES
///
/// Ce service gère la logique d'attribution des produits contrôlés,
/// en s'inspirant de la logique du module de contrôle qualité.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../controle_de_donnes/models/collecte_models.dart';
import '../../controle_de_donnes/services/firestore_data_service.dart';
import '../../controle_de_donnes/services/quality_control_service.dart';
import '../../controle_de_donnes/models/quality_control_models.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart';

class AttributionCollectesService {
  static final AttributionCollectesService _instance =
      AttributionCollectesService._internal();
  factory AttributionCollectesService() => _instance;
  AttributionCollectesService._internal();

  final QualityControlService _qualityService = QualityControlService();

  /// Récupère toutes les collectes avec leurs informations de contrôle
  Future<Map<Section, List<BaseCollecte>>> getCollectesWithControlInfo() async {
    try {
      if (kDebugMode) {
        print(
            '🔄 [Attribution Service] Chargement des collectes pour attribution...');
      }

      // Charger toutes les collectes depuis Firestore
      final collectesData =
          await FirestoreDataService.getCollectesFromFirestore();

      if (kDebugMode) {
        print(
            '✅ [Attribution Service] \${collectesData.values.expand((list) => list).length} collectes chargées');
      }

      return collectesData;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Attribution Service] Erreur chargement collectes: \$e');
      }
      rethrow;
    }
  }

  /// Récupère les informations de contrôle pour une collecte spécifique
  /// 🔧 NOUVELLE VERSION: Utilise les vraies données de contrôle qualité depuis Firestore
  Future<CollecteControlInfo> getControlInfoForCollecte(
      String collecteId, BaseCollecte collecte) async {
    try {
      if (kDebugMode) {
        print(
            '🔍 [Attribution Service] Récupération contrôle pour collecte: \$collecteId');
        print('   Site: \${collecte.site}, Type: \${collecte.runtimeType}');
        print('   Village: \${_getCollecteLocation(collecte)}');
        print('   Technicien: \${collecte.technicien ?? "Non défini"}');
        print('   Date: \${collecte.date}');
      }

      // 🔧 NOUVELLE APPROCHE: Récupérer directement depuis controles_qualite
      final controles =
          await _qualityService.getQualityControlsForCollecte(collecteId);

      if (kDebugMode) {
        print('   📊 Contrôles qualité trouvés: \${controles.length}');
        for (final controle in controles) {
          print(
              '      - \${controle.containerCode}: \${controle.totalWeight}kg total, \${controle.honeyWeight}kg miel, \${controle.conformityStatus}');
        }
      }

      // Analyser la structure de la collecte pour obtenir le nombre total de contenants déclarés
      int totalContainers = 0;
      if (collecte is Recolte) {
        totalContainers = collecte.contenants.length;
        if (kDebugMode) {
          print('   📦 RECOLTE - Contenants déclarés: \$totalContainers');
        }
      } else if (collecte is Scoop) {
        totalContainers = collecte.contenants.length;
        if (kDebugMode) {
          print('   🥄 SCOOP - Contenants déclarés: \$totalContainers');
        }
      } else if (collecte is Individuel) {
        totalContainers = collecte.contenants.length;
        if (kDebugMode) {
          print('   👤 INDIVIDUEL - Contenants déclarés: \$totalContainers');
        }
      }

      // 🔧 UTILISER LES VRAIES DONNÉES DE FIRESTORE
      final controlsByContainer = <String, QualityControlData>{};
      for (final controle in controles) {
        controlsByContainer[controle.containerCode] = controle;
      }

      // 🔧 CALCULER LES STATISTIQUES À PARTIR DES VRAIES DONNÉES FIRESTORE
      final controlledContainers = controles.length;
      final conformeCount = controles
          .where((c) => c.conformityStatus == ConformityStatus.conforme)
          .length;
      final nonConformeCount = controles
          .where((c) => c.conformityStatus == ConformityStatus.nonConforme)
          .length;

      final controlInfo = CollecteControlInfo(
        collecteId: collecteId,
        totalContainers: totalContainers,
        controlledContainers: controlledContainers,
        conformeCount: conformeCount,
        nonConformeCount: nonConformeCount,
        controlsByContainer: controlsByContainer,
        lastUpdated: controles.isNotEmpty
            ? controles
                .map((c) => c.createdAt)
                .reduce((a, b) => a.isAfter(b) ? a : b)
            : DateTime.now(),
      );

      if (kDebugMode) {
        print('✅ [Attribution Service] Info contrôle finale:');
        print('   📦 Total contenants: \${controlInfo.totalContainers}');
        print(
            '   ✅ Contenants contrôlés: \${controlInfo.controlledContainers}');
        print('   😊 Conformes: \${controlInfo.conformeCount}');
        print('   😞 Non conformes: \${controlInfo.nonConformeCount}');
        print('   ⏳ Restants: \${controlInfo.totalRestants}');
        print(
            '   🎯 Produits conformes disponibles: \${controlInfo.produitsConformesDisponibles.length}');
        print(
            '   📈 Taux de completion: \${(controlInfo.completionPercentage * 100).toStringAsFixed(1)}%');

        // Afficher les poids réels de Firestore
        double totalWeightFromFirestore = 0;
        double honeyWeightFromFirestore = 0;
        for (final controle in controles) {
          totalWeightFromFirestore += controle.totalWeight;
          honeyWeightFromFirestore += controle.honeyWeight;
        }
        print(
            '   💰 Poids total réel (Firestore): \${totalWeightFromFirestore}kg');
        print(
            '   🍯 Poids miel réel (Firestore): \${honeyWeightFromFirestore}kg');
      }

      return controlInfo;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Attribution Service] Erreur récupération contrôle: \$e');
      }
      rethrow;
    }
  }

  /// Récupère les produits conformes disponibles pour attribution depuis une collecte
  /// 🔧 NOUVELLE VERSION: Utilise les vraies données de contrôle qualité
  Future<List<ProductControle>> getProduitsConformesFromCollecte(
      BaseCollecte collecte, Section section) async {
    final collecteId = collecte.id;

    if (kDebugMode) {
      print(
          '🎯 [Attribution Service] Récupération produits conformes pour collecte: \$collecteId');
    }

    // 🔧 Utiliser les vraies données de contrôle qualité depuis Firestore
    final controles =
        await _qualityService.getQualityControlsForCollecte(collecteId);
    final produits = <ProductControle>[];

    try {
      // 🔧 CRÉER LES PRODUITS À PARTIR DES VRAIES DONNÉES FIRESTORE
      for (final controle in controles) {
        if (controle.conformityStatus == ConformityStatus.conforme) {
          final produit = ProductControle(
            id: '\${collecte.id}_\${controle.containerCode}',
            collecteId: collecte.id,
            containerCode: controle.containerCode,
            collecteType: section,
            localite: _getCollecteLocation(collecte),
            technicien: collecte.technicien ?? 'Non défini',
            dateReception: controle.receptionDate,
            productType: _getProductTypeFromSection(section),
            quantity:
                controle.totalWeight, // 🔧 UTILISER LE VRAI POIDS DE FIRESTORE
            qualityControl: controle, // 🔧 UTILISER LES VRAIES DONNÉES
            isAttributed: false,
            attributionDate: null,
            attributionDetails: null,
          );

          produits.add(produit);

          if (kDebugMode) {
            print('   ✅ Produit conforme ajouté: \${controle.containerCode}');
            print(
                '      - Poids total: \${controle.totalWeight}kg (Firestore)');
            print('      - Poids miel: \${controle.honeyWeight}kg (Firestore)');
            print('      - Qualité: \${controle.quality}');
          }
        }
      }

      if (kDebugMode) {
        print(
            '🎯 [Attribution Service] \${produits.length} produits conformes trouvés pour \$collecteId');
      }

      return produits;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Attribution Service] Erreur récupération produits: \$e');
      }
      return [];
    }
  }

  /// Récupère tous les produits contrôlés disponibles pour attribution
  Future<List<ProductControle>> getProduitsControlesDisponibles() async {
    try {
      final collectesData = await getCollectesWithControlInfo();
      final tousLesProduits = <ProductControle>[];

      for (final entry in collectesData.entries) {
        final section = entry.key;
        final collectes = entry.value;

        for (final collecte in collectes) {
          final produitsCollecte =
              await getProduitsConformesFromCollecte(collecte, section);
          tousLesProduits.addAll(produitsCollecte);
        }
      }

      if (kDebugMode) {
        print(
            '🎯 [Attribution Service] Total produits disponibles: \${tousLesProduits.length}');
      }

      return tousLesProduits;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Attribution Service] Erreur récupération tous produits: \$e');
      }
      return [];
    }
  }

  /// Obtient la localisation d'une collecte
  String _getCollecteLocation(BaseCollecte collecte) {
    if (collecte is Recolte) {
      return collecte.village ??
          collecte.commune ??
          collecte.localisation ??
          collecte.site;
    } else if (collecte is Scoop) {
      return collecte.village ??
          collecte.commune ??
          collecte.localisation ??
          collecte.site;
    } else if (collecte is Individuel) {
      return collecte.village ??
          collecte.commune ??
          collecte.localisation ??
          collecte.site;
    }
    return collecte.site;
  }

  /// Détermine le type de produit selon la section
  ProductType _getProductTypeFromSection(Section section) {
    switch (section) {
      case Section.recoltes:
        return ProductType.extraction;
      case Section.scoop:
      case Section.individuel:
      case Section.miellerie:
        return ProductType.filtrage;
    }
  }
}

/// Modèle pour les informations de contrôle d'une collecte
class CollecteControlInfo {
  final String collecteId;
  final int totalContainers;
  final int controlledContainers;
  final int conformeCount;
  final int nonConformeCount;
  final Map<String, QualityControlData> controlsByContainer;
  final DateTime lastUpdated;

  CollecteControlInfo({
    required this.collecteId,
    required this.totalContainers,
    required this.controlledContainers,
    required this.conformeCount,
    required this.nonConformeCount,
    required this.controlsByContainer,
    required this.lastUpdated,
  });

  /// Nombre de contenants restant à contrôler
  int get totalRestants => totalContainers - controlledContainers;

  /// Pourcentage de completion du contrôle
  double get completionPercentage =>
      totalContainers > 0 ? controlledContainers / totalContainers : 0.0;

  /// Indique s'il y a des produits disponibles pour attribution
  bool get hasAvailableProducts => conformeCount > 0;

  /// Nombre total de produits disponibles pour attribution
  int get totalDisponibles => conformeCount;

  /// 🔧 NOUVELLE PROPRIÉTÉ: Poids total depuis les contrôles Firestore
  double get poidsTotal {
    return controlsByContainer.values
        .fold(0.0, (sum, control) => sum + control.totalWeight);
  }

  /// 🔧 NOUVELLE PROPRIÉTÉ: Poids conformes depuis les contrôles Firestore
  double get poidsConformes {
    return controlsByContainer.values
        .where(
            (control) => control.conformityStatus == ConformityStatus.conforme)
        .fold(0.0, (sum, control) => sum + control.totalWeight);
  }

  /// 🔧 NOUVELLE PROPRIÉTÉ: Poids non conformes depuis les contrôles Firestore
  double get poidsNonConformes {
    return controlsByContainer.values
        .where((control) =>
            control.conformityStatus == ConformityStatus.nonConforme)
        .fold(0.0, (sum, control) => sum + control.totalWeight);
  }

  /// Liste des produits conformes disponibles pour attribution
  List<QualityControlData> get produitsConformesDisponibles {
    return controlsByContainer.values
        .where(
            (control) => control.conformityStatus == ConformityStatus.conforme)
        .toList();
  }

  /// Couleur de statut basée sur le taux de conformité
  Color get statusColor {
    if (controlledContainers == 0) return Colors.grey;
    final conformityRate = conformeCount / controlledContainers;
    if (conformityRate >= 0.8) return Colors.green;
    if (conformityRate >= 0.5) return Colors.orange;
    return Colors.red;
  }

  /// Résumé du statut de contrôle
  String get statusSummary {
    if (controlledContainers == 0) return 'Aucun contrôle';
    final conformityRate = (conformeCount / controlledContainers * 100).round();
    return '$conformityRate% conformes';
  }

  /// Nombre total d'attributions (simulé)
  int get totalAttribues => conformeCount ~/ 2; // Simulation simple

  /// Pourcentage de conformité
  double get conformityPercentage =>
      controlledContainers > 0 ? conformeCount / controlledContainers : 0.0;
}
