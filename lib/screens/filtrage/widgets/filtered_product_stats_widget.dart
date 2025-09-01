import 'package:flutter/material.dart';
import '../models/filtered_product_models.dart';

/// Widget d'affichage des statistiques des produits filtrés
class FilteredProductStatsWidget extends StatelessWidget {
  final FilteredProductStats stats;

  const FilteredProductStatsWidget({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      margin: EdgeInsets.all(isMobile ? 8 : 16),
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: theme.colorScheme.primary,
                size: isMobile ? 20 : 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Statistiques des Produits Filtrés',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  fontSize: isMobile ? 18 : 20,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Grille de stats responsive
          LayoutBuilder(
            builder: (context, constraints) {
              int columns;
              double cardAspectRatio;

              if (constraints.maxWidth < 600) {
                columns = 2; // Mobile: 2 colonnes
                cardAspectRatio = 1.4;
              } else if (constraints.maxWidth < 900) {
                columns = 3; // Tablette: 3 colonnes
                cardAspectRatio = 1.3;
              } else if (constraints.maxWidth < 1200) {
                columns = 4; // Desktop: 4 colonnes
                cardAspectRatio = 1.2;
              } else {
                columns = 5; // Grand écran: 5 colonnes
                cardAspectRatio = 1.1;
              }

              final statCards = [
                _buildStatCard(
                  'Total Produits',
                  stats.totalProduits.toString(),
                  Icons.inventory_2,
                  Colors.blue,
                  theme,
                ),
                _buildStatCard(
                  'En Attente',
                  stats.enAttente.toString(),
                  Icons.schedule,
                  Colors.orange,
                  theme,
                ),
                _buildStatCard(
                  'En Cours',
                  stats.enCours.toString(),
                  Icons.hourglass_bottom,
                  Colors.amber,
                  theme,
                ),
                _buildStatCard(
                  'Terminés',
                  stats.termines.toString(),
                  Icons.check_circle,
                  Colors.green,
                  theme,
                ),
                _buildStatCard(
                  'Suspendus',
                  stats.suspendus.toString(),
                  Icons.pause_circle,
                  Colors.red,
                  theme,
                ),
              ];

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: cardAspectRatio,
                ),
                itemCount: statCards.length,
                itemBuilder: (context, index) => statCards[index],
              );
            },
          ),

          const SizedBox(height: 16),

          // Résumé des poids et origine
          _buildSummarySection(theme, isMobile),

          const SizedBox(height: 16),

          // Sections par origine
          Row(
            children: [
              Expanded(
                child: _buildOriginSection(
                  'Produits du Contrôle',
                  stats.origineDuControle,
                  Icons.verified_user,
                  Colors.teal,
                  theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOriginSection(
                  'Produits de l\'Extraction',
                  stats.origineDeLExtraction,
                  Icons.science,
                  Colors.purple,
                  theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construit une carte de statistique
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Section résumé des poids
  Widget _buildSummarySection(ThemeData theme, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Résumé des Poids',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          if (isMobile)
            Column(
              children: [
                _buildWeightInfo('Poids Total Original', stats.poidsTotal, 'kg',
                    Icons.scale, theme),
                const SizedBox(height: 8),
                _buildWeightInfo('Poids Filtré', stats.poidsFiltre, 'kg',
                    Icons.water_drop, theme),
                const SizedBox(height: 8),
                _buildWeightInfo('Rendement Global', stats.rendementGlobal, '%',
                    Icons.trending_up, theme),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildWeightInfo('Poids Total Original',
                      stats.poidsTotal, 'kg', Icons.scale, theme),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildWeightInfo('Poids Filtré', stats.poidsFiltre,
                      'kg', Icons.water_drop, theme),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildWeightInfo('Rendement Global',
                      stats.rendementGlobal, '%', Icons.trending_up, theme),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Information de poids
  Widget _buildWeightInfo(
      String label, double value, String unit, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${value.toStringAsFixed(unit == '%' ? 1 : 2)} $unit',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Section par origine
  Widget _buildOriginSection(
    String title,
    int count,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    final percentage = stats.totalProduits > 0
        ? (count / stats.totalProduits * 100).toStringAsFixed(1)
        : '0.0';

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
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$count produits',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$percentage%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

