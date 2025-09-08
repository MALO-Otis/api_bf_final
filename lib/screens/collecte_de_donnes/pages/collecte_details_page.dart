/// Page de détails moderne pour les collectes avec codes de localisation intégrés
import 'package:flutter/material.dart';

import '../widgets/collecte_details_card.dart';

class CollecteDetailsPage extends StatelessWidget {
  final Map<String, dynamic> collecteData;
  final String type; // 'Récoltes', 'SCOOP', 'Individuel'

  const CollecteDetailsPage({
    super.key,
    required this.collecteData,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Détails - $type'),
        backgroundColor: _getTypeColor(type),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareDetails(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _getTypeColor(type).withOpacity(0.1),
              Colors.transparent,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Card principale avec toutes les informations
              CollecteDetailsCard(
                collecteData: collecteData,
                type: type,
                onEdit: () => _editCollecte(context),
                onDelete: () => _deleteCollecte(context),
              ),

              // Section contenants si présents
              if (collecteData['contenants'] != null)
                _buildContenantsSection(context, theme),

              // Section historique si applicable
              _buildHistoriqueSection(context, theme),

              // Espace en bas
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-collecte-details-edit',
        onPressed: () => _editCollecte(context),
        backgroundColor: _getTypeColor(type),
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text(
          'Modifier',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildContenantsSection(BuildContext context, ThemeData theme) {
    final contenants = collecteData['contenants'] as List?;
    if (contenants == null || contenants.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.inventory_2,
                  color: _getTypeColor(type),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Contenants (${contenants.length})',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getTypeColor(type),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Liste des contenants
            ...contenants.asMap().entries.map((entry) {
              final index = entry.key;
              final contenant = entry.value;
              return _buildContenantCard(context, theme, contenant, index + 1);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildContenantCard(BuildContext context, ThemeData theme,
      Map<String, dynamic> contenant, int numero) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getTypeColor(type).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getTypeColor(type).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTypeColor(type),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Contenant $numero',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              if (contenant['type_ruche'] != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    contenant['type_ruche'].toString(),
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Informations du contenant
          Row(
            children: [
              Expanded(
                child: _buildContenantInfo(
                  'Poids',
                  '${contenant['quantite_kg'] ?? 0} kg',
                  Icons.scale,
                  theme,
                ),
              ),
              Expanded(
                child: _buildContenantInfo(
                  'Prix unitaire',
                  '${contenant['prix_unitaire'] ?? 0} FCFA',
                  Icons.attach_money,
                  theme,
                ),
              ),
            ],
          ),

          if (contenant['origine_florale'] != null) ...[
            const SizedBox(height: 8),
            _buildContenantInfo(
              'Origine florale',
              contenant['origine_florale'].toString(),
              Icons.local_florist,
              theme,
            ),
          ],

          if (contenant['note'] != null &&
              contenant['note'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.note, color: Colors.grey.shade600, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      contenant['note'].toString(),
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContenantInfo(
      String label, String value, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 14),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoriqueSection(BuildContext context, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: Colors.grey.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Historique',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Timeline des modifications
            _buildTimelineItem(
              'Collecte créée',
              collecteData['date_creation']?.toString() ?? 'Date inconnue',
              Icons.add_circle,
              Colors.green,
              theme,
            ),

            if (collecteData['date_modification'] != null)
              _buildTimelineItem(
                'Dernière modification',
                collecteData['date_modification'].toString(),
                Icons.edit,
                Colors.blue,
                theme,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
      String title, String date, IconData icon, Color color, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  date,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'SCOOP':
        return Colors.blue;
      case 'Récoltes':
        return Colors.green;
      case 'Individuel':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _editCollecte(BuildContext context) {
    // Navigation vers la page d'édition
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Édition de la collecte - Fonctionnalité à implémenter'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _deleteCollecte(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la collecte'),
        content: const Text(
            'Êtes-vous sûr de vouloir supprimer cette collecte ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Suppression - Fonctionnalité à implémenter'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _shareDetails(BuildContext context) {
    // Fonctionnalité de partage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Partage des détails - Fonctionnalité à implémenter'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
