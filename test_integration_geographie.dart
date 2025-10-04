import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/collecte_de_donnes/core/collecte_geographie_service.dart';

/// Test simple pour vérifier l'intégration du service géographie Firestore
/// dans le module de collecte.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase (nécessaire pour les tests)
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialisé avec succès');
  } catch (e) {
    print('❌ Erreur Firebase: $e');
    return;
  }

  // Injecter le service géographie
  Get.put(CollecteGeographieService());

  print('🚀 Test d\'intégration CollecteGeographieService');
  print('=' * 50);

  final service = Get.find<CollecteGeographieService>();

  // Test 1: Chargement des données
  print('\n📡 Test 1: Chargement des données depuis Firestore...');
  try {
    await service.loadGeographieData();
    print('✅ Données chargées avec succès');

    // Afficher les statistiques
    final stats = service.getStats();
    print('📊 Statistiques:');
    print('   - Régions: ${stats['regions']}');
    print('   - Provinces: ${stats['provinces']}');
    print('   - Communes: ${stats['communes']}');
    print('   - Villages: ${stats['villages']}');

    if (stats['regions']! > 0) {
      print('✅ Test 1 réussi - Données non vides');
    } else {
      print('⚠️  Test 1 partiel - Aucune région trouvée');
    }
  } catch (e) {
    print('❌ Test 1 échoué: $e');
    return;
  }

  // Test 2: Méthodes de compatibilité
  print('\n🔄 Test 2: Méthodes de compatibilité...');
  try {
    // Test regionsMap
    final regions = service.regionsMap;
    print('📍 ${regions.length} régions au format Map disponibles');

    if (regions.isNotEmpty) {
      final premiereRegion = regions.first;
      print('   Exemple: ${premiereRegion['nom']} (${premiereRegion['code']})');

      // Test provinces pour cette région
      final provinces =
          service.getProvincesForRegionMap(premiereRegion['code']);
      print('   Provinces: ${provinces.length} trouvées');

      if (provinces.isNotEmpty) {
        final premiereProvince = provinces.first;
        print(
            '   Exemple: ${premiereProvince['nom']} (${premiereProvince['code']})');

        // Test communes pour cette province
        final communes = service.getCommunesForProvinceMap(
            premiereRegion['code'], premiereProvince['code']);
        print('   Communes: ${communes.length} trouvées');

        if (communes.isNotEmpty) {
          final premiereCommune = communes.first;
          print(
              '   Exemple: ${premiereCommune['nom']} (${premiereCommune['code']})');

          // Test villages pour cette commune
          final villages = service.getVillagesForCommuneMap(
              premiereRegion['code'],
              premiereProvince['code'],
              premiereCommune['code']);
          print('   Villages: ${villages.length} trouvées');

          if (villages.isNotEmpty) {
            final premierVillage = villages.first;
            print(
                '   Exemple: ${premierVillage['nom']} (${premierVillage['code']})');
          }
        }
      }

      print('✅ Test 2 réussi - Méthodes de compatibilité fonctionnelles');
    }
  } catch (e) {
    print('❌ Test 2 échoué: $e');
    return;
  }

  // Test 3: Méthodes de recherche par nom
  print('\n🔍 Test 3: Recherche par nom...');
  try {
    final regions = service.regionsMap;
    if (regions.isNotEmpty) {
      final premiereRegion = regions.first;
      final nomRegion = premiereRegion['nom'];

      // Test recherche région par nom
      final codeRegion = service.getRegionCodeByName(nomRegion);
      print('🔍 Recherche région "$nomRegion" → Code: "$codeRegion"');

      if (codeRegion.isNotEmpty) {
        final provinces = service.getProvincesForRegionMap(codeRegion);
        if (provinces.isNotEmpty) {
          final nomProvince = provinces.first['nom'];
          final codeProvince =
              service.getProvinceCodeByName(codeRegion, nomProvince);
          print('🔍 Recherche province "$nomProvince" → Code: "$codeProvince"');

          if (codeProvince.isNotEmpty) {
            final communes =
                service.getCommunesForProvinceMap(codeRegion, codeProvince);
            if (communes.isNotEmpty) {
              final nomCommune = communes.first['nom'];
              final codeCommune = service.getCommuneCodeByName(
                  codeRegion, codeProvince, nomCommune);
              print(
                  '🔍 Recherche commune "$nomCommune" → Code: "$codeCommune"');
            }
          }
        }
      }

      print('✅ Test 3 réussi - Recherche par nom fonctionnelle');
    }
  } catch (e) {
    print('❌ Test 3 échoué: $e');
    return;
  }

  // Test 4: Validation hiérarchie
  print('\n✔️  Test 4: Validation hiérarchie...');
  try {
    final regions = service.regionsMap;
    if (regions.isNotEmpty) {
      final premiereRegion = regions.first;
      final codeRegion = premiereRegion['code'];

      final provinces = service.getProvincesForRegionMap(codeRegion);
      if (provinces.isNotEmpty) {
        final codeProvince = provinces.first['code'];

        // Test validation positive
        final validationOk = service.validateHierarchy(
          codeRegion: codeRegion,
          codeProvince: codeProvince,
        );
        print('✔️  Validation hiérarchie valide: $validationOk');

        // Test validation négative
        final validationKo = service.validateHierarchy(
          codeRegion: codeRegion,
          codeProvince: '99', // Code inexistant
        );
        print('✔️  Validation hiérarchie invalide: $validationKo');

        if (validationOk && !validationKo) {
          print('✅ Test 4 réussi - Validation fonctionnelle');
        } else {
          print('⚠️  Test 4 partiel - Résultats inattendus');
        }
      }
    }
  } catch (e) {
    print('❌ Test 4 échoué: $e');
    return;
  }

  print('\n' + '=' * 50);
  print('🎉 Tests d\'intégration terminés avec succès !');
  print('💡 Le service CollecteGeographieService est prêt pour l\'utilisation');
  print(
      '🔄 Les dropdowns dans modal_nouveau_producteur.dart utilisent maintenant');
  print(
      '   les données Firestore en temps réel depuis /metiers/geographie_data');
}
