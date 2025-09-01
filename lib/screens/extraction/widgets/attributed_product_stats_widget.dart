/// Widget pour afficher les statistiques des produits attribués
import 'package:flutter/material.dart';
import '../models/attributed_product_models.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart';

class AttributedProductStatsWidget extends StatelessWidget {
  final AttributedProductStats stats;

  const AttributedProductStatsWidget({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Statistiques des Produits Attribués',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (isMobile) ...[
            _buildMobileStats(theme),
          ] else ...[
            _buildDesktopStats(theme),
          ],
        ],
      ),
    );
  }

  /// Statistiques pour mobile
  Widget _buildMobileStats(ThemeData theme) {
    return Column(
      children: [
        // Première ligne: Total et statuts
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Produits',
                stats.totalProduits.toString(),
                Icons.inventory_2,
                theme.colorScheme.primary,
                theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'En Attente',
                stats.enAttente.toString(),
                Icons.schedule,
                Colors.orange,
                theme,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Deuxième ligne: En cours et terminés
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'En Cours',
                stats.enCours.toString(),
                Icons.play_circle,
                Colors.blue,
                theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Terminés',
                stats.termines.toString(),
                Icons.check_circle,
                Colors.green,
                theme,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Poids - Ligne unique
        _buildWeightsSummary(theme),

        const SizedBox(height: 16),

        // Répartition par nature
        _buildNatureDistribution(theme),

        const SizedBox(height: 16),

        // Top 3 provenances
        _buildTopProvenances(theme, 3),
      ],
    );
  }

  /// Statistiques pour desktop
  Widget _buildDesktopStats(ThemeData theme) {
    return Column(
      children: [
        // Première ligne: Statuts
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Produits',
                stats.totalProduits.toString(),
                Icons.inventory_2,
                theme.colorScheme.primary,
                theme,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'En Attente',
                stats.enAttente.toString(),
                Icons.schedule,
                Colors.orange,
                theme,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'En Cours',
                stats.enCours.toString(),
                Icons.play_circle,
                Colors.blue,
                theme,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Terminés',
                stats.termines.toString(),
                Icons.check_circle,
                Colors.green,
                theme,
              ),
            ),
            if (stats.suspendus > 0) ...[
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Suspendus',
                  stats.suspendus.toString(),
                  Icons.pause_circle,
                  Colors.red,
                  theme,
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 20),

        // Deuxième ligne: Informations détaillées
        Row(
          children: [
            // Colonne 1: Poids
            Expanded(
              flex: 2,
              child: _buildWeightsSummary(theme),
            ),

            const SizedBox(width: 20),

            // Colonne 2: Répartition par nature
            Expanded(
              flex: 2,
              child: _buildNatureDistribution(theme),
            ),

            const SizedBox(width: 20),

            // Colonne 3: Top provenances
            Expanded(
              flex: 2,
              child: _buildTopProvenances(theme, 5),
            ),
          ],
        ),
      ],
    );
  }

  /// Card de statistique
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Résumé des poids
  Widget _buildWeightsSummary(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.scale,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Résumé des Poids',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Poids total
          _buildWeightRow(
            'Poids total:',
            '${stats.poidsTotal.toStringAsFixed(1)} kg',
            theme,
            bold: true,
          ),

          const SizedBox(height: 8),

          // Poids disponible
          _buildWeightRow(
            'Disponible:',
            '${stats.poidsDisponible.toStringAsFixed(1)} kg',
            theme,
            color: Colors.green,
          ),

          const SizedBox(height: 8),

          // Poids prélevé
          _buildWeightRow(
            'Prélevé:',
            '${stats.poidsPreleve.toStringAsFixed(1)} kg',
            theme,
            color: Colors.blue,
          ),

          const SizedBox(height: 12),

          // Barre de progression globale
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progression globale',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${stats.pourcentagePrelevementMoyen.toStringAsFixed(1)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: stats.pourcentagePrelevementMoyen / 100,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Ligne de poids
  Widget _buildWeightRow(
    String label,
    String value,
    ThemeData theme, {
    Color? color,
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color ?? theme.colorScheme.onSurface,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color ?? theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Répartition par nature
  Widget _buildNatureDistribution(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.category,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Par Nature',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...stats.parNature.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getNatureColor(entry.key),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key.label,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      entry.value.toString(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getNatureColor(entry.key),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  /// Top provenances
  Widget _buildTopProvenances(ThemeData theme, int maxItems) {
    final sortedProvenances = stats.parProvenance.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topProvenances = sortedProvenances.take(maxItems).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Top Provenances',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (topProvenances.isEmpty) ...[
            Text(
              'Aucune donnée',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else ...[
            ...topProvenances.asMap().entries.map((entry) {
              final index = entry.key;
              final provenance = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getPositionColor(index),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        provenance.key,
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      provenance.value.toString(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getPositionColor(index),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  /// Couleur selon la nature du produit
  Color _getNatureColor(ProductNature nature) {
    switch (nature) {
      case ProductNature.brut:
        return Colors.amber;
      case ProductNature.filtre:
        return Colors.blue;
      case ProductNature.cire:
        return Colors.orange;
    }
  }

  /// Couleur selon la position dans le classement
  Color _getPositionColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey[600]!;
      case 2:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }
}
