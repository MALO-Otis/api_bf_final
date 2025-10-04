import 'package:flutter/material.dart';

class SectionAppartenance extends StatelessWidget {
  final String appartenanceSelectionnee;
  final String nomCooperative;
  final Function(String) onAppartenanceChanged;
  final Function(String) onNomCooperativeChanged;

  const SectionAppartenance({
    Key? key,
    required this.appartenanceSelectionnee,
    required this.nomCooperative,
    required this.onAppartenanceChanged,
    required this.onNomCooperativeChanged,
  }) : super(key: key);

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
                  Icons.business,
                  color: theme.primaryColor,
                  size: isSmallScreen ? 20 : 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Appartenance',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),

            // Sélection de l'appartenance
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Type d\'appartenance *',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: Text(
                          'Propre',
                          style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                        ),
                        value: 'Propre',
                        groupValue: appartenanceSelectionnee,
                        onChanged: (value) {
                          if (value != null) {
                            onAppartenanceChanged(value);
                          }
                        },
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: Text(
                          'Coopérative',
                          style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                        ),
                        value: 'Coopérative',
                        groupValue: appartenanceSelectionnee,
                        onChanged: (value) {
                          if (value != null) {
                            onAppartenanceChanged(value);
                          }
                        },
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Champ nom de coopérative (affiché seulement si Coopérative est sélectionné)
            if (appartenanceSelectionnee == 'Coopérative') ...[
              SizedBox(height: 16),
              TextFormField(
                initialValue: nomCooperative,
                decoration: InputDecoration(
                  labelText: 'Nom de la coopérative *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group),
                ),
                onChanged: onNomCooperativeChanged,
                validator: (value) {
                  if (appartenanceSelectionnee == 'Coopérative' &&
                      (value == null || value.isEmpty)) {
                    return 'Veuillez saisir le nom de la coopérative';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
