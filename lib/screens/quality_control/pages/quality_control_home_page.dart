import 'package:get/get.dart';
import '../models/quality_vocab.dart';
import 'package:flutter/material.dart';
import '../models/quality_chain_models.dart';
import '../widgets/quality_filters_panel.dart';
import '../widgets/quality_lot_collection.dart';
import '../widgets/quality_summary_header.dart';
import '../controllers/quality_control_controller.dart';
import '../../controle_de_donnes/models/quality_control_models.dart';

class QualityControlHomePage extends StatelessWidget {
  const QualityControlHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(QualityControlController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contrôle Qualité'),
        actions: [
          Obx(() {
            final exporting = controller.isExporting.value;
            final lotsEmpty = controller.displayedLots.isEmpty;
            return IconButton(
              tooltip: exporting
                  ? 'Export en cours…'
                  : lotsEmpty
                      ? 'Aucun lot à exporter'
                      : 'Exporter la vue (CSV)',
              onPressed: exporting || lotsEmpty
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final result = await controller.exportCurrentView();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(result.message),
                          backgroundColor:
                              result.success ? Colors.green : Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
              icon: exporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
            );
          }),
          IconButton(
            tooltip: 'Rafraîchir',
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadData(),
          ),
        ],
      ),
      body: Obx(() {
        final isLoading = controller.isLoading.value;
        final lots = controller.displayedLots;
        final summary = controller.summaryMetrics.value;
        final filters = controller.filters.value;

        return RefreshIndicator(
          onRefresh: controller.loadData,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  QualitySummaryHeader(
                    metrics: summary,
                    isLoading: isLoading && !controller.hasData,
                  ),
                  const SizedBox(height: 24),
                  QualityFiltersPanel(
                    filterState: filters,
                    availableProductTypes: controller.availableProductTypes,
                    onFiltersChanged: controller.updateFilters,
                    onResetFilters: controller.resetFilters,
                  ),
                  const SizedBox(height: 24),
                  if (isLoading && !controller.hasData)
                    const _LoadingPlaceholder()
                  else if (lots.isEmpty)
                    const _EmptyState()
                  else
                    QualityLotCollection(
                      lots: lots,
                      onLotSelected: (lot) => _showLotDetails(context, lot),
                      isLoading: isLoading,
                    ),
                ],
              );
            },
          ),
        );
      }),
    );
  }

  void _showLotDetails(BuildContext context, QualityLotSnapshot lot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, controller) {
          return _LotDetailsSheet(scrollController: controller, lot: lot);
        },
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ShimmerLoading(
            height: 140,
            borderRadius: BorderRadius.circular(16),
          ),
        );
      }),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.orange.shade300),
          const SizedBox(height: 12),
          const Text(
            'Aucun lot ne correspond aux filtres',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajustez les filtres (étape, statut, période ou type de produit) pour voir plus de résultats.',
            style: TextStyle(color: Colors.orange.shade700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LotDetailsSheet extends StatelessWidget {
  final ScrollController scrollController;
  final QualityLotSnapshot lot;

  const _LotDetailsSheet({
    required this.scrollController,
    required this.lot,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, -2),
            blurRadius: 16,
            color: Colors.black12,
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: ListView(
          controller: scrollController,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.inventory_2_outlined,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lot.lotCode,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        lot.productType,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: lot.overallStatus()),
              ],
            ),
            const SizedBox(height: 16),
            if (lot.latestWaterContent != null)
              _MetricLine(
                icon: Icons.water_drop_outlined,
                label: 'Dernière teneur en eau',
                value: '${lot.latestWaterContent!.toStringAsFixed(1)} %',
              ),
            const SizedBox(height: 24),
            const Text(
              'Détails par étape',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...QualityChainStep.values.map((step) {
              final metrics = lot.metricsByStep[step];
              if (metrics == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _StepMetricsCard(step: step, metrics: metrics),
              );
            }).where((widget) => widget is! SizedBox),
          ],
        ),
      ),
    );
  }
}

class _StepMetricsCard extends StatelessWidget {
  final QualityChainStep step;
  final QualityStepMetrics metrics;

  const _StepMetricsCard({
    required this.step,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stepIcon = step.icon;
    final statusColor =
        metrics.isConform ? Colors.green.shade600 : Colors.red.shade600;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(stepIcon, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StatusChip(status: metrics.conformityStatus),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (metrics.waterContent != null)
                _MetricChip(
                  icon: Icons.water_drop_outlined,
                  label: 'Eau',
                  value: '${metrics.waterContent!.toStringAsFixed(1)} %',
                  color: Colors.blue.shade100,
                ),
              if (metrics.residuePercent != null)
                _MetricChip(
                  icon: Icons.bug_report,
                  label: 'Résidus',
                  value: '${metrics.residuePercent!.toStringAsFixed(1)} %',
                  color: Colors.purple.shade100,
                ),
              if (metrics.pollenLostKg != null)
                _MetricChip(
                  icon: Icons.grain,
                  label: 'Pollen perdu',
                  value: '${metrics.pollenLostKg!.toStringAsFixed(2)} kg',
                  color: Colors.orange.shade100,
                ),
              _MetricChip(
                icon: Icons.local_florist,
                label: 'Odeur',
                value: metrics.odorProfile.label,
                color: Colors.green.shade100,
              ),
              _MetricChip(
                icon: Icons.layers,
                label: 'Dépôts',
                value: metrics.depositProfile.label,
                color: Colors.teal.shade100,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (metrics.controllerName != null &&
              metrics.controllerName!.trim().isNotEmpty)
            _MetricLine(
              icon: Icons.badge,
              label: 'Contrôleur',
              value: metrics.controllerName!,
            ),
          _MetricLine(
            icon: Icons.schedule,
            label: 'Dernière mise à jour',
            value:
                '${metrics.lastUpdated.day.toString().padLeft(2, '0')}/${metrics.lastUpdated.month.toString().padLeft(2, '0')}/${metrics.lastUpdated.year} ${metrics.lastUpdated.hour.toString().padLeft(2, '0')}h${metrics.lastUpdated.minute.toString().padLeft(2, '0')}',
          ),
          if (metrics.observation != null &&
              metrics.observation!.trim().isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: metrics.isConform
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                metrics.observation!,
                style: TextStyle(
                  color: statusColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ConformityStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isConform = status == ConformityStatus.conforme;
    final color = isConform ? Colors.green.shade100 : Colors.red.shade100;
    final textColor = isConform ? Colors.green.shade700 : Colors.red.shade700;
    final icon = isConform ? Icons.verified : Icons.error_outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 6),
          Text(
            QualityControlUtils.getConformityStatusLabel(status),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Simple composant de chargement scintillant utilisé pour les placeholders.
class ShimmerLoading extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius borderRadius;

  const ShimmerLoading({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.4 + (0.4 * _controller.value);
        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          color: Colors.grey.shade300,
        ),
      ),
    );
  }
}
