import 'dart:async';
import 'package:get/get.dart';
import '../models/quality_vocab.dart';
import 'package:collection/collection.dart';
import '../models/quality_chain_models.dart';
import '../services/quality_report_service.dart';
import '../services/quality_computation_service.dart';
import '../../controle_de_donnes/models/quality_control_models.dart';
import '../../controle_de_donnes/services/quality_control_service.dart';

/// Contrôleur principal du module Contrôle Qualité.
class QualityControlController extends GetxController {
  final QualityControlService _qualityService = QualityControlService();
  final QualityComputationService _computationService =
      const QualityComputationService();
  final QualityReportService _reportService = const QualityReportService();

  final RxBool isLoading = false.obs;
  final RxBool isExporting = false.obs;
  final RxList<QualityLotSnapshot> _allLots = <QualityLotSnapshot>[].obs;
  final RxList<QualityLotSnapshot> displayedLots = <QualityLotSnapshot>[].obs;
  final Rx<QualitySummaryMetrics?> summaryMetrics =
      Rx<QualitySummaryMetrics?>(null);
  final Rx<QualityFilterState> filters = const QualityFilterState().obs;

  StreamSubscription<Map<String, QualityControlData>>? _controlsSubscription;

  @override
  void onInit() {
    super.onInit();
    _wireStreams();
    loadData();
  }

  @override
  void onClose() {
    _controlsSubscription?.cancel();
    super.onClose();
  }

  void _wireStreams() {
    _controlsSubscription = _qualityService.controlsStream.listen((_) {
      loadData();
    });
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;
      await _qualityService.refreshAllData();
      final controls = _qualityService.getAllQualityControls();
      final lots = _buildSnapshots(controls)
        ..sort((a, b) => b.referenceDate.compareTo(a.referenceDate));
      _allLots.assignAll(lots);
      _applyFilters();
    } finally {
      isLoading.value = false;
    }
  }

  bool get hasData => _allLots.isNotEmpty;

  List<String> get availableProductTypes {
    final types = _allLots
        .map((lot) => lot.productType)
        .where((type) => type.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);
    types.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return types;
  }

  void updateFilters(QualityFilterState newFilters) {
    filters.value = newFilters;
    _applyFilters();
  }

  void resetFilters() {
    filters.value = const QualityFilterState();
    _applyFilters();
  }

  List<QualityLotSnapshot> _buildSnapshots(List<QualityControlData> controls) {
    final grouped = groupBy(controls, (QualityControlData control) {
      return control.containerCode;
    });

    return grouped.entries.map((entry) {
      final metrics = <QualityChainStep, QualityStepMetrics>{};
      for (final control in entry.value) {
        final step = _resolveStep(control);
        metrics[step] = _buildMetrics(step, control);
      }

      final firstControl = entry.value.first;
      return QualityLotSnapshot(
        lotCode: entry.key,
        productType: firstControl.honeyNature.name,
        referenceDate: firstControl.receptionDate,
        metricsByStep: metrics,
      );
    }).toList(growable: false);
  }

  QualityStepMetrics _buildMetrics(
      QualityChainStep step, QualityControlData control) {
    final waterContent = control.waterContent ??
        _computationService.computeWaterContent(
          containerType: _resolveContainerType(control.containerType),
          odorProfile: control.odorProfile,
          depositLevel: control.depositLevel,
          manualMeasure: control.manualWaterContent,
        );

    return QualityStepMetrics(
      step: step,
      conformityStatus: control.conformityStatus,
      waterContent: waterContent,
      pollenLostKg: control.pollenLostKg,
      residuePercent: control.residuePercent,
      odorProfile: control.odorProfile,
      depositProfile: control.depositLevel,
      controllerName: control.controllerName,
      observation: control.observations,
      lastUpdated: control.createdAt,
    );
  }

  void _applyFilters() {
    var filtered = _allLots.toList(growable: false);
    final filterState = filters.value;

    if (filterState.period != null) {
      filtered = filtered
          .where((lot) =>
              !lot.referenceDate.isBefore(filterState.period!.start) &&
              !lot.referenceDate.isAfter(filterState.period!.end))
          .toList(growable: false);
    }

    if (filterState.step != null) {
      filtered = filtered
          .where((lot) => lot.metricsByStep.containsKey(filterState.step))
          .toList(growable: false);
    }

    if (filterState.conformityStatus != null) {
      filtered = filtered
          .where((lot) => lot.overallStatus() == filterState.conformityStatus)
          .toList(growable: false);
    }

    if (filterState.productType != null &&
        filterState.productType!.isNotEmpty) {
      filtered = filtered
          .where((lot) => lot.productType == filterState.productType)
          .toList(growable: false);
    }

    displayedLots.assignAll(filtered);
    summaryMetrics.value =
        _computationService.buildSummary(displayedLots.toList(growable: false));
  }

  Future<QualityReportResult> exportCurrentView() async {
    if (displayedLots.isEmpty) {
      return const QualityReportResult(
        success: false,
        message: 'Aucun lot filtré à exporter.',
      );
    }
    if (isExporting.value) {
      return const QualityReportResult(
        success: false,
        message: 'Un export est déjà en cours…',
      );
    }

    try {
      isExporting.value = true;
      return await _reportService.exportLotsToCsv(
        lots: displayedLots.toList(growable: false),
        summary: summaryMetrics.value,
      );
    } finally {
      isExporting.value = false;
    }
  }

  QualityChainStep _resolveStep(QualityControlData control) {
    final typeAttribution = control.typeAttribution?.toLowerCase();
    switch (typeAttribution) {
      case 'filtrage':
        return QualityChainStep.filtration;
      case 'extraction':
        return QualityChainStep.extraction;
      case 'maturation':
      case 'cire':
        return QualityChainStep.maturation;
      case 'conditionnement':
        return QualityChainStep.conditionnement;
      case 'vente':
        return QualityChainStep.vente;
      case 'attribution':
        return QualityChainStep.attribution;
    }

    switch (control.honeyNature) {
      case HoneyNature.brut:
        return QualityChainStep.collecte;
      case HoneyNature.prefilitre:
        return QualityChainStep.filtration;
      case HoneyNature.cire:
        return QualityChainStep.maturation;
    }
  }

  ContainerType _resolveContainerType(String rawValue) {
    final lower = rawValue.toLowerCase();
    return ContainerType.values.firstWhere(
      (type) =>
          type.name.toLowerCase() == lower || type.label.toLowerCase() == lower,
      orElse: () => ContainerType.bidon,
    );
  }
}
