import 'package:get/get.dart';
import 'lib/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/screens/collecte_de_donnes/core/collecte_geographie_service.dart';

/// Test standalone pour vérifier le CollecteGeographieService
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('🔥 Firebase initialisé');

  // Initialiser GetX
  Get.put(CollecteGeographieService(), permanent: true);
  print('✅ Service injecté dans GetX');

  // Récupérer le service et tester
  final service = Get.find<CollecteGeographieService>();

  print('📊 État initial du service:');
  print('  - isLoading: ${service.isLoading}');
  print('  - error: "${service.error}"');
  print('  - regions: ${service.regions.length}');

  // Attendre que les données se chargent
  print('⏳ Attente de 5 secondes pour le chargement...');
  await Future.delayed(Duration(seconds: 5));

  print('📊 État après 5 secondes:');
  print('  - isLoading: ${service.isLoading}');
  print('  - error: "${service.error}"');
  print('  - regions: ${service.regions.length}');

  if (service.regions.isNotEmpty) {
    print('🎯 Première région trouvée: ${service.regions.first.nom}');
    if (service.regions.first.provinces.isNotEmpty) {
      print(
          '   └── Première province: ${service.regions.first.provinces.first.nom}');
    }
  }

  print('✅ Test terminé');
}
