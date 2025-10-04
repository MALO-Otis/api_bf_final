import '../models/quality_vocab.dart';
import 'package:flutter/material.dart';
import '../models/quality_chain_models.dart';
import '../../controle_de_donnes/models/quality_control_models.dart';

class QualityLotCollection extends StatelessWidget {
  final List<QualityLotSnapshot> lots;
  final ValueChanged<QualityLotSnapshot> onLotSelected;
  final bool isLoading;

  const QualityLotCollection({
    super.key,
    required this.lots,
    required this.onLotSelected,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Lots filtrés (${lots.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 12),
            if (isLoading)
              SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
            const Spacer(),
            Text(
              'Cliquez sur un lot pour consulter les détails complets',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final columns = maxWidth > 1260
                ? 3
                : maxWidth > 820
                    ? 2
                    : 1;
            final itemWidth = (maxWidth - ((columns - 1) * 18)) / columns;

            return Wrap(
              spacing: 18,
              runSpacing: 18,
              children: lots
                  .map(
                    (lot) => SizedBox(
                      width: columns == 1 ? maxWidth : itemWidth,
                      child: _LotCard(
                        lot: lot,
                        onTap: () => onLotSelected(lot),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _LotCard extends StatelessWidget {
  final QualityLotSnapshot lot;
  final VoidCallback onTap;

  const _LotCard({required this.lot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = lot.overallStatus();
    final isConform = status == ConformityStatus.conforme;
    final latestWater = lot.latestWaterContent;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: (isConform ? Colors.green : Colors.red)
                  .withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, 14),
                blurRadius: 30,
                color: Colors.black.withValues(alpha: 0.05),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color:
                          isConform ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.inventory,
                      color: isConform
                          ? Colors.green.shade600
                          : Colors.red.shade600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lot.lotCode,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lot.productType,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(lot.referenceDate),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  QualityStatusChip(status: status),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (latestWater != null)
                    _MetricBadge(
                      icon: Icons.water_drop,
                      label: '${latestWater.toStringAsFixed(1)} % eau',
                      color: Colors.blue.shade100,
                      textColor: Colors.blue.shade800,
                    ),
                  _MetricBadge(
                    icon: Icons.numbers,
                    label: '${lot.metricsByStep.length} étapes contrôlées',
                    color: Colors.grey.shade200,
                    textColor: Colors.grey.shade700,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _StepOverview(metricsByStep: lot.metricsByStep),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return 'Référence: $day/$month/$year';
  }
}

class _StepOverview extends StatelessWidget {
  final Map<QualityChainStep, QualityStepMetrics> metricsByStep;

  const _StepOverview({required this.metricsByStep});

  @override
  Widget build(BuildContext context) {
    final orderedSteps = QualityChainStep.values
        .where((step) => metricsByStep.containsKey(step))
        .toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: orderedSteps.map((step) {
        final metrics = metricsByStep[step]!;
        final isConform = metrics.isConform;
        final color = isConform ? Colors.green.shade50 : Colors.red.shade50;
        final borderColor =
            isConform ? Colors.green.shade200 : Colors.red.shade200;
        final iconColor =
            isConform ? Colors.green.shade600 : Colors.red.shade600;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(step.icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                step.label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;

  const _MetricBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
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
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
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

class QualityStatusChip extends StatelessWidget {
  final ConformityStatus status;

  const QualityStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isConform = status == ConformityStatus.conforme;
    final bgColor = isConform ? Colors.green.shade100 : Colors.red.shade100;
    final textColor = isConform ? Colors.green.shade800 : Colors.red.shade800;
    final icon = isConform ? Icons.verified : Icons.error_outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: textColor),
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
