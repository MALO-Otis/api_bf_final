import 'package:flutter/material.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart';

/// 🎯 CARTE PRODUIT POUR ATTRIBUTION
///
/// Widget réutilisable pour afficher un produit disponible pour attribution
class AttributionCard extends StatelessWidget {
  final ProductControle produit;
  final Function(AttributionType) onAttribuer;
  final VoidCallback onDetails;

  const AttributionCard({
    Key? key,
    required this.produit,
    required this.onAttribuer,
    required this.onDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onDetails,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildProductInfo(),
              const SizedBox(height: 12),
              _buildQualityInfo(),
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Badge nature
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getNatureColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getNatureIcon(),
            color: _getNatureColor(),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),

        // Informations principales
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    produit.codeContenant,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (produit.isUrgent) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'URGENT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                produit.producteur,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // Badge conformité
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: produit.estConforme ? Colors.green[100] : Colors.red[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            produit.estConforme ? 'C' : 'NC',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: produit.estConforme ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildInfoRow('Village', produit.village),
          _buildInfoRow('Nature', produit.nature.label),
          _buildInfoRow(
              'Poids Miel', '${produit.poidsMiel.toStringAsFixed(2)} kg'),
          _buildInfoRow('Date Réception', _formatDate(produit.dateReception)),
        ],
      ),
    );
  }

  Widget _buildQualityInfo() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: produit.qualiteColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: produit.qualiteColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.star,
                  color: produit.qualiteColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  produit.qualite,
                  style: TextStyle(
                    color: produit.qualiteColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (produit.teneurEau != null)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'H₂O: ${produit.teneurEau!.toStringAsFixed(1)}%',
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Bouton détails
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDetails,
            icon: const Icon(Icons.info_outline, size: 16),
            label: const Text('Détails'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Bouton attribution principal
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () => onAttribuer(_getAttributionTypeForNature()),
            icon: Icon(_getNatureIcon(), size: 16),
            label: Text(_getAttributionLabel()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getNatureColor(),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthodes utilitaires
  Color _getNatureColor() {
    switch (produit.nature) {
      case ProductNature.brut:
        return Colors.brown;
      case ProductNature.liquide:
        return Colors.blue;
      case ProductNature.cire:
        return Colors.amber[700]!;
      case ProductNature.filtre:
        return Colors.green;
    }
  }

  IconData _getNatureIcon() {
    switch (produit.nature) {
      case ProductNature.brut:
        return Icons.science;
      case ProductNature.liquide:
        return Icons.water_drop;
      case ProductNature.cire:
        return Icons.spa;
      case ProductNature.filtre:
        return Icons.filter_alt;
    }
  }

  AttributionType _getAttributionTypeForNature() {
    switch (produit.nature) {
      case ProductNature.brut:
        return AttributionType.extraction;
      case ProductNature.liquide:
        return AttributionType.filtration;
      case ProductNature.cire:
        return AttributionType.traitementCire;
      case ProductNature.filtre:
        // Les produits déjà filtrés ne peuvent pas être attribués normalement
        return AttributionType.filtration;
    }
  }

  String _getAttributionLabel() {
    switch (produit.nature) {
      case ProductNature.brut:
        return 'Extraction';
      case ProductNature.liquide:
        return 'Filtrage';
      case ProductNature.cire:
        return 'Traiter Cire';
      case ProductNature.filtre:
        return 'Filtré';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
