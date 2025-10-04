import 'dart:math' as math;
import '../models/quality_vocab.dart';
import '../models/quality_chain_models.dart';
import '../../controle_de_donnes/models/quality_control_models.dart';

/// Service utilitaire pour centraliser les calculs qualité et la codification.
class QualityComputationService {
  const QualityComputationService();

  /// Calcule automatiquement la teneur en eau estimée à partir du contenant,
  /// de l'odeur perçue et du niveau de dépôts. Un relevé manuel peut être
  /// fourni pour pondérer le résultat (moyenne pondérée peu biaisée).
  double computeWaterContent({
    required ContainerType containerType,
    required QualityOdorProfile odorProfile,
    required QualityDepositLevel depositLevel,
    double? manualMeasure,
    double ambientHumidity = 45,
  }) {
    final containerBase = switch (containerType) {
      ContainerType.bidon => 17.8,
      ContainerType.fut => 18.5,
      ContainerType.seau => 17.0,
      ContainerType.sac => 19.2,
    };

    final odorImpact = switch (odorProfile) {
      QualityOdorProfile.floral => -0.3,
      QualityOdorProfile.vegetal => 0.2,
      QualityOdorProfile.fumee => 0.6,
      QualityOdorProfile.fermentation => 1.2,
      QualityOdorProfile.neutre => 0.0,
      QualityOdorProfile.suspect => 1.5,
    };

    final depositImpact = switch (depositLevel) {
      QualityDepositLevel.aucun => -0.2,
      QualityDepositLevel.faible => 0.0,
      QualityDepositLevel.moyen => 0.4,
      QualityDepositLevel.important => 0.9,
    };

    final humidityDrift = (ambientHumidity - 45) * 0.03;

    final estimation =
        containerBase + odorImpact + depositImpact + humidityDrift;

    if (manualMeasure == null) {
      return _clamp(estimation);
    }

    // Pondération douce 60/40 entre estimation heuristique et mesure réelle
    final weighted = (estimation * 0.6) + (manualMeasure * 0.4);
    return _clamp(weighted);
  }

  /// Enforce observation requirement when non compliant.
  String? validateObservation(ConformityStatus status, String? observation) {
    if (status == ConformityStatus.conforme) {
      return null;
    }
    if (observation == null || observation.trim().isEmpty) {
      return "Une observation est obligatoire pour une non conformité.";
    }
    if (observation.trim().length < 10) {
      return "Merci de détailler l'observation (10 caractères minimum).";
    }
    return null;
  }

  /// Génère un code lot strict basé sur la codification existante (site + étape + timestamp).
  String buildLotCode({
    required String site,
    required QualityChainStep step,
    required String baseCode,
    DateTime? reference,
  }) {
    final sanitizedSite = site
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '')
        .padRight(3, 'X')
        .substring(0, 3);
    final sanitizedBase = baseCode
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '')
        .padRight(6, '0')
        .substring(0, 6);
    final timestamp = (reference ?? DateTime.now());
    final stamp = '${timestamp.year.remainder(100).toString().padLeft(2, '0')}'
        '${timestamp.month.toString().padLeft(2, '0')}'
        '${timestamp.day.toString().padLeft(2, '0')}'
        '${timestamp.hour.toString().padLeft(2, '0')}'
        '${timestamp.minute.toString().padLeft(2, '0')}';

    return '${sanitizedSite}_${step.name.toUpperCase()}_${sanitizedBase}_$stamp';
  }

  /// Agrège des métriques globales à afficher sur le tableau de bord.
  QualitySummaryMetrics buildSummary(List<QualityLotSnapshot> lots) {
    if (lots.isEmpty) {
      return const QualitySummaryMetrics(
        totalLots: 0,
        conformLots: 0,
        nonConformLots: 0,
        averageWaterContent: 0,
        averageResiduePercent: 0,
        totalPollenLostKg: 0,
      );
    }

    final conformLots = lots
        .where((lot) => lot.overallStatus() == ConformityStatus.conforme)
        .length;
    final nonConformLots = lots.length - conformLots;

    final waterValues = lots
        .map((lot) => lot.latestWaterContent)
        .nonNulls
        .toList(growable: false);
    final residueValues = lots
        .expand((lot) => lot.metricsByStep.values)
        .map((metrics) => metrics.residuePercent)
        .nonNulls
        .toList(growable: false);
    final pollenTotal = lots
        .expand((lot) => lot.metricsByStep.values)
        .map((metrics) => metrics.pollenLostKg ?? 0)
        .fold<double>(0, (sum, value) => sum + value);

    final averageWater = waterValues.isEmpty
        ? 0.0
        : waterValues.fold<double>(0, (sum, value) => sum + value) /
            waterValues.length;
    final averageResidue = residueValues.isEmpty
        ? 0.0
        : residueValues.fold<double>(0, (sum, value) => sum + value) /
            residueValues.length;

    return QualitySummaryMetrics(
      totalLots: lots.length,
      conformLots: conformLots,
      nonConformLots: nonConformLots,
      averageWaterContent: averageWater,
      averageResiduePercent: averageResidue,
      totalPollenLostKg: pollenTotal,
    );
  }

  double _clamp(double value) => math.max(14.0, math.min(24.0, value));
}
