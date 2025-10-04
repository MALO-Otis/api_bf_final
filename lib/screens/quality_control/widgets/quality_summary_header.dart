import 'package:flutter/material.dart';
import '../models/quality_chain_models.dart';

class QualitySummaryHeader extends StatelessWidget {
  final QualitySummaryMetrics? metrics;
  final bool isLoading;

  const QualitySummaryHeader({
    super.key,
    required this.metrics,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _SummarySkeleton();
    }

    if (metrics == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.orange.shade50,
          border: Border.all(color: Colors.orange.shade100),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade500),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Commencez un contrôle pour afficher les indicateurs du module.',
                style: TextStyle(
                  color: Colors.orange.shade900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final data = _summaryTiles(metrics!);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final columns = maxWidth > 1200
            ? 4
            : maxWidth > 920
                ? 3
                : maxWidth > 680
                    ? 2
                    : 1;
        final itemWidth = (maxWidth - ((columns - 1) * 16)) / columns;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: data
              .map((tile) => SizedBox(
                    width: columns == 1 ? maxWidth : itemWidth,
                    child: _SummaryTile(info: tile),
                  ))
              .toList(),
        );
      },
    );
  }

  List<_SummaryInfo> _summaryTiles(QualitySummaryMetrics metrics) {
    final conformityRate = metrics.conformityRate * 100;
    return [
      _SummaryInfo(
        title: 'Lots contrôlés',
        value: metrics.totalLots.toString(),
        icon: Icons.inventory_2,
        accentColor: Colors.blue.shade600,
        subtitle:
            '${metrics.conformLots} conformes • ${metrics.nonConformLots} non conformes',
      ),
      _SummaryInfo(
        title: 'Taux de conformité',
        value: '${conformityRate.toStringAsFixed(1)} %',
        icon: Icons.verified_rounded,
        accentColor: Colors.green.shade600,
        progress: conformityRate.clamp(0, 100) / 100,
        subtitle: 'Objectif: ≥ 92 %',
      ),
      _SummaryInfo(
        title: 'Teneur moyenne en eau',
        value: '${metrics.averageWaterContent.toStringAsFixed(1)} %',
        icon: Icons.water_drop,
        accentColor: Colors.cyan.shade600,
        subtitle: 'Seuil critique: 19 %',
      ),
      _SummaryInfo(
        title: 'Pollen perdu',
        value: '${metrics.totalPollenLostKg.toStringAsFixed(2)} kg',
        icon: Icons.grass,
        accentColor: Colors.orange.shade600,
        subtitle:
            'Résidus moyens: ${metrics.averageResiduePercent.toStringAsFixed(1)} %',
      ),
    ];
  }
}

class _SummaryInfo {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String? subtitle;
  final double? progress;

  const _SummaryInfo({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.subtitle,
    this.progress,
  });
}

class _SummaryTile extends StatelessWidget {
  final _SummaryInfo info;

  const _SummaryTile({required this.info});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 10),
            blurRadius: 30,
            color: Colors.black.withValues(alpha: 0.04),
          ),
        ],
        border: Border.all(
          color: info.accentColor.withValues(alpha: 0.18),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: info.accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(info.icon, color: info.accentColor, size: 26),
          ),
          const SizedBox(height: 18),
          Text(
            info.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            info.value,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (info.subtitle != null) ...[
            const SizedBox(height: 10),
            Text(
              info.subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
          if (info.progress != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: info.progress!.clamp(0, 1),
                minHeight: 8,
                backgroundColor: info.accentColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(info.accentColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final columns = maxWidth > 1200
            ? 4
            : maxWidth > 920
                ? 3
                : maxWidth > 680
                    ? 2
                    : 1;
        final itemWidth = (maxWidth - ((columns - 1) * 16)) / columns;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: List.generate(columns, (index) {
            return Container(
              width: columns == 1 ? maxWidth : itemWidth,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }),
        );
      },
    );
  }
}
