import 'package:flutter/material.dart';

class SectionPredominanceFlorale extends StatelessWidget {
  final List<String> predominancesFloralesSelectionnees;
  final Function(String, bool) onPredominanceChanged;

  const SectionPredominanceFlorale({
    Key? key,
    required this.predominancesFloralesSelectionnees,
    required this.onPredominanceChanged,
  }) : super(key: key);

  static const List<String> _predominancesFlorales = [
    'Acacia',
    'Eucalyptus',
    'Karité',
    'Néré',
    'Baobab',
    'Manguier',
    'Citronnier',
    'Tamarinier',
    'Kapokier',
    'Fleurs sauvages',
    'Autre',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre de la section
            Row(
              children: [
                Icon(
                  Icons.local_florist,
                  color: theme.primaryColor,
                  size: isSmallScreen ? 20 : 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Prédominance florale',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),

            Text(
              'Sélectionnez les origines florales du miel collecté (plusieurs choix possibles) :',
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),

            // Grille des prédominances florales
            Wrap(
              spacing: isSmallScreen ? 4 : 8,
              runSpacing: isSmallScreen ? 4 : 8,
              children: _predominancesFlorales.map((predominance) {
                final isSelected =
                    predominancesFloralesSelectionnees.contains(predominance);
                return FilterChip(
                  label: Text(
                    predominance,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13,
                      color: isSelected ? Colors.white : theme.primaryColor,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    onPredominanceChanged(predominance, selected);
                  },
                  selectedColor: theme.primaryColor,
                  checkmarkColor: Colors.white,
                  backgroundColor: Colors.grey[100],
                  side: BorderSide(
                    color: isSelected ? theme.primaryColor : Colors.grey[300]!,
                  ),
                );
              }).toList(),
            ),

            // Affichage du nombre de sélections
            if (predominancesFloralesSelectionnees.isNotEmpty) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${predominancesFloralesSelectionnees.length} origine(s) sélectionnée(s)',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 13,
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
