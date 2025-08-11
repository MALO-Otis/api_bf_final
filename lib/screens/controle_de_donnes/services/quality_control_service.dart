// Service pour la gestion des données de contrôle qualité
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/quality_control_models.dart';

/// Service pour sauvegarder et récupérer les données de contrôle qualité
class QualityControlService {
  static final QualityControlService _instance =
      QualityControlService._internal();
  factory QualityControlService() => _instance;
  QualityControlService._internal();

  // Stockage en mémoire pour la démonstration
  // Dans un vrai projet, ceci serait connecté à Firebase/SQLite
  final Map<String, QualityControlData> _qualityControls = {};

  /// Sauvegarde un contrôle qualité
  Future<bool> saveQualityControl(QualityControlData data) async {
    try {
      // Créer une clé unique basée sur le contenant et la collecte
      final key =
          '${data.containerCode}_${data.receptionDate.millisecondsSinceEpoch}';

      _qualityControls[key] = data;

      // Simulation d'une sauvegarde async (Firebase, etc.)
      await Future.delayed(const Duration(milliseconds: 500));

      if (kDebugMode) {
        print('✅ Contrôle qualité sauvegardé: $key');
        print('📊 Données: ${jsonEncode(data.toJson())}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la sauvegarde: $e');
      }
      return false;
    }
  }

  /// Récupère un contrôle qualité par code de contenant
  QualityControlData? getQualityControl(
      String containerCode, DateTime receptionDate) {
    final key = '${containerCode}_${receptionDate.millisecondsSinceEpoch}';
    return _qualityControls[key];
  }

  /// Récupère tous les contrôles qualité pour une période donnée
  List<QualityControlData> getQualityControlsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _qualityControls.values
        .where((control) =>
            control.receptionDate
                .isAfter(startDate.subtract(const Duration(days: 1))) &&
            control.receptionDate
                .isBefore(endDate.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => b.receptionDate.compareTo(a.receptionDate));
  }

  /// Récupère tous les contrôles qualité d'un producteur
  List<QualityControlData> getQualityControlsByProducer(String producer) {
    return _qualityControls.values
        .where((control) =>
            control.producer.toLowerCase().contains(producer.toLowerCase()))
        .toList()
      ..sort((a, b) => b.receptionDate.compareTo(a.receptionDate));
  }

  /// Récupère les statistiques de conformité
  QualityStats getQualityStats({DateTime? startDate, DateTime? endDate}) {
    var controls = _qualityControls.values.toList();

    if (startDate != null && endDate != null) {
      controls = controls
          .where((control) =>
              control.receptionDate
                  .isAfter(startDate.subtract(const Duration(days: 1))) &&
              control.receptionDate
                  .isBefore(endDate.add(const Duration(days: 1))))
          .toList();
    }

    final total = controls.length;
    final conforme = controls
        .where((c) => c.conformityStatus == ConformityStatus.conforme)
        .length;
    final nonConforme = total - conforme;

    final averageWaterContent = controls
            .where((c) => c.waterContent != null)
            .fold<double>(0, (sum, c) => sum + c.waterContent!) /
        controls.where((c) => c.waterContent != null).length;

    final totalHoneyWeight =
        controls.fold<double>(0, (sum, c) => sum + c.honeyWeight);

    return QualityStats(
      totalControls: total,
      conformeCount: conforme,
      nonConformeCount: nonConforme,
      conformityRate: total > 0 ? (conforme / total) * 100 : 0,
      averageWaterContent: averageWaterContent.isNaN ? 0 : averageWaterContent,
      totalHoneyWeight: totalHoneyWeight,
    );
  }

  /// Supprime un contrôle qualité
  Future<bool> deleteQualityControl(
      String containerCode, DateTime receptionDate) async {
    try {
      final key = '${containerCode}_${receptionDate.millisecondsSinceEpoch}';
      _qualityControls.remove(key);

      await Future.delayed(const Duration(milliseconds: 200));

      if (kDebugMode) {
        print('🗑️ Contrôle qualité supprimé: $key');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la suppression: $e');
      }
      return false;
    }
  }

  /// Exporte les données en JSON
  String exportToJson({DateTime? startDate, DateTime? endDate}) {
    var controls = _qualityControls.values.toList();

    if (startDate != null && endDate != null) {
      controls = controls
          .where((control) =>
              control.receptionDate
                  .isAfter(startDate.subtract(const Duration(days: 1))) &&
              control.receptionDate
                  .isBefore(endDate.add(const Duration(days: 1))))
          .toList();
    }

    final data = {
      'export_date': DateTime.now().toIso8601String(),
      'total_controls': controls.length,
      'quality_controls': controls.map((c) => c.toJson()).toList(),
    };

    return jsonEncode(data);
  }

  /// Vérifie si un contenant a déjà été contrôlé
  bool isContainerControlled(String containerCode, DateTime receptionDate) {
    final key = '${containerCode}_${receptionDate.millisecondsSinceEpoch}';
    return _qualityControls.containsKey(key);
  }

  /// Récupère les causes de non-conformité les plus fréquentes
  Map<String, int> getNonConformityCauses() {
    final causes = <String, int>{};

    for (final control in _qualityControls.values) {
      if (control.conformityStatus == ConformityStatus.nonConforme &&
          control.nonConformityCause != null) {
        final cause = control.nonConformityCause!;
        causes[cause] = (causes[cause] ?? 0) + 1;
      }
    }

    // Trier par fréquence décroissante
    final sortedEntries = causes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries);
  }

  /// Génère des données de test pour la démonstration
  void generateTestData() {
    final testData = [
      QualityControlData(
        containerCode: 'C001',
        receptionDate: DateTime.now().subtract(const Duration(days: 1)),
        producer: 'Coopérative Ouagadougou',
        apiaryVillage: 'Saaba',
        hiveType: 'Langstroth',
        collectionStartDate: DateTime.now().subtract(const Duration(days: 10)),
        collectionEndDate: DateTime.now().subtract(const Duration(days: 2)),
        honeyNature: HoneyNature.brut,
        containerType: 'Bidon plastique',
        containerNumber: 'BID001',
        totalWeight: 25.5,
        honeyWeight: 23.2,
        quality: 'Excellente',
        waterContent: 18.2,
        floralPredominance: 'Acacia',
        conformityStatus: ConformityStatus.conforme,
        createdAt: DateTime.now(),
        controllerName: 'Marie OUEDRAOGO',
      ),
      QualityControlData(
        containerCode: 'C002',
        receptionDate: DateTime.now().subtract(const Duration(days: 2)),
        producer: 'Association Koudougou',
        apiaryVillage: 'Réo',
        hiveType: 'Kenyane',
        honeyNature: HoneyNature.prefilitre,
        containerType: 'Pot en verre',
        containerNumber: 'POT002',
        totalWeight: 12.8,
        honeyWeight: 11.5,
        quality: 'Bonne',
        waterContent: 21.5,
        floralPredominance: 'Karité',
        conformityStatus: ConformityStatus.nonConforme,
        nonConformityCause: 'Teneur en eau trop élevée',
        observations: 'Recommander une période de maturation plus longue',
        createdAt: DateTime.now(),
        controllerName: 'Paul SAWADOGO',
      ),
    ];

    for (final data in testData) {
      saveQualityControl(data);
    }
  }
}

/// Modèle pour les statistiques de qualité
class QualityStats {
  final int totalControls;
  final int conformeCount;
  final int nonConformeCount;
  final double conformityRate;
  final double averageWaterContent;
  final double totalHoneyWeight;

  const QualityStats({
    required this.totalControls,
    required this.conformeCount,
    required this.nonConformeCount,
    required this.conformityRate,
    required this.averageWaterContent,
    required this.totalHoneyWeight,
  });
}
