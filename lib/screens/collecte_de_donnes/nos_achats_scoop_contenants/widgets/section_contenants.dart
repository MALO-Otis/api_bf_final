import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/models/scoop_models.dart';
import 'modal_contenant.dart';

class SectionContenants extends StatelessWidget {
  final List<ContenantScoopModel> contenants;
  final Function(List<ContenantScoopModel>) onContenantsChanged;
  final Map<String, double> totals;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  const SectionContenants({
    super.key,
    required this.contenants,
    required this.onContenantsChanged,
    required this.totals,
    this.onNext,
    this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.inventory_2,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contenants',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Ajoutez des contenants de miel (Bidon/Pot) et calculez automatiquement les totaux',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Résumé des totaux
          Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTotalItem(
                      'Poids total',
                      '${totals['poids']?.toStringAsFixed(2)} kg',
                      Icons.scale,
                      Colors.blue,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.amber.shade300,
                  ),
                  Expanded(
                    child: _buildTotalItem(
                      'Montant total',
                      '${totals['montant']?.toStringAsFixed(2)} CFA',
                      Icons.text_fields,
                      Colors.green,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.amber.shade300,
                  ),
                  Expanded(
                    child: _buildTotalItem(
                      'Contenants',
                      '${contenants.length}',
                      Icons.inventory,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Bouton d'ajout et liste des contenants
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Liste des contenants',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showAddContenantModal(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter un contenant'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Liste des contenants
                  contenants.isEmpty
                      ? _buildEmptyState()
                      : Column(
                          children: contenants.asMap().entries.map((entry) {
                            final index = entry.key;
                            final contenant = entry.value;
                            return _buildContenantCard(
                                context, contenant, index);
                          }).toList(),
                        ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Boutons de navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: onPrevious,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour'),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
              ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Continuer',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTotalItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Builder(
      builder: (context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun contenant ajouté',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des contenants pour continuer',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddContenantModal(context),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter le premier contenant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenantsList() {
    return ListView.builder(
      itemCount: contenants.length,
      itemBuilder: (context, index) {
        final contenant = contenants[index];
        return _buildContenantCard(context, contenant, index);
      },
    );
  }

  Widget _buildContenantCard(
      BuildContext context, ContenantScoopModel contenant, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Icône du type de contenant
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: contenant.typeContenant == ContenantType.bidon
                    ? Colors.blue.shade100
                    : Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                contenant.typeContenant == ContenantType.bidon
                    ? Icons.water_drop
                    : Icons.local_drink,
                color: contenant.typeContenant == ContenantType.bidon
                    ? Colors.blue.shade700
                    : Colors.green.shade700,
                size: 20,
              ),
            ),

            const SizedBox(width: 16),

            // Informations du contenant
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          contenant.typeContenant.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          contenant.typeMiel.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${contenant.poids} kg',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${contenant.prix} CFA',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  if (contenant.notes?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      contenant.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () =>
                      _showEditContenantModal(context, contenant, index),
                  icon: const Icon(Icons.edit),
                  tooltip: 'Modifier',
                  color: Colors.blue.shade600,
                ),
                IconButton(
                  onPressed: () => _deleteContenant(index),
                  icon: const Icon(Icons.delete),
                  tooltip: 'Supprimer',
                  color: Colors.red.shade600,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddContenantModal(BuildContext context) async {
    final contenant = await showDialog<ContenantScoopModel>(
      context: context,
      builder: (context) => const ModalContenant(),
    );

    if (contenant != null) {
      final nouveauContenant = contenant.copyWith(
        id: 'C${(contenants.length + 1).toString().padLeft(3, '0')}_scoop',
      );
      final nouveauxContenants = [...contenants, nouveauContenant];
      onContenantsChanged(nouveauxContenants);
    }
  }

  void _showEditContenantModal(
      BuildContext context, ContenantScoopModel contenant, int index) async {
    final contenantModifie = await showDialog<ContenantScoopModel>(
      context: context,
      builder: (context) => ModalContenant(contenant: contenant),
    );

    if (contenantModifie != null) {
      final nouveauxContenants = [...contenants];
      nouveauxContenants[index] = contenantModifie;
      onContenantsChanged(nouveauxContenants);
    }
  }

  void _deleteContenant(int index) {
    final nouveauxContenants = [...contenants];
    nouveauxContenants.removeAt(index);
    onContenantsChanged(nouveauxContenants);
  }
}
