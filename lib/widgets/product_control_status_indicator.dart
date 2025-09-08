/// Widget d'indicateur de statut de contrôle des produits
import 'package:flutter/material.dart';
import '../screens/controle_de_donnes/models/attribution_models_v2.dart';
import '../services/product_control_status_service.dart';

class ProductControlStatusIndicator extends StatelessWidget {
  final ProductControle product;
  final bool showDetails;
  final VoidCallback? onTap;

  const ProductControlStatusIndicator({
    super.key,
    required this.product,
    this.showDetails = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusService = ProductControlStatusService();
    final status = statusService.getControlStatus(product.statutControle);
    final canBeAttributed = statusService.canBeAttributed(product);

    if (showDetails) {
      return _buildDetailedIndicator(context, status, canBeAttributed);
    } else {
      return _buildSimpleIndicator(context, status, canBeAttributed);
    }
  }

  Widget _buildSimpleIndicator(
    BuildContext context,
    ProductControlStatus status,
    bool canBeAttributed,
  ) {
    Color color;
    IconData icon;

    if (!product.estControle) {
      color = Colors.red;
      icon = Icons.error;
    } else if (!product.estConforme) {
      color = Colors.orange;
      icon = Icons.warning;
    } else if (canBeAttributed) {
      color = Colors.green;
      icon = Icons.check_circle;
    } else {
      color = Colors.grey;
      icon = Icons.help_outline;
    }

    Widget indicator = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            _getShortStatusText(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: indicator,
      );
    }

    return indicator;
  }

  Widget _buildDetailedIndicator(
    BuildContext context,
    ProductControlStatus status,
    bool canBeAttributed,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assignment_turned_in,
                  color: theme.primaryColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Statut de Contrôle',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildStatusChip(
                  'Contrôlé',
                  product.estControle,
                  product.estControle ? Colors.green : Colors.red,
                ),
                if (product.estControle)
                  _buildStatusChip(
                    'Conforme',
                    product.estConforme,
                    product.estConforme ? Colors.blue : Colors.orange,
                  ),
                _buildStatusChip(
                  'Attribuable',
                  canBeAttributed,
                  canBeAttributed ? Colors.purple : Colors.grey,
                ),
              ],
            ),
            if (product.statutControle != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getStatusColor(status).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  status.label,
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            if (!product.estConforme && product.causeNonConformite != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      color: Colors.orange,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        product.causeNonConformite!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, bool value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: value ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: value ? 0.3 : 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            value ? Icons.check : Icons.close,
            color: color.withValues(alpha: value ? 1.0 : 0.5),
            size: 12,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: value ? 1.0 : 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getShortStatusText() {
    if (!product.estControle) {
      return 'NON CONTRÔLÉ';
    } else if (!product.estConforme) {
      return 'NON CONFORME';
    } else if (product.estAttribue) {
      return 'ATTRIBUÉ';
    } else {
      return 'DISPONIBLE';
    }
  }

  Color _getStatusColor(ProductControlStatus status) {
    switch (status) {
      case ProductControlStatus.nonControle:
        return Colors.red;
      case ProductControlStatus.enAttente:
        return Colors.orange;
      case ProductControlStatus.enCours:
        return Colors.blue;
      case ProductControlStatus.termine:
        return Colors.teal;
      case ProductControlStatus.valide:
        return Colors.green;
      case ProductControlStatus.refuse:
      case ProductControlStatus.nonConforme:
        return Colors.red;
    }
  }
}

/// Widget d'alerte pour les produits non contrôlés
class ProductControlAlert extends StatelessWidget {
  final List<ProductControle> products;
  final VoidCallback? onViewDetails;

  const ProductControlAlert({
    super.key,
    required this.products,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final statusService = ProductControlStatusService();
    final stats = statusService.getControlStatistics(products);

    final totalProducts = stats['total_products'] as int;
    final withIssues = stats['with_issues'] as int;
    final healthPercentage = stats['health_percentage'] as double;

    if (totalProducts == 0 || withIssues == 0) {
      return const SizedBox.shrink();
    }

    Color alertColor;
    IconData alertIcon;
    String alertTitle;

    if (healthPercentage < 50) {
      alertColor = Colors.red;
      alertIcon = Icons.error;
      alertTitle = 'Problèmes Critiques Détectés';
    } else if (healthPercentage < 80) {
      alertColor = Colors.orange;
      alertIcon = Icons.warning;
      alertTitle = 'Avertissements Détectés';
    } else {
      alertColor = Colors.amber;
      alertIcon = Icons.info;
      alertTitle = 'Attention Requise';
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: alertColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(alertIcon, color: alertColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alertTitle,
                          style: TextStyle(
                            color: alertColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '$withIssues/$totalProducts produits nécessitent une attention',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onViewDetails != null)
                    TextButton(
                      onPressed: onViewDetails,
                      child: const Text('Voir Détails'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: healthPercentage / 100,
                backgroundColor: alertColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(alertColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Santé du système: ${healthPercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
