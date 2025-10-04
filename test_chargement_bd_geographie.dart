import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/screens/collecte_de_donnes/core/collecte_geographie_service.dart';

/// Test rapide pour vérifier que le CollecteGeographieService
/// charge bien les vraies données depuis /metiers/geographie_data
/// et non des données hardcodées

void main() async {
  print(
      '🧪 [Test BD] Début du test de chargement des données géographiques...');

  try {
    // Initialiser Firebase (nécessaire pour Firestore)
    await Firebase.initializeApp();
    print('✅ [Test BD] Firebase initialisé');

    // Créer le service
    final service = CollecteGeographieService();
    print('✅ [Test BD] Service créé');

    // Charger les données
    await service.loadGeographieData();
    print('✅ [Test BD] Chargement des données terminé');

    // Vérifier les résultats
    final regions = service.regions;
    print('📊 [Test BD] Résultats:');
    print('  - Nombre de régions: ${regions.length}');

    if (regions.isNotEmpty) {
      print('  - Première région: ${regions.first.nom}');
      print('  - Dernière région: ${regions.last.nom}');

      // Vérifier quelques régions spécifiques de la vraie BD
      final regionsAttendue = [
        'Bankui (BOUCLE DU MOUHOUN)',
        'Tannounyan (CASCADES)',
        'Kadiogo (CENTRE)',
        'Djôrô (SUD-OUEST)'
      ];

      print('🔍 [Test BD] Vérification des régions attendues:');
      for (final regionNom in regionsAttendue) {
        final found = regions.any((r) => r.nom == regionNom);
        print('  - ${regionNom}: ${found ? "✅ Trouvé" : "❌ Non trouvé"}');
      }

      // Afficher toutes les régions pour comparaison
      print('📋 [Test BD] Liste complète des régions chargées:');
      for (int i = 0; i < regions.length; i++) {
        final region = regions[i];
        print(
            '  ${i + 1}. ${region.nom} (code: ${region.code}, provinces: ${region.provinces.length})');
      }
    } else {
      print('❌ [Test BD] Aucune région chargée!');
    }
  } catch (e) {
    print('❌ [Test BD] Erreur: $e');
  }

  print('🏁 [Test BD] Test terminé');
  exit(0);
}
