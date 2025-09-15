// Widget de carte de collecte
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/collecte_models.dart';
import '../models/attribution_models_v2.dart';

import '../utils/formatters.dart';
import 'quality_control_indicator.dart';

class CollecteCard extends StatelessWidget {
  final Section section;
  final BaseCollecte item;
  final bool canEdit;
  final VoidCallback? onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(AttributionType)? onAttribution;
  final bool isCompact;

  const CollecteCard({
    super.key,
    required this.section,
    required this.item,
    this.canEdit = false,
    this.onOpen,
    this.onEdit,
    this.onDelete,
    this.onAttribution,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isVerySmall = screenWidth < 360;

    final title = Formatters.getTitleForCollecte(section, item);
    final subtitle = Formatters.getSubtitleForCollecte(item);
    final chips = Formatters.getChipsForCollecte(section, item);
    final sectionLabel = Formatters.getSectionLabel(section);

    // Couleurs selon la section
    Color badgeColor;
    Color badgeTextColor;
    switch (section) {
      case Section.recoltes:
        badgeColor = Colors.green.shade100;
        badgeTextColor = Colors.green.shade800;
        break;
      case Section.scoop:
        badgeColor = Colors.blue.shade100;
        badgeTextColor = Colors.blue.shade800;
        break;
      case Section.individuel:
        badgeColor = Colors.orange.shade100;
        badgeTextColor = Colors.orange.shade800;
        break;
      case Section.miellerie:
        badgeColor = Colors.purple.shade100;
        badgeTextColor = Colors.purple.shade800;
        break;
    }

    // Adaptation responsive automatique
    final adaptiveIsCompact = isCompact || isMobile;
    final adaptivePadding = isVerySmall ? 8.0 : (isMobile ? 12.0 : 16.0);

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(adaptivePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec badge et actions
              Row(
                children: [
                  // Badge de section - plus compact sur mobile
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 6 : 8,
                      vertical: isMobile ? 3 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                    ),
                    child: Text(
                      sectionLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: badgeTextColor,
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 10 : null,
                      ),
                    ),
                  ),

                  // Indicateur de contrôle qualité
                  QualityControlIndicator(
                    collecte: item,
                    showDetails: !isMobile,
                  ),

                  const Spacer(),

                  // Actions pour desktop seulement
                  if (!adaptiveIsCompact) _buildDesktopActions(context, theme),
                ],
              ),

              SizedBox(height: isMobile ? 8 : 12),

              // Titre et sous-titre - adaptation mobile
              if (isMobile) ...[
                // Sur mobile, titre + statut en haut, puis sous-titre
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    if (item.statut != null) ...[
                      const SizedBox(width: 8),
                      _buildStatutBadge(theme, compact: true),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ] else ...[
                // Layout desktop original
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (item.statut != null) _buildStatutBadge(theme),
                  ],
                ),
              ],

              SizedBox(height: isMobile ? 10 : 16),

              // Métriques - adaptation responsive
              _buildResponsiveMetrics(theme, isMobile, isVerySmall),

              // Chips d'information - adaptation mobile
              if (chips.isNotEmpty) ...[
                SizedBox(height: isMobile ? 8 : 12),
                _buildResponsiveChips(context,
                    chips.map((text) => {'text': text}).toList(), isMobile),
              ],

              // Actions pour mobile
              if (adaptiveIsCompact) ...[
                SizedBox(height: isMobile ? 8 : 12),
                _buildMobileActions(context, theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopActions(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onOpen != null)
          OutlinedButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.visibility, size: 16),
            label: const Text('Détails'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: theme.textTheme.labelMedium,
            ),
          ),
        if (onAttribution != null) ...[
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => onAttribution!(AttributionType.extraction),
            icon: const Icon(Icons.science, size: 16),
            label: const Text('Attribuer à Extraction'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => onAttribution!(AttributionType.filtration),
            icon: const Icon(Icons.filter_alt, size: 16),
            label: const Text('Attribuer à Filtration'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
        if (canEdit && onEdit != null) ...[
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Modifier'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: theme.textTheme.labelMedium,
            ),
          ),
        ],
        const SizedBox(width: 8),
        _buildMoreMenu(context),
      ],
    );
  }

  Widget _buildMobileActions(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            if (onOpen != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Détails'),
                ),
              ),
            const SizedBox(width: 8),
            _buildMoreMenu(context),
          ],
        ),
        if (onAttribution != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onAttribution!(AttributionType.extraction),
                  icon: const Icon(Icons.science, size: 14),
                  label: const Text('Extraction'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onAttribution!(AttributionType.filtration),
                  icon: const Icon(Icons.filter_alt, size: 14),
                  label: const Text('Filtration'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMoreMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      tooltip: 'Plus d\'actions',
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'copy_id',
          child: Row(
            children: const [
              Icon(Icons.copy, size: 16),
              SizedBox(width: 12),
              Text('Copier ID'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'copy_path',
          child: Row(
            children: const [
              Icon(Icons.link, size: 16),
              SizedBox(width: 12),
              Text('Copier chemin'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'export_pdf',
          child: Row(
            children: const [
              Icon(Icons.picture_as_pdf, size: 16),
              SizedBox(width: 12),
              Text('Exporter PDF'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'export_csv',
          child: Row(
            children: const [
              Icon(Icons.table_chart, size: 16),
              SizedBox(width: 12),
              Text('Exporter CSV'),
            ],
          ),
        ),
        if (canEdit && onEdit != null) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: const [
                Icon(Icons.edit, size: 16),
                SizedBox(width: 12),
                Text('Modifier'),
              ],
            ),
          ),
        ],
        if (canEdit && onDelete != null)
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete,
                    size: 16, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 12),
                Text(
                  'Supprimer',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ),
          ),
      ],
      onSelected: (value) => _handleMenuAction(context, value),
    );
  }

  void _handleMenuAction(BuildContext context, String action) async {
    switch (action) {
      case 'copy_id':
        await Clipboard.setData(ClipboardData(text: item.id));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ID copié dans le presse-papiers')),
          );
        }
        break;
      case 'copy_path':
        await Clipboard.setData(ClipboardData(text: item.path));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Chemin copié dans le presse-papiers')),
          );
        }
        break;
      case 'export_pdf':
        _showNotImplemented(context, 'Export PDF');
        break;
      case 'export_csv':
        _exportCsv();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export CSV généré')),
          );
        }
        break;
      case 'edit':
        onEdit?.call();
        break;
      case 'delete':
        _showDeleteConfirmation(context);
        break;
    }
  }

  void _showNotImplemented(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature sera bientôt disponible')),
    );
  }

  void _exportCsv() {
    final headers = Formatters.getCsvHeaders();
    final data = Formatters.prepareCollecteForCsv(section, item);
    final rows = [headers, data];
    final csv = Formatters.toCsv(rows);

    // Dans un vrai cas d'usage, on sauvegarderait le fichier
    // Ici on simule juste l'action
    print('CSV généré: $csv');
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette collecte ? '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete?.call();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatutBadge(ThemeData theme, {bool compact = false}) {
    final statutColor = Formatters.getStatutColor(item.statut);
    final statutLabel = Formatters.formatStatut(item.statut);

    Color backgroundColor;
    Color textColor;

    switch (statutColor) {
      case 'green':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case 'orange':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case 'blue':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        break;
      default:
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 6,
        vertical: compact ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
      ),
      child: Text(
        statutLabel,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: compact ? 10 : null,
        ),
      ),
    );
  }

  Widget _buildMetrics(ThemeData theme) {
    return IntrinsicHeight(
      child: Row(
        children: [
          _buildMetric(
            theme,
            'Poids total',
            Formatters.formatKg(item.totalWeight),
            Icons.scale,
          ),
          _buildDivider(theme),
          _buildMetric(
            theme,
            'Montant total',
            Formatters.formatFCFA(item.totalAmount),
            Icons.attach_money,
          ),
          _buildDivider(theme),
          _buildMetric(
            theme,
            '#contenants',
            Formatters.formatNumber(item.containersCount),
            Icons.inventory_2,
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(
      ThemeData theme, String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: theme.colorScheme.outline.withValues(alpha: 0.2),
    );
  }

  Widget _buildChips(BuildContext context, List<String> chips) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: chips
          .take(3)
          .map(
            (chip) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                chip,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  // Nouvelles fonctions responsive
  Widget _buildResponsiveMetrics(
      ThemeData theme, bool isMobile, bool isVerySmall) {
    if (isMobile) {
      // Sur mobile, afficher les métriques en colonnes 2x2 ou 1x3 selon la taille
      if (isVerySmall) {
        // Très petits écrans : format vertical compact
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildCompactMetric(
                    theme,
                    'Poids',
                    Formatters.formatKg(item.totalWeight),
                    Icons.scale,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCompactMetric(
                    theme,
                    'Montant',
                    Formatters.formatFCFA(item.totalAmount),
                    Icons.attach_money,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildCompactMetric(
                    theme,
                    'Contenants',
                    '${_getContainerCount(item)}',
                    Icons.inventory_2,
                  ),
                ),
                const Expanded(child: SizedBox()), // Spacer pour équilibrer
              ],
            ),
          ],
        );
      } else {
        // Écrans mobiles moyens : une ligne avec 3 colonnes
        return Row(
          children: [
            Expanded(
              child: _buildCompactMetric(
                theme,
                'Poids',
                Formatters.formatKg(item.totalWeight),
                Icons.scale,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCompactMetric(
                theme,
                'Montant',
                Formatters.formatFCFA(item.totalAmount),
                Icons.attach_money,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCompactMetric(
                theme,
                'Contenants',
                '${_getContainerCount(item)}',
                Icons.inventory_2,
              ),
            ),
            const SizedBox(width: 8),
            // Indicateur de contrôle en mode compact pour mobile
            QualityControlIndicator(
              collecte: item,
              showDetails: false,
            ),
          ],
        );
      }
    } else {
      // Desktop : utiliser l'affichage original
      return _buildMetrics(theme);
    }
  }

  Widget _buildCompactMetric(
      ThemeData theme, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveChips(
      BuildContext context, List<Map<String, String>> chips, bool isMobile) {
    if (isMobile) {
      // Sur mobile, limiter à 2 chips max et les rendre plus compacts
      final displayChips = chips.take(2).toList();
      return Wrap(
        spacing: 4,
        runSpacing: 4,
        children: displayChips.map((chip) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              chip['text'] ?? '',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          );
        }).toList(),
      );
    } else {
      // Desktop : convertir vers le format attendu pour la fonction originale
      final stringChips = chips.map((chip) => chip['text'] ?? '').toList();
      return _buildChips(context, stringChips);
    }
  }

  // Méthode helper pour obtenir le nombre de contenants
  int _getContainerCount(BaseCollecte item) {
    if (item is Recolte) {
      return item.contenants.length;
    } else if (item is Scoop) {
      return item.contenants.length;
    } else if (item is Individuel) {
      return item.contenants.length;
    }
    return 0;
  }
}

/// Widget de squelette pour le chargement
class CollecteCardSkeleton extends StatelessWidget {
  const CollecteCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 60,
                  height: 20,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 80,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Titre
            Container(
              width: double.infinity,
              height: 20,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            const SizedBox(height: 8),

            // Sous-titre
            Container(
              width: 200,
              height: 16,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            const SizedBox(height: 16),

            // Métriques
            Row(
              children: List.generate(
                3,
                (index) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index < 2 ? 12 : 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 12,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 40,
                          height: 16,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
