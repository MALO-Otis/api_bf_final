import 'package:flutter/material.dart';

import '../models/filtrage_models.dart';

/// Widget de carte pour afficher un produit de filtrage
class FiltrageCard extends StatelessWidget {
  final FiltrageProduct product;
  final VoidCallback onTap;
  final VoidCallback onStartFiltrage;
  final VoidCallback onAssign;

  const FiltrageCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onStartFiltrage,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getBorderColor(),
          width: product.isUrgent ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildDetails(),
              const SizedBox(height: 12),
              _buildStatus(),
              const SizedBox(height: 16),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Badge de priorité
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getPriorityColor(),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getPriorityIcon(),
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                _getPriorityLabel(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Code contenant
        Expanded(
          child: Text(
            product.codeContenant,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),

        // Badge de type
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getTypeColor(),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _getTypeLabel(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetails() {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.person, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                product.producteur,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              product.village,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.scale, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              '${product.poids.toStringAsFixed(1)} kg',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.deepOrange,
              ),
            ),
            const SizedBox(width: 16),
            Icon(Icons.water_drop, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              '${(product.teneurEau ?? 0).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              _getAgeLabel(),
              style: TextStyle(
                fontSize: 14,
                color: product.isUrgent
                    ? Colors.red.shade600
                    : Colors.grey.shade600,
                fontWeight:
                    product.isUrgent ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${product.statutFiltrage.emoji} ${product.statutFiltrage.label}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _getStatusColor(),
            ),
          ),
          if (product.agentFiltrage != null) ...[
            const SizedBox(width: 12),
            Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                product.agentFiltrage!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        if (product.peutEtreFiltrer) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onAssign,
              icon: const Icon(Icons.person_add, size: 16),
              label: const Text('Attribuer'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onStartFiltrage,
              icon: const Icon(Icons.play_arrow, size: 16),
              label: const Text('Filtrer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ] else ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('Voir détails'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
                side: BorderSide(color: Colors.grey.shade400),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _getBorderColor() {
    if (product.isUrgent) return Colors.red.shade400;

    switch (product.statutFiltrage) {
      case StatutFiltrage.en_cours:
        return Colors.orange.shade400;
      case StatutFiltrage.termine:
        return Colors.green.shade400;
      case StatutFiltrage.probleme:
        return Colors.red.shade400;
      default:
        return Colors.grey.shade300;
    }
  }

  Color _getPriorityColor() {
    switch (product.priorite) {
      case 1:
        return Colors.red.shade600; // Haute
      case 2:
        return Colors.orange.shade600; // Normale
      case 3:
        return Colors.green.shade600; // Basse
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getPriorityIcon() {
    switch (product.priorite) {
      case 1:
        return Icons.priority_high;
      case 2:
        return Icons.remove;
      case 3:
        return Icons.keyboard_arrow_down;
      default:
        return Icons.help;
    }
  }

  String _getPriorityLabel() {
    switch (product.priorite) {
      case 1:
        return 'URGENT';
      case 2:
        return 'NORMAL';
      case 3:
        return 'FAIBLE';
      default:
        return 'INCONNUE';
    }
  }

  Color _getTypeColor() {
    switch (product.typeCollecte) {
      case 'recoltes':
        return Colors.green.shade600;
      case 'scoop':
        return Colors.blue.shade600;
      case 'individuel':
        return Colors.purple.shade600;
      case 'miellerie':
        return Colors.amber.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _getTypeLabel() {
    switch (product.typeCollecte) {
      case 'recoltes':
        return 'RÉCOLTE';
      case 'scoop':
        return 'SCOOP';
      case 'individuel':
        return 'INDIVIDUEL';
      case 'miellerie':
        return 'MIELLERIE';
      default:
        return product.typeCollecte.toUpperCase();
    }
  }

  Color _getStatusColor() {
    switch (product.statutFiltrage) {
      case StatutFiltrage.en_attente:
        return Colors.grey.shade600;
      case StatutFiltrage.en_cours:
        return Colors.orange.shade600;
      case StatutFiltrage.termine:
        return Colors.green.shade600;
      case StatutFiltrage.probleme:
        return Colors.red.shade600;
    }
  }

  String _getAgeLabel() {
    final age = product.ageDepuisReception;

    if (age.inDays > 0) {
      return '${age.inDays}j';
    } else if (age.inHours > 0) {
      return '${age.inHours}h';
    } else {
      return '${age.inMinutes}min';
    }
  }
}
