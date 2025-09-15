import 'package:flutter/material.dart';
import '../../../../data/models/collecte_models.dart';

/// Widget simple pour afficher un contenant (sans édition in-line)
class ContenantCard extends StatelessWidget {
  final int index;
  final ContenantModel contenant;
  final VoidCallback? onSupprimer;
  final Function(ContenantModel) onContenantModified;

  const ContenantCard({
    Key? key,
    required this.index,
    required this.contenant,
    this.onSupprimer,
    required this.onContenantModified,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final montantTotal = contenant.quantite * contenant.prixUnitaire;

    return Card(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
      ),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec numéro et bouton supprimer
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Contenant ${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                  ),
                ),
                const Spacer(),
                if (onSupprimer != null)
                  IconButton(
                    onPressed: onSupprimer,
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade400,
                      size: isSmallScreen ? 20 : 24,
                    ),
                    tooltip: 'Supprimer ce contenant',
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Informations du contenant avec badges
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoBadge(
                  contenant.typeMiel,
                  Colors.blue,
                  Icons.water_drop,
                ),
                _buildInfoBadge(
                  contenant.typeContenant,
                  Colors.amber,
                  Icons.inventory,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Détails numériques
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDetailItem(
                        'Poids',
                        '${contenant.quantite} kg',
                        Icons.scale,
                      ),
                      _buildDetailItem(
                        'Prix unitaire',
                        '${contenant.prixUnitaire.toStringAsFixed(0)} CFA/kg',
                        Icons.monetization_on,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calculate,
                          color: Colors.green.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Montant total: ${montantTotal.toStringAsFixed(0)} CFA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                            fontSize: isSmallScreen ? 13 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Notes si présentes
            if (contenant.note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note,
                      color: Colors.blue.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        contenant.note,
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
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

  Widget _buildInfoBadge(String text, MaterialColor color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color.shade700,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Colors.grey.shade600,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
