/// Card pour afficher un produit attribué
import 'package:flutter/material.dart';
import '../models/attributed_product_models.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart';

class AttributedProductCard extends StatelessWidget {
  final AttributedProduct product;
  final VoidCallback? onPrelevementTap;
  final VoidCallback? onDetailsTap;

  const AttributedProductCard({
    super.key,
    required this.product,
    this.onPrelevementTap,
    this.onDetailsTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onDetailsTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec code et statut
              Row(
                children: [
                  // Icône de nature
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getNatureColor(product.nature)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getNatureIcon(product.nature),
                      color: _getNatureColor(product.nature),
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Code contenant
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.codeContenant,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          product.nature.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getNatureColor(product.nature),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Statut
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(product.statut)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(product.statut)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(product.statut),
                          color: _getStatusColor(product.statut),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.statut.label,
                          style: TextStyle(
                            color: _getStatusColor(product.statut),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Informations principales
              if (isMobile) ...[
                _buildMobileLayout(theme),
              ] else ...[
                _buildDesktopLayout(theme),
              ],

              const SizedBox(height: 16),

              // Barre de progression des prélèvements
              _buildProgressBar(theme),

              const SizedBox(height: 16),

              // Actions
              _buildActions(theme, isMobile),
            ],
          ),
        ),
      ),
    );
  }

  /// Layout mobile
  Widget _buildMobileLayout(ThemeData theme) {
    return Column(
      children: [
        // Ligne 1: Producteur et village
        Row(
          children: [
            Icon(
              Icons.person,
              color: theme.colorScheme.outline,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                product.producteur,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Ligne 2: Localisation
        Row(
          children: [
            Icon(
              Icons.location_on,
              color: theme.colorScheme.outline,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                product.codeLocalisation,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Ligne 3: Poids et dates
        Row(
          children: [
            Expanded(
              child: _buildInfoChip(
                Icons.scale,
                '${product.poidsDisponible.toStringAsFixed(1)} kg',
                'Disponible',
                theme,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildInfoChip(
                Icons.calendar_today,
                _formatDateShort(product.dateAttribution),
                'Attribué',
                theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Layout desktop
  Widget _buildDesktopLayout(ThemeData theme) {
    return Row(
      children: [
        // Colonne 1: Producteur et localisation
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person,
                    color: theme.colorScheme.outline,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      product.producteur,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: theme.colorScheme.outline,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    product.codeLocalisation,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Colonne 2: Poids
        Expanded(
          child: _buildInfoChip(
            Icons.scale,
            '${product.poidsDisponible.toStringAsFixed(1)} kg',
            'Disponible',
            theme,
          ),
        ),

        // Colonne 3: Date attribution
        Expanded(
          child: _buildInfoChip(
            Icons.calendar_today,
            _formatDateShort(product.dateAttribution),
            'Attribué',
            theme,
          ),
        ),

        // Colonne 4: Attributeur
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Attribué par',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              Text(
                product.attributeur
                    .split(' ')
                    .take(2)
                    .join(' '), // Prénom + Nom
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construit un chip d'information
  Widget _buildInfoChip(
    IconData icon,
    String value,
    String label,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 16,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Construit la barre de progression
  Widget _buildProgressBar(ThemeData theme) {
    final progression = product.pourcentagePrelevementTotal / 100;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progression des prélèvements',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${product.pourcentagePrelevementTotal.toStringAsFixed(1)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: progression >= 1.0
                    ? Colors.green
                    : theme.colorScheme.primary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progression,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              progression >= 1.0 ? Colors.green : theme.colorScheme.primary,
            ),
            minHeight: 6,
          ),
        ),

        const SizedBox(height: 8),

        // Détails des poids
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Original: ${product.poidsOriginal.toStringAsFixed(1)} kg',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            if (product.poidsResidus > 0.01)
              Text(
                'Prélevé: ${product.poidsResidus.toStringAsFixed(1)} kg',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            Text(
              'Reste: ${product.poidsDisponible.toStringAsFixed(1)} kg',
              style: theme.textTheme.bodySmall?.copyWith(
                color: product.poidsDisponible > 0.01
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Construit les actions
  Widget _buildActions(ThemeData theme, bool isMobile) {
    return Row(
      children: [
        // Historique des prélèvements
        if (product.prelevements.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.history,
                  color: theme.colorScheme.secondary,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${product.prelevements.length} prélèvement${product.prelevements.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: theme.colorScheme.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],

        const Spacer(),

        // Bouton prélèvement
        if (product.poidsDisponible > 0.01 && !product.aPrelevementEnCours) ...[
          ElevatedButton.icon(
            onPressed: onPrelevementTap,
            icon: const Icon(Icons.science, size: 16),
            label: Text(isMobile ? 'Prélever' : 'Nouveau Prélèvement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: 8,
              ),
            ),
          ),
        ],

        // Indicateur prélèvement en cours
        if (product.aPrelevementEnCours) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'En cours d\'extraction',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Indicateur produit complètement prélevé
        if (product.estCompletePreleve) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'Complètement prélevé',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Couleur selon la nature du produit
  Color _getNatureColor(ProductNature nature) {
    switch (nature) {
      case ProductNature.brut:
        return Colors.amber;
      case ProductNature.liquide:
        return Colors.lightBlue;
      case ProductNature.filtre:
        return Colors.blue;
      case ProductNature.cire:
        return Colors.orange;
    }
  }

  /// Icône selon la nature du produit
  IconData _getNatureIcon(ProductNature nature) {
    switch (nature) {
      case ProductNature.brut:
        return Icons.water_drop;
      case ProductNature.liquide:
        return Icons.opacity;
      case ProductNature.filtre:
        return Icons.filter_alt;
      case ProductNature.cire:
        return Icons.texture;
    }
  }

  /// Couleur selon le statut
  Color _getStatusColor(PrelevementStatus statut) {
    switch (statut) {
      case PrelevementStatus.enAttente:
        return Colors.orange;
      case PrelevementStatus.enCours:
        return Colors.blue;
      case PrelevementStatus.termine:
        return Colors.green;
      case PrelevementStatus.suspendu:
        return Colors.red;
    }
  }

  /// Icône selon le statut
  IconData _getStatusIcon(PrelevementStatus statut) {
    switch (statut) {
      case PrelevementStatus.enAttente:
        return Icons.schedule;
      case PrelevementStatus.enCours:
        return Icons.play_circle;
      case PrelevementStatus.termine:
        return Icons.check_circle;
      case PrelevementStatus.suspendu:
        return Icons.pause_circle;
    }
  }

  /// Formate une date en format court
  String _formatDateShort(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
