/// Script de debugging pour vérifier l'historique des filtrages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

void main() async {
  debugPrint('=== DÉBUT DEBUG HISTORIQUE FILTRAGE ===');

  // Configuration Firebase (à adapter selon votre configuration)
  // Remplacez par votre configuration Firebase si nécessaire

  try {
    // Créer une session utilisateur de test
    final userSession = UserSession();
    userSession.site = 'Koudougou'; // ou votre site
    userSession.email = 'test@test.com';
    Get.put(userSession);

    final service = FiltrageServiceComplete();

    debugPrint('🔍 Vérification directe des collections Firestore...');

    final firestore = FirebaseFirestore.instance;

    // 1. Vérifier si la collection principale existe
    debugPrint('📋 1. Vérification collection Filtrage...');
    final filtrageMainCollection = await firestore.collection('Filtrage').get();
    debugPrint('   📊 Nombre de sites: ${filtrageMainCollection.docs.length}');

    for (final siteDoc in filtrageMainCollection.docs) {
      debugPrint('   🏢 Site: ${siteDoc.id}');

      // Vérifier les processus de ce site
      final processusCollection =
          await siteDoc.reference.collection('processus').get();
      debugPrint(
          '      📦 Nombre de processus: ${processusCollection.docs.length}');

      for (final processusDoc in processusCollection.docs.take(3)) {
        // Limiter à 3 pour le debug
        final data = processusDoc.data();
        debugPrint('      🔍 Processus ID: ${processusDoc.id}');
        debugPrint('         📝 Données: ${data.keys.join(', ')}');
        debugPrint('         👤 Utilisateur: ${data['utilisateur']}');
        debugPrint('         📅 Date: ${data['dateFiltrage']}');
        debugPrint(
            '         ⚖️ Quantité filtrée: ${data['quantiteFiltree']} kg');
      }
    }

    debugPrint('🔍 2. Test du service FiltrageServiceComplete...');
    final historique = await service.getHistoriqueFiltrage();
    debugPrint('   📊 Nombre d\'éléments récupérés: ${historique.length}');

    if (historique.isNotEmpty) {
      debugPrint('   ✅ Premier élément:');
      final premier = historique.first;
      premier.forEach((key, value) {
        debugPrint('      $key: $value');
      });
    } else {
      debugPrint('   ❌ Aucun élément dans l\'historique');
      debugPrint('   🔍 Causes possibles:');
      debugPrint('      - Collection Firestore vide');
      debugPrint('      - Problème de permissions');
      debugPrint('      - Nom de site incorrect');
      debugPrint('      - Problème de configuration Firebase');
    }

    debugPrint('🔍 3. Test des statistiques...');
    final stats = await service.getStatistiquesFiltrage();
    debugPrint('   📊 Statistiques: $stats');
  } catch (e, stackTrace) {
    debugPrint('❌ ERREUR lors du debug:');
    debugPrint('   💥 Erreur: $e');
    debugPrint('   📍 Stack: $stackTrace');
  }

  debugPrint('=== FIN DEBUG HISTORIQUE FILTRAGE ===');
}
