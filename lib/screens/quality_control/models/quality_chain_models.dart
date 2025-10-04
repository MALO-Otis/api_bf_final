import 'quality_vocab.dart';
import 'package:flutter/material.dart';
import '../../controle_de_donnes/models/quality_control_models.dart';

/// Mesures suivies pour une étape donnée du contrôle qualité.
class QualityStepMetrics {
  final QualityChainStep step;
  final ConformityStatus conformityStatus;
  final double? waterContent;
  final double? pollenLostKg;
  final double? residuePercent;
  final QualityOdorProfile odorProfile;
  final QualityDepositLevel depositProfile;
  final String? controllerName;
  final DateTime lastUpdated;
  final String? observation;

  const QualityStepMetrics({
    required this.step,
    required this.conformityStatus,
    this.waterContent,
    this.pollenLostKg,
    this.residuePercent,
    required this.odorProfile,
    required this.depositProfile,
    this.controllerName,
    this.observation,
    required this.lastUpdated,
  });

  bool get isConform => conformityStatus == ConformityStatus.conforme;
  bool get requiresObservation =>
      !isConform && (observation == null || observation!.isEmpty);
}

/// Rassemble les mesures qualité pour un lot donné.
class QualityLotSnapshot {
  final String lotCode;
  final String productType;
  final DateTime referenceDate;
  final Map<QualityChainStep, QualityStepMetrics> metricsByStep;

  const QualityLotSnapshot({
    required this.lotCode,
    required this.productType,
    required this.referenceDate,
    required this.metricsByStep,
  });

  double? get latestWaterContent {
    for (final step in QualityChainStep.values) {
      final metrics = metricsByStep[step];
      if (metrics?.waterContent != null) {
        return metrics!.waterContent;
      }
    }
    return null;
  }

  ConformityStatus overallStatus() {
    if (metricsByStep.values
        .any((m) => m.conformityStatus == ConformityStatus.nonConforme)) {
      return ConformityStatus.nonConforme;
    }
    return ConformityStatus.conforme;
  }
}

/// Filtres disponibles pour la vue Contrôle Qualité.
class QualityFilterState {
  final DateTimeRange? period;
  final QualityChainStep? step;
  final ConformityStatus? conformityStatus;
  final String? productType;

  const QualityFilterState({
    this.period,
    this.step,
    this.conformityStatus,
    this.productType,
  });

  QualityFilterState copyWith({
    DateTimeRange? period,
    QualityChainStep? step,
    ConformityStatus? conformityStatus,
    String? productType,
  }) {
    return QualityFilterState(
      period: period ?? this.period,
      step: step ?? this.step,
      conformityStatus: conformityStatus ?? this.conformityStatus,
      productType: productType ?? this.productType,
    );
  }
}

/// Résumé agrégé utilisé dans les cartes de têtes.
class QualitySummaryMetrics {
  final int totalLots;
  final int conformLots;
  final int nonConformLots;
  final double averageWaterContent;
  final double averageResiduePercent;
  final double totalPollenLostKg;

  const QualitySummaryMetrics({
    required this.totalLots,
    required this.conformLots,
    required this.nonConformLots,
    required this.averageWaterContent,
    required this.averageResiduePercent,
    required this.totalPollenLostKg,
  });

  double get conformityRate => totalLots == 0 ? 0 : conformLots / totalLots;
}
