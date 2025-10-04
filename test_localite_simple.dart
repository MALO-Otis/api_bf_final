// Test simple du service de codification sans dépendances Firebase
void main() {
  print('🚀 Test simple du service de codification des localités');
  print('=' * 60);

  // Test avec des valeurs hardcodées basées sur GeographieData
  testGenerationCodes();
}

void testGenerationCodes() {
  final testCases = [
    {
      'region': 'Kadiogo (CENTRE)',
      'province': 'Kadiogo',
      'commune': 'Ouagadougou',
      'description': 'Capitale du Burkina Faso'
    },
    {
      'region': 'Guiriko (HAUTS-BASSINS)',
      'province': 'Houet',
      'commune': 'Bobo-Dioulasso',
      'description': 'Deuxième ville du pays'
    },
    {
      'region': 'Bankui (BOUCLE DU MOUHOUN)',
      'province': 'Balé',
      'commune': 'Bagassi',
      'description': 'Commune de la Boucle du Mouhoun'
    },
    {
      'region': 'Nando (CENTRE-OUEST)',
      'province': 'Boulkiemdé',
      'commune': 'Koudougou',
      'description': 'Ville de Koudougou'
    },
  ];

  print('\n📍 Test de génération de codes de localité');
  print('-' * 50);

  for (final testCase in testCases) {
    print('\n🏷️  ${testCase['description']}');
    print(
        '   📍 ${testCase['region']} > ${testCase['province']} > ${testCase['commune']}');

    // Simulation du processus de codification
    final regionCode = _getRegionCodeSimulation(testCase['region'] as String);
    final provinceCode =
        _getProvinceCodeSimulation(testCase['province'] as String);
    final communeCode =
        _getCommuneCodeSimulation(testCase['commune'] as String);

    if (regionCode != null && provinceCode != null && communeCode != null) {
      final codeLocalite = '$regionCode-$provinceCode-$communeCode';
      print('   ✅ Code généré: $codeLocalite');
      print(
          '   🔍 Détail: Région $regionCode, Province $provinceCode, Commune $communeCode');
    } else {
      print('   ❌ Impossible de générer le code');
    }
  }

  print('\n🎯 Explication du système de codification:');
  print('   • Format: XX-XX-XX (Région-Province-Commune)');
  print('   • Codification basée sur l\'ordre alphabétique');
  print('   • Permet une identification unique de chaque localité');
  print('   • Facilite le tri et la recherche géographique');
}

// Simulations simplifiées basées sur GeographieData
String? _getRegionCodeSimulation(String regionNom) {
  final regions = {
    'Bankui (BOUCLE DU MOUHOUN)': '01',
    'Tannounyan (CASCADES)': '02',
    'Kadiogo (CENTRE)': '03',
    'Nakambé (CENTRE-EST)': '04',
    'Kuilsé (CENTRE-NORD)': '05',
    'Nando (CENTRE-OUEST)': '06',
    'Nazinon (CENTRE-SUD)': '07',
    'Goulmou (EST)': '08',
    'Guiriko (HAUTS-BASSINS)': '09',
    'Yaadga (NORD)': '10',
    'Oubri (PLATEAU-CENTRAL)': '11',
    'Liptako (SAHEL)': '12',
    'Djôrô (SUD-OUEST)': '13',
  };

  return regions[regionNom];
}

String? _getProvinceCodeSimulation(String provinceNom) {
  final provinces = {
    'Kadiogo': '01',
    'Houet': '02',
    'Balé': '01',
    'Boulkiemdé': '02',
  };

  return provinces[provinceNom];
}

String? _getCommuneCodeSimulation(String communeNom) {
  final communes = {
    'Ouagadougou': '01',
    'Bobo-Dioulasso': '01',
    'Bagassi': '01',
    'Koudougou': '01',
  };

  return communes[communeNom];
}
