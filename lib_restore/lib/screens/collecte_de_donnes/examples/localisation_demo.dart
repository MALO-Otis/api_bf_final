/// Démonstration de l'utilisation des widgets de localisation avec codes
import 'package:flutter/material.dart';
import '../widgets/localisation_code_widget.dart';
import '../pages/collecte_details_page.dart';

class LocalisationDemoPage extends StatelessWidget {
  const LocalisationDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Démonstration Codes de Localisation'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exemples d\'affichage des codes de localisation',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),

            // Exemple 1: Localisation complète
            Text(
              '1. Localisation complète (Boucle du Mouhoun)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            LocalisationCodeWidget(
              localisation: const {
                'region': 'Boucle du Mouhoun',
                'province': 'Balé',
                'commune': 'Boromo',
                'village': 'BAKARIDJAN',
              },
              accentColor: Colors.green,
            ),

            const SizedBox(height: 20),

            // Exemple 2: Localisation partielle
            Text(
              '2. Localisation partielle (Centre)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            LocalisationCodeWidget(
              localisation: const {
                'region': 'Centre',
                'province': 'Kadiogo',
                'commune': '',
                'village': '',
              },
              accentColor: Colors.blue,
              compact: true,
            ),

            const SizedBox(height: 20),

            // Exemple 3: Version compacte en ligne
            Text(
              '3. Version compacte en ligne',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 8),
                  const Text('Producteur: '),
                  const Expanded(
                    child: LocalisationCodeCompact(
                      localisation: {
                        'region': 'Hauts-Bassins',
                        'province': 'Houet',
                        'commune': 'Bobo-Dioulasso',
                        'village': 'SECTEUR 25',
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Exemple 4: Localisation vide
            Text(
              '4. Localisation non spécifiée',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            const LocalisationCodeWidget(
              localisation: {
                'region': '',
                'province': '',
                'commune': '',
                'village': '',
              },
              accentColor: Colors.red,
            ),

            const SizedBox(height: 30),

            // Bouton pour voir un exemple de page complète
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToExamplePage(context),
                icon: const Icon(Icons.visibility),
                label: const Text('Voir exemple de page de détails complète'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Informations sur le système de codification
            _buildInformationCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Système de Codification',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Le système utilise la codification officielle du Burkina Faso:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildCodeExample('Région', '01-13', 'Ex: 01 = Boucle du Mouhoun'),
            _buildCodeExample(
                'Province', '01-06', 'Ex: 01 = Balé (dans Boucle du Mouhoun)'),
            _buildCodeExample(
                'Commune', '01-15', 'Ex: 01 = Boromo (dans Balé)'),
            const SizedBox(height: 12),
            const Text(
              'Format final: 01-01-01 / Boucle du Mouhoun-Balé-Boromo-Village',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeExample(String niveau, String plage, String exemple) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$niveau:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            plage,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              exemple,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToExamplePage(BuildContext context) {
    // Données d'exemple pour une collecte SCOOP
    final exempleCollecte = {
      'id': 'SCOOP_001_2024',
      'type': 'SCOOP',
      'date': DateTime.now().toIso8601String(),
      'technicien': 'Amadou TRAORE',
      'statut': 'Validée',
      'region': 'Boucle du Mouhoun',
      'province': 'Balé',
      'commune': 'Boromo',
      'village': 'BAKARIDJAN',
      'scoop_name': 'SCOOP Balé Boromo',
      'periode_collecte': 'Février 2024',
      'nombre_producteurs': 15,
      'qualite': 'Premium',
      'poids_total': 125.50,
      'montant_total': 875000,
      'nombre_contenants': 8,
      'observations':
          'Excellent miel de acacia, couleur dorée homogène. Très bonne qualité pour cette période.',
      'contenants': [
        {
          'type_ruche': 'Moderne',
          'quantite_kg': 15.5,
          'prix_unitaire': 7000,
          'origine_florale': 'Acacia',
          'note': 'Première extraction, excellente qualité',
        },
        {
          'type_ruche': 'Traditionnelle',
          'quantite_kg': 12.0,
          'prix_unitaire': 6500,
          'origine_florale': 'Karité',
          'note': '',
        },
        {
          'type_ruche': 'Moderne',
          'quantite_kg': 18.3,
          'prix_unitaire': 7200,
          'origine_florale': 'Toutes fleurs',
          'note': 'Miel polyfloral de très bonne qualité',
        },
      ],
      'date_creation':
          DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      'date_modification':
          DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CollecteDetailsPage(
          collecteData: exempleCollecte,
          type: 'SCOOP',
        ),
      ),
    );
  }
}
