import 'package:flutter/material.dart';
import '../models/filtered_product_models.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart';

/// Carte d'affichage d'un produit attribué au filtrage
class FilteredProductCard extends StatelessWidget {
  final FilteredProduct product;
  final VoidCallback? onTap;
  final VoidCallback? onRefresh;

  const FilteredProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(
        vertical: isMobile ? 4 : 8,
        horizontal: isMobile ? 0 : 8,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // En-tête avec producteur et statut
              _buildHeader(theme, isMobile),

              const SizedBox(height: 12),

              // Informations principales
              _buildMainInfo(theme, isMobile),

              const SizedBox(height: 12),

              // Détails techniques
              _buildTechnicalDetails(theme, isMobile),

              const SizedBox(height: 12),

              // Origine et attribution
              _buildOriginAndAttribution(theme, isMobile),

              if (onTap != null) ...[
                const SizedBox(height: 12),
                _buildActionButton(theme, isMobile),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Construit l'en-tête de la carte
  Widget _buildHeader(ThemeData theme, bool isMobile) {
    return Row(
      children: [
        // Icône du type de collecte
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getCollecteTypeColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCollecteTypeIcon(),
            color: _getCollecteTypeColor(),
            size: isMobile ? 20 : 24,
          ),
        ),

        const SizedBox(width: 12),

        // Producteur et code contenant
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.producteur,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 14 : 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                product.codeContenant,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontFamily: 'monospace',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Badge de statut
        _buildStatusBadge(theme),
      ],
    );
  }

  /// Badge de statut
  Widget _buildStatusBadge(ThemeData theme) {
    Color statusColor;
    IconData statusIcon;

    switch (product.statut) {
      case FilteredProductStatus.enAttente:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case FilteredProductStatus.enCoursTraitement:
        statusColor = Colors.blue;
        statusIcon = Icons.hourglass_bottom;
        break;
      case FilteredProductStatus.termine:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case FilteredProductStatus.suspendu:
        statusColor = Colors.red;
        statusIcon = Icons.pause_circle;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 14, color: statusColor),
          const SizedBox(width: 4),
          Text(
            product.statut.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Informations principales
  Widget _buildMainInfo(ThemeData theme, bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: _buildCompactInfoItem(
            'Village',
            product.village,
            Icons.location_on,
            theme,
          ),
        ),
        Expanded(
          child: _buildCompactInfoItem(
            'Poids Original',
            '${product.poidsOriginal.toStringAsFixed(2)} kg',
            Icons.scale,
            theme,
          ),
        ),
        if (product.poidsFiltre != null)
          Expanded(
            child: _buildCompactInfoItem(
              'Poids Filtré',
              '${product.poidsFiltre!.toStringAsFixed(2)} kg',
              Icons.water_drop,
              theme,
            ),
          ),
      ],
    );
  }

  /// Détails techniques
  Widget _buildTechnicalDetails(ThemeData theme, bool isMobile) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildChip(
          product.nature.label,
          _getNatureColor(),
          Icons.category,
        ),
        _buildChip(
          product.qualite,
          Colors.amber,
          Icons.star,
        ),
        _buildChip(
          product.typeContenant,
          Colors.grey,
          Icons.inventory_2,
        ),
        if (product.teneurEau != null)
          _buildChip(
            '${product.teneurEau!.toStringAsFixed(1)}% eau',
            Colors.blue,
            Icons.opacity,
          ),
      ],
    );
  }

  /// Origine et attribution
  Widget _buildOriginAndAttribution(ThemeData theme, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Origine
        Row(
          children: [
            Icon(
              product.estOrigineDuControle
                  ? Icons.verified_user
                  : Icons.science,
              size: 16,
              color: product.estOrigineDuControle ? Colors.teal : Colors.purple,
            ),
            const SizedBox(width: 4),
            Text(
              product.origineDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color:
                    product.estOrigineDuControle ? Colors.teal : Colors.purple,
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // Attribution
        Row(
          children: [
            Icon(
              Icons.person,
              size: 16,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            Text(
              'Attribué par ${product.attributeur}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDate(product.dateAttribution),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),

        // Dates de filtrage si disponibles
        if (product.dateDebutFiltrage != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.play_arrow,
                size: 16,
                color: Colors.blue,
              ),
              const SizedBox(width: 4),
              Text(
                'Débuté le ${_formatDate(product.dateDebutFiltrage!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],

        if (product.dateFinFiltrage != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.check,
                size: 16,
                color: Colors.green,
              ),
              const SizedBox(width: 4),
              Text(
                'Terminé le ${_formatDate(product.dateFinFiltrage!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (product.dureeFiltrage != null) ...[
                const SizedBox(width: 8),
                Text(
                  '(${_formatDuration(product.dureeFiltrage!)})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  /// Bouton d'action
  Widget _buildActionButton(ThemeData theme, bool isMobile) {
    String buttonText;
    IconData buttonIcon;
    Color buttonColor;

    switch (product.statut) {
      case FilteredProductStatus.enAttente:
        buttonText = 'Commencer le filtrage';
        buttonIcon = Icons.play_arrow;
        buttonColor = Colors.blue;
        break;
      case FilteredProductStatus.enCoursTraitement:
        buttonText = 'Continuer le filtrage';
        buttonIcon = Icons.hourglass_bottom;
        buttonColor = Colors.orange;
        break;
      case FilteredProductStatus.termine:
        buttonText = 'Voir les détails';
        buttonIcon = Icons.visibility;
        buttonColor = Colors.green;
        break;
      case FilteredProductStatus.suspendu:
        buttonText = 'Reprendre le filtrage';
        buttonIcon = Icons.play_arrow;
        buttonColor = Colors.red;
        break;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(buttonIcon, size: 18),
        label: Text(buttonText),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  /// Item d'information compact
  Widget _buildCompactInfoItem(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
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
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
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

  /// Chip d'information
  Widget _buildChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Couleur selon le type de collecte
  Color _getCollecteTypeColor() {
    switch (product.typeCollecte.toLowerCase()) {
      case 'recolte':
        return Colors.green;
      case 'individuel':
        return Colors.blue;
      case 'scoop':
        return Colors.orange;
      case 'miellerie':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Icône selon le type de collecte
  IconData _getCollecteTypeIcon() {
    switch (product.typeCollecte.toLowerCase()) {
      case 'recolte':
        return Icons.agriculture;
      case 'individuel':
        return Icons.person;
      case 'scoop':
        return Icons.groups;
      case 'miellerie':
        return Icons.factory;
      default:
        return Icons.inventory;
    }
  }

  /// Couleur selon la nature du produit
  Color _getNatureColor() {
    switch (product.nature) {
      case ProductNature.brut:
        return Colors.amber;
      case ProductNature.filtre:
        return Colors.blue;
      case ProductNature.cire:
        return Colors.brown;
    }
  }

  /// Formate une date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Formate une durée
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}j ${duration.inHours.remainder(24)}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}min';
    } else {
      return '${duration.inMinutes}min';
    }
  }
}
