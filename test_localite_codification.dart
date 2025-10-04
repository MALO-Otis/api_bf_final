import '../lib/data/services/localite_codification_service.dart';

void main() {
  print('🚀 Test du service de codification des localités');
  print('=' * 60);

  // Test 1: Génération de codes
  print('\n📍 Test 1: Génération de codes de localité');
  testGenerationCodes();

  // Test 2: Décodage de codes
  print('\n🔍 Test 2: Décodage de codes de localité');
  testDecodageCodes();

  // Test 3: Validation de codes
  print('\n✅ Test 3: Validation de codes');
  testValidationCodes();

  // Test 4: Test de performance
  print('\n⚡ Test 4: Test de performance');
  testPerformance();

  // Test 5: Statistiques système
  print('\n📊 Test 5: Statistiques du système');
  testStatistiques();

  print('\n🎉 Tests terminés !');
}

void testGenerationCodes() {
  final testCases = [
    {
      'region': 'Kadiogo (CENTRE)',
      'province': 'Kadiogo',
      'commune': 'Ouagadougou',
      'expected':
          '03-01-01' // Kadiogo est région 03, province 01, Ouaga commune 01
    },
    {
      'region': 'Guiriko (HAUTS-BASSINS)',
      'province': 'Houet',
      'commune': 'Bobo-Dioulasso',
      'expected':
          '09-02-01' // Guiriko région 09, Houet province 02, Bobo commune 01
    },
    {
      'region': 'Bankui (BOUCLE DU MOUHOUN)',
      'province': 'Balé',
      'commune': 'Bagassi',
      'expected':
          '01-01-01' // Bankui région 01, Balé province 01, Bagassi commune 01
    },
    {
      'region': 'Liptako (SAHEL)',
      'province': 'Oudalan',
      'commune': 'Gorom-Gorom',
      'expected':
          '12-04-01' // Liptako région 12, Oudalan province 04, Gorom commune 01
    },
  ];

  for (final testCase in testCases) {
    final code = LocaliteCodificationService.generateCodeLocalite(
      regionNom: testCase['region'] as String,
      provinceNom: testCase['province'] as String,
      communeNom: testCase['commune'] as String,
    );

    print(
        '  🏷️  ${testCase['region']} > ${testCase['province']} > ${testCase['commune']}');
    print('     ➡️  Code généré: $code');

    if (code != null) {
      print('     ✅ Génération réussie');
    } else {
      print('     ❌ Échec de génération');
    }
    print('');
  }
}

void testDecodageCodes() {
  final testCodes = [
    '03-01-01', // Kadiogo > Kadiogo > Ouagadougou
    '09-02-01', // Guiriko > Houet > Bobo-Dioulasso
    '01-01-01', // Bankui > Balé > Bagassi
    '12-04-01', // Liptako > Oudalan > Gorom-Gorom
    '99-99-99', // Code invalide
  ];

  for (final code in testCodes) {
    print('  🔍 Décodage du code: $code');
    final decoded = LocaliteCodificationService.decodeCodeLocalite(code);

    if (decoded != null) {
      print(
          '     ✅ ${decoded['region']} > ${decoded['province']} > ${decoded['commune']}');

      // Test du formatage pour affichage
      final formatted = LocaliteCodificationService.formatCodeForDisplay(code);
      print('     🎨 Formaté: $formatted');
    } else {
      print('     ❌ Code invalide ou non trouvé');
    }
    print('');
  }
}

void testValidationCodes() {
  final testCodes = [
    '03-01-01', // Valide
    '09-02-01', // Valide
    '99-99-99', // Invalide
    '01-01', // Format invalide
    'abc-def-ghi', // Format invalide
    '', // Vide
  ];

  for (final code in testCodes) {
    final isValid = LocaliteCodificationService.validateCodeLocalite(code);
    print('  📋 Code: "$code" → ${isValid ? "✅ Valide" : "❌ Invalide"}');
  }
}

void testPerformance() {
  print('  ⏱️  Démarrage du test de performance...');

  final result = LocaliteCodificationService.runPerformanceTest();

  print('     Durée: ${result['duration_ms']}ms');
  print('     Succès: ${result['success_count']}');
  print('     Erreurs: ${result['error_count']}');
  print('     Performance OK: ${result['performance_ok'] ? "✅" : "❌"}');

  final sampleCodes = result['sample_codes'] as List<String>;
  if (sampleCodes.isNotEmpty) {
    print('     📝 Exemples de codes générés:');
    for (final code in sampleCodes.take(3)) {
      print('        - $code');
    }
  }
}

void testStatistiques() {
  final stats = LocaliteCodificationService.getStatistics();

  print('  📊 Statistiques du système géographique:');
  print('     🏛️  Régions: ${stats['regions']}');
  print('     🏙️  Provinces: ${stats['provinces']}');
  print('     🏘️  Communes: ${stats['communes']}');

  final totalCombinations =
      stats['regions']! * stats['provinces']! * stats['communes']!;
  print('     🔢 Combinaisons possibles: $totalCombinations');
}
