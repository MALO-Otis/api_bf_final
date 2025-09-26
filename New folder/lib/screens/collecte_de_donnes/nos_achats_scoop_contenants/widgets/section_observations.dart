import 'package:flutter/material.dart';

class SectionObservations extends StatelessWidget {
  final String observations;
  final Function(String) onObservationsChanged;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  const SectionObservations({
    super.key,
    required this.observations,
    required this.onObservationsChanged,
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
                    const Icon(Icons.note_alt, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Observations',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Ajoutez des remarques ou informations complémentaires',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Zone de texte
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
                    'Notes et observations',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: observations,
                    onChanged: onObservationsChanged,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      hintText:
                          'Ajoutez vos observations, remarques ou informations complémentaires...',
                      prefixIcon: const Icon(Icons.edit_note),
                    ),
                    maxLines: 6,
                    maxLength: 500,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Exemples d'observations
          Card(
            elevation: 2,
            color: Colors.blue.shade50,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb,
                          color: Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Exemples d\'observations',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Qualité exceptionnelle du miel de karité\n'
                    '• Collecte effectuée après la période de pluie\n'
                    '• SCOOP très organisé, respect des standards\n'
                    '• Miel cristallisé, conservation optimale\n'
                    '• Transport effectué dans de bonnes conditions',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Boutons de navigation (responsives)
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 420;
              final back = TextButton.icon(
                onPressed: onPrevious,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour'),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              );
              final next = ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
              );
              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(alignment: Alignment.centerLeft, child: back),
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerRight, child: next),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [back, next],
              );
            },
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
