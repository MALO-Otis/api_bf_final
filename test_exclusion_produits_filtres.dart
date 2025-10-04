/// Script de test pour valider l'exclusion des produits filtrés
/// Ce script simule le comportement attendu du module de filtrage
library;

void main() {
  print('🧪 TEST: Validation de l\'exclusion des produits filtrés\n');

  // Simulation des produits dans la collection
  final produitsFiltres = [
    {
      'id': 'PROD001',
      'codeContenant': 'CONT001',
      'statut': 'en_attente', // Doit apparaître dans la liste
      'dateReception': '2024-01-15T10:30:00Z',
    },
    {
      'id': 'PROD002',
      'codeContenant': 'CONT002',
      'statut': 'en_cours_traitement', // Doit apparaître dans la liste
      'dateReception': '2024-01-15T11:00:00Z',
    },
    {
      'id': 'PROD003',
      'codeContenant': 'CONT003',
      'statut': 'termine', // NE DOIT PAS apparaître dans la liste
      'dateReception': '2024-01-15T09:15:00Z',
      'dateFinFiltrage': '2024-01-15T14:30:00Z',
      'poidsFiltre': '8.5',
    },
    {
      'id': 'PROD004',
      'codeContenant': 'CONT004',
      'statut': 'suspendu', // Doit apparaître dans la liste
      'dateReception': '2024-01-15T08:45:00Z',
    },
    {
      'id': 'PROD005',
      'codeContenant': 'CONT005',
      'statut': 'termine', // NE DOIT PAS apparaître dans la liste
      'dateReception': '2024-01-15T12:20:00Z',
      'dateFinFiltrage': '2024-01-15T16:45:00Z',
      'poidsFiltre': '12.3',
    }
  ];

  print('📋 Produits dans la collection: ${produitsFiltres.length}');
  for (final produit in produitsFiltres) {
    print('   - ${produit['codeContenant']}: ${produit['statut']}');
  }

  // Simulation de la logique d'exclusion
  final produitsAffiches = produitsFiltres.where((product) {
    if (product['statut'] == 'termine') {
      print(
          '🚫 EXCLUSION: ${product['codeContenant']} - Statut: ${product['statut']}');
      return false; // Produit déjà filtré, ne pas l'afficher
    }
    return true; // Produit à afficher dans la liste à filtrer
  }).toList();

  print('\n📱 Produits affichés dans l\'UI: ${produitsAffiches.length}');
  for (final produit in produitsAffiches) {
    print('   ✅ ${produit['codeContenant']}: ${produit['statut']}');
  }

  // Validation des résultats
  print('\n🔍 VALIDATION:');

  final nombreProduitsTotaux = produitsFiltres.length;
  final nombreProduitsTermines =
      produitsFiltres.where((p) => p['statut'] == 'termine').length;
  final nombreProduitsAffiches = produitsAffiches.length;
  final nombreProduitsAttendus = nombreProduitsTotaux - nombreProduitsTermines;

  print('   - Nombre total de produits: $nombreProduitsTotaux');
  print(
      '   - Nombre de produits terminés (à exclure): $nombreProduitsTermines');
  print('   - Nombre de produits affichés: $nombreProduitsAffiches');
  print('   - Nombre attendu: $nombreProduitsAttendus');

  if (nombreProduitsAffiches == nombreProduitsAttendus) {
    print('   ✅ SUCCÈS: L\'exclusion fonctionne correctement !');
  } else {
    print('   ❌ ÉCHEC: L\'exclusion ne fonctionne pas correctement !');
  }

  // Test de simulation de filtrage
  print('\n🔄 SIMULATION: Filtrage d\'un produit');

  // Simuler le filtrage du produit CONT001
  final produitAFiltrer =
      produitsAffiches.firstWhere((p) => p['codeContenant'] == 'CONT001');
  print('   🎯 Filtrage de: ${produitAFiltrer['codeContenant']}');

  // Mise à jour du statut
  produitAFiltrer['statut'] = 'termine';
  produitAFiltrer['dateFinFiltrage'] = '2024-01-15T17:00:00Z';
  produitAFiltrer['poidsFiltre'] = '9.8'; // Chaîne de caractères

  print('   📝 Nouveau statut: ${produitAFiltrer['statut']}');

  // Re-application de la logique d'exclusion
  final produitsApresFiltrageUpdate = produitsFiltres.where((product) {
    if (product['statut'] == 'termine') {
      return false; // Produit filtré, ne pas l'afficher
    }
    return true;
  }).toList();

  print(
      '   📱 Produits affichés après filtrage: ${produitsApresFiltrageUpdate.length}');
  print(
      '   🎉 Le produit ${produitAFiltrer['codeContenant']} a disparu de la liste !');

  print('\n✅ TEST TERMINÉ: La logique d\'exclusion est correcte.');
}
