import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attribution_models.dart';
import '../models/extraction_models.dart';

/// Carte d'affichage d'une attribution
class AttributionCard extends StatelessWidget {
  final AttributionExtraction attribution;
  final List<ExtractionProduct> extractionProducts;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  const AttributionCard({
    super.key,
    required this.attribution,
    required this.extractionProducts,
    this.onEdit,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              _getStatusColor().withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec statut
              _buildHeader(),
              const SizedBox(height: 12),

              // Informations principales
              _buildMainInfo(),
              const SizedBox(height: 12),

              // Contenants
              _buildContenantsInfo(isMobile),
              const SizedBox(height: 12),

              // Métadonnées et commentaires
              if (attribution.commentaires?.isNotEmpty == true ||
                  attribution.metadata.isNotEmpty) ...[
                _buildMetadata(),
                const SizedBox(height: 12),
              ],

              // Actions
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit le header avec le statut
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            attribution.statut.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Lot ${attribution.lotId}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              DateFormat('dd/MM/yyyy HH:mm')
                  .format(attribution.dateAttribution),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Construit les informations principales
  Widget _buildMainInfo() {
    return Row(
      children: [
        Icon(
          Icons.person,
          color: Colors.blue.shade600,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                attribution.utilisateur,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              if (attribution.dateModification != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Modifié le ${DateFormat('dd/MM HH:mm').format(attribution.dateModification!)}',
                  style: TextStyle(
                    color: Colors.orange.shade600,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (attribution.utilisateurModification != null)
                  Text(
                    'par ${attribution.utilisateurModification}',
                    style: TextStyle(
                      color: Colors.orange.shade600,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Construit les informations sur les contenants
  Widget _buildContenantsInfo(bool isMobile) {
    final contenants = _getContenantsInfo();
    final totalPoids =
        contenants.fold<double>(0, (sum, c) => sum + c.poidsTotal);
    final totalContenants = contenants.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.inventory_2,
                color: Colors.green.shade600,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '$totalContenants contenant(s) - ${totalPoids.toStringAsFixed(1)} kg',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (!isMobile && contenants.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: contenants
                  .take(3)
                  .map((contenant) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getProductTypeColor(contenant.type)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getProductTypeColor(contenant.type)
                                .withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          '${contenant.type.label} - ${contenant.poidsTotal.toStringAsFixed(1)}kg',
                          style: TextStyle(
                            color: _getProductTypeColor(contenant.type),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ))
                  .toList(),
            ),
            if (contenants.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '... et ${contenants.length - 3} autre(s)',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// Construit les métadonnées
  Widget _buildMetadata() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (attribution.commentaires?.isNotEmpty == true) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.comment,
                color: Colors.grey.shade600,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  attribution.commentaires!,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        if (attribution.metadata.isNotEmpty) ...[
          if (attribution.commentaires?.isNotEmpty == true)
            const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: attribution.metadata.entries
                .take(2)
                .map((entry) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${entry.key}: ${entry.value}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 10,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  /// Construit les actions
  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (attribution.peutEtreModifiee) ...[
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Modifier'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue.shade600,
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (attribution.peutEtreAnnulee) ...[
          TextButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.cancel, size: 16),
            label: const Text('Annuler'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade600,
            ),
          ),
        ],
      ],
    );
  }

  /// Récupère les informations des contenants
  List<ExtractionProduct> _getContenantsInfo() {
    return extractionProducts
        .where((product) => attribution.listeContenants.contains(product.id))
        .toList();
  }

  /// Récupère la couleur du statut
  Color _getStatusColor() {
    switch (attribution.statut) {
      case AttributionStatus.attribueExtraction:
        return Colors.blue;
      case AttributionStatus.enCoursExtraction:
        return Colors.orange;
      case AttributionStatus.extraitEnAttente:
        return Colors.purple;
      case AttributionStatus.attribueMaturation:
        return Colors.teal;
      case AttributionStatus.enCoursMaturation:
        return Colors.indigo;
      case AttributionStatus.termineMaturation:
        return Colors.green;
      case AttributionStatus.annule:
        return Colors.red;
    }
  }

  /// Récupère la couleur du type de produit
  Color _getProductTypeColor(ProductType type) {
    switch (type) {
      case ProductType.mielBrut:
        return Colors.amber.shade600;
      case ProductType.mielCristallise:
        return Colors.yellow.shade700;
      case ProductType.propolis:
        return Colors.brown.shade600;
      case ProductType.cire:
        return Colors.orange.shade600;
    }
  }
}
