import 'package:cloud_firestore/cloud_firestore.dart';

/// Script de test simple pour vérifier le chargement des données Firestore
/// Exécute directement la requête vers /metiers/geographie_data
void main() async {
  print('🔍 Test direct du chargement des données Firestore...');

  try {
    final firestore = FirebaseFirestore.instance;

    print('📡 Connexion à Firestore...');
    final doc =
        await firestore.collection('metiers').doc('geographie_data').get();

    print('📄 Document existe: ${doc.exists}');

    if (!doc.exists) {
      print('❌ ERREUR: Document geographie_data non trouvé dans /metiers/');
      return;
    }

    final data = doc.data()!;
    print('📊 Clés du document: ${data.keys}');

    final regionsData = data['regions'] as List<dynamic>? ?? [];
    print('🗺️  Nombre de régions: ${regionsData.length}');

    if (regionsData.isNotEmpty) {
      print('🎯 Première région:');
      final firstRegion = regionsData.first as Map<String, dynamic>;
      print('  - Code: ${firstRegion['code']}');
      print('  - Nom: ${firstRegion['nom']}');

      final provinces = firstRegion['provinces'] as List<dynamic>? ?? [];
      print('  - Provinces: ${provinces.length}');

      if (provinces.isNotEmpty) {
        final firstProvince = provinces.first as Map<String, dynamic>;
        print(
            '  - Première province: ${firstProvince['nom']} (code: ${firstProvince['code']})');
      }
    }

    // Vérifier quelques régions spécifiques mentionnées par l'utilisateur
    final targetRegions = [
      'Bankui (BOUCLE DU MOUHOUN)',
      'Tannounyan (CASCADES)',
      'Kadiogo (CENTRE)',
    ];

    print('\n🎯 Vérification des régions cibles:');
    for (final regionData in regionsData) {
      final regionMap = regionData as Map<String, dynamic>;
      final nom = regionMap['nom'] as String;

      if (targetRegions.contains(nom)) {
        print('  ✅ Trouvé: $nom (code: ${regionMap['code']})');
      }
    }

    print('\n✅ Test terminé avec succès. Données BD bien structurées !');
  } catch (e) {
    print('❌ ERREUR lors du test: $e');
  }
}
