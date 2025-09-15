import 'package:flutter/material.dart';
import '../../../../data/models/scoop_models.dart';

class SectionResume extends StatelessWidget {
  final ScoopModel? scoop;
  final String periode;
  final List<ContenantScoopModel> contenants;
  final String observations;
  final Map<String, double> totals;
  final bool isLoading;
  final VoidCallback onSave;
  final VoidCallback? onPrevious;

  const SectionResume({
    super.key,
    required this.scoop,
    required this.periode,
    required this.contenants,
    required this.observations,
    required this.totals,
    required this.isLoading,
    required this.onSave,
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
                child:
                    const Icon(Icons.summarize, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Résumé',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Vérifiez toutes les informations avant enregistrement',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Contenu du résumé
          _buildScoopCard(),

          const SizedBox(height: 16),

          _buildPeriodeCard(),

          const SizedBox(height: 16),

          _buildContenantsCard(),

          const SizedBox(height: 16),

          _buildTotauxCard(),

          const SizedBox(height: 16),

          _buildObservationsCard(),

          const SizedBox(height: 24),

          // Boutons d'action
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
              ElevatedButton.icon(
                onPressed: isLoading ? null : onSave,
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(isLoading
                    ? 'Enregistrement...'
                    : 'Confirmer et enregistrer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildScoopCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'SCOOP',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (scoop != null) ...[
              Text(
                scoop!.nom,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Président: ${scoop!.president}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 2),
              Text(
                'Tél: ${scoop!.telephone}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Code localisation: ${scoop!.codeLocalisation}',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Zone: ${scoop!.localisation}',
                    style: TextStyle(color: Colors.grey.shade700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  _buildInfoChip('${scoop!.nbMembres} membres', Icons.group),
                  _buildInfoChip(
                      '${scoop!.nbRuchesTrad + scoop!.nbRuchesModernes} ruches',
                      Icons.hive),
                ],
              ),
            ] else ...[
              Text(
                'Aucun SCOOP sélectionné',
                style: TextStyle(
                    color: Colors.red.shade600, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodeCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.orange.shade600, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Période',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (periode.isNotEmpty) ...[
              Text(
                periode,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ] else ...[
              Text(
                'Aucune période sélectionnée',
                style: TextStyle(
                    color: Colors.red.shade600, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContenantsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Contenants (${contenants.length})',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (contenants.isEmpty) ...[
              Text(
                'Aucun contenant ajouté',
                style: TextStyle(
                    color: Colors.red.shade600, fontStyle: FontStyle.italic),
              ),
            ] else ...[
              ...contenants.map((contenant) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            contenant.typeContenant.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            contenant.typeMiel.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${contenant.poids} kg',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${contenant.prix} CFA',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.green.shade700,
                          ),
                        ),
                        if (contenant.notes?.isNotEmpty == true) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '— ${contenant.notes}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTotauxCard() {
    return Card(
      elevation: 2,
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate, color: Colors.amber.shade700, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Totaux',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTotalItem(
                    'Poids total',
                    '${totals['poids']?.toStringAsFixed(2)} kg',
                    Icons.scale,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildTotalItem(
                    'Montant total',
                    '${totals['montant']?.toStringAsFixed(2)} CFA',
                    Icons.text_fields,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTotalItem(
                    'Bidons',
                    '${contenants.where((c) => c.typeContenant == ContenantType.bidon).length}',
                    Icons.water_drop,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildTotalItem(
                    'Fûts',
                    '${contenants.where((c) => c.typeContenant == ContenantType.seau).length}',
                    Icons.local_drink,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObservationsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note_alt, color: Colors.purple.shade600, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Observations',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              observations.isEmpty ? 'Aucune observation' : observations,
              style: TextStyle(
                color: observations.isEmpty
                    ? Colors.grey.shade500
                    : Colors.black87,
                fontStyle:
                    observations.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
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

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.blue.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
