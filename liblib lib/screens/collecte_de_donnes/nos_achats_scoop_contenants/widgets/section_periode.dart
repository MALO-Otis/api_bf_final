import 'package:flutter/material.dart';
import '../../../../data/models/scoop_models.dart';

class SectionPeriode extends StatelessWidget {
  final String selectedPeriode;
  final Function(String) onPeriodeSelected;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  const SectionPeriode({
    super.key,
    required this.selectedPeriode,
    required this.onPeriodeSelected,
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
                child:
                    const Icon(Icons.schedule, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Période de collecte',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Sélectionnez une période prédéfinie pour cette collecte',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Sélection de période
          Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Période',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedPeriode.isEmpty ? null : selectedPeriode,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.calendar_today),
                      hintText: 'Choisir une période',
                    ),
                    items: PeriodesCollecte.periodes.map((periode) {
                      return DropdownMenuItem(
                        value: periode,
                        child: Text(periode),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        onPeriodeSelected(value);
                      }
                    },
                    validator: (value) =>
                        value == null ? 'Période requise' : null,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Aperçu de la période sélectionnée
          if (selectedPeriode.isNotEmpty) _buildPeriodePreview(),

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

  Widget _buildPeriodePreview() {
    return Card(
      elevation: 3,
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Période sélectionnée',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedPeriode,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getPeriodeDescription(selectedPeriode),
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPeriodeDescription(String periode) {
    switch (periode) {
      case 'La grande Miellé':
        return 'Période principale de récolte du miel - Production maximale';
      case 'La Petite miellée':
        return 'Période secondaire de récolte du miel - Production réduite';
      default:
        return 'Période de collecte sélectionnée';
    }
  }
}
