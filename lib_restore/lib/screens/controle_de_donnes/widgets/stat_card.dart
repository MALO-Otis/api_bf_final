// Widget de carte statistique
import 'package:flutter/material.dart';

/// Énumération des tons de couleur pour les cartes statistiques
enum StatCardTone { primary, success, warning, danger, info }

/// Widget de carte statistique
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  final IconData? icon;
  final StatCardTone tone;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.subValue,
    this.icon,
    this.tone = StatCardTone.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Couleurs selon le ton
    Color effectiveColor;
    Color backgroundColor;
    switch (tone) {
      case StatCardTone.primary:
        effectiveColor = theme.colorScheme.primary;
        backgroundColor = theme.colorScheme.primaryContainer.withOpacity(0.1);
        break;
      case StatCardTone.success:
        effectiveColor = Colors.green.shade600;
        backgroundColor = Colors.green.shade50;
        break;
      case StatCardTone.warning:
        effectiveColor = Colors.orange.shade600;
        backgroundColor = Colors.orange.shade50;
        break;
      case StatCardTone.danger:
        effectiveColor = Colors.red.shade600;
        backgroundColor = Colors.red.shade50;
        break;
      case StatCardTone.info:
        effectiveColor = Colors.blue.shade600;
        backgroundColor = Colors.blue.shade50;
        break;
    }

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: backgroundColor,
        ),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label avec icône optionnelle
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Valeur
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: effectiveColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),

              // Sous-valeur optionnelle
              if (subValue != null) ...[
                const SizedBox(height: 2),
                Text(
                  subValue!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget simplifié pour les mini-statistiques
class StatMini extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? color;

  const StatMini({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surface,
      ),
      child: IntrinsicHeight(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label avec icône
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 14,
                    color: effectiveColor,
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Valeur
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: effectiveColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget de grille de statistiques responsive
class StatsGrid extends StatelessWidget {
  final List<StatCard> stats;
  final int crossAxisCount;
  final double childAspectRatio;

  const StatsGrid({
    super.key,
    required this.stats,
    this.crossAxisCount = 4,
    this.childAspectRatio = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Détermine le nombre de colonnes selon la largeur disponible
        int columns;
        if (constraints.maxWidth < 600) {
          columns = 2; // Mobile : 2 colonnes
        } else if (constraints.maxWidth < 900) {
          columns = 3; // Tablette : 3 colonnes
        } else {
          columns = crossAxisCount; // Desktop : nombre configuré
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) => stats[index],
        );
      },
    );
  }
}

/// Widget de statistiques en ligne pour les détails
class StatsRow extends StatelessWidget {
  final List<StatMini> stats;
  final MainAxisAlignment alignment;

  const StatsRow({
    super.key,
    required this.stats,
    this.alignment = MainAxisAlignment.spaceEvenly,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // En mobile, affiche en colonne si plus de 3 stats
        if (constraints.maxWidth < 600 && stats.length > 3) {
          return Column(
            children: stats
                .map((stat) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: stat,
                    ))
                .toList(),
          );
        }

        // Sinon affiche en ligne avec gestion de l'overflow
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: IntrinsicWidth(
            child: Row(
              mainAxisAlignment: alignment,
              mainAxisSize: MainAxisSize.min,
              children: stats
                  .map((stat) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: stat,
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}
