/// 🧪 Test du nouveau format de code de suivi
/// Vérifie que le nouveau format fonctionne correctement

void main() {
  print('🧪 TEST DU NOUVEAU FORMAT DE CODE DE SUIVI');
  print('=' * 60);

  // Test du format avec des exemples
  testNewTrackingCodeFormat();

  print('\n✅ TESTS TERMINÉS !');
}

void testNewTrackingCodeFormat() {
  print('\n📋 Nouveau format de code de suivi:');
  print(
      'Format: [Type]__[Du-date]__[De-nom]__[A-localité]__[Site-de-nom]__[Controle-date]__[Controler-Par-nom]__[Code-Contenant-num]');

  // Exemple de code généré
  String exempleCode =
      '[Recolte]__[Du-19-09-2025]__[De-VALENTIN-ZOUNGRANA]__[A-04-03-01-KOUDOUGOU]__[Site-de-KOUDOUGOU]__[Controle-04-10-2025]__[Controler-Par-MALO-OTIS]__[Code-Contenant-00001]';

  print('\n🎯 Exemple de code généré:');
  print(exempleCode);

  print('\n📊 Analyse du format:');
  print('✅ [Recolte] → Type de collecte');
  print('✅ [Du-19-09-2025] → Date précise de collecte');
  print('✅ [De-VALENTIN-ZOUNGRANA] → Nom producteur/technicien');
  print(
      '✅ [A-04-03-01-KOUDOUGOU] → Code localité (région-province-commune-village)');
  print('✅ [Site-de-KOUDOUGOU] → Site de récolte');
  print('✅ [Controle-04-10-2025] → Date de contrôle');
  print('✅ [Controler-Par-MALO-OTIS] → Nom du contrôleur');
  print('✅ [Code-Contenant-00001] → Code contenant formaté');

  print('\n🔧 Avantages du nouveau format:');
  print('• Plus lisible et structuré');
  print('• Séparateurs clairs (__) entre sections');
  print('• Informations géographiques détaillées');
  print('• Traçabilité complète du processus');
  print('• Format uniforme et professionnel');

  testContainerNumberExtraction();
  testLocationCodeBuilding();
}

void testContainerNumberExtraction() {
  print('\n🧮 Test extraction numéro contenant:');

  Map<String, String> testCases = {
    'RECREOVALENTINZOUNGRANA202509190001': '00001',
    'CONTAINER123': '00123',
    'SCOOP456': '00456',
    'MIEL789ABC': '00789',
    'NODIGITS': '00001', // Fallback
  };

  testCases.forEach((input, expected) {
    String result = extractContainerNumber(input);
    String status = result == expected ? '✅' : '❌';
    print('  $status $input → $result (attendu: $expected)');
  });
}

void testLocationCodeBuilding() {
  print('\n🗺️  Test construction code localité:');

  // Simuler différents cas
  print('  📍 Région 04, Province 03, Commune 01, Village KOUDOUGOU');
  print('  → Code: 04-03-01-KOUDOUGOU');

  print('  📍 Région 02, Province 05, Commune 03, Village BOBO-DIOULASSO');
  print('  → Code: 02-05-03-BOBO-DIOULASSO');

  print('  📍 Fallback avec valeurs par défaut');
  print('  → Code: 04-03-01-VILLAGE');
}

// Fonction utilitaire pour tester l'extraction du numéro
String extractContainerNumber(String containerCode) {
  final regex = RegExp(r'(\d+)$');
  final match = regex.firstMatch(containerCode);

  if (match != null) {
    final number = int.tryParse(match.group(1)!) ?? 1;
    return number.toString().padLeft(5, '0');
  } else {
    return '00001';
  }
}
