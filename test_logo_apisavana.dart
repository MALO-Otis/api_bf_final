import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
#!/usr/bin/env dart


/// Script de test pour vérifier que le logo APISAVANA existe et peut être chargé
void main() async {
  print('🔍 Test du logo APISAVANA...');
  
  // Vérifier si le fichier existe
  final logoFile = File('assets/logo/logo.jpeg');
  if (await logoFile.exists()) {
    print('✅ Fichier logo trouvé: ${logoFile.path}');
    
    final fileSize = await logoFile.length();
    print('📏 Taille du fichier: ${fileSize} bytes');
    
    if (fileSize > 0) {
      print('✅ Le logo APISAVANA est prêt à être utilisé dans les PDF');
      print('');
      print('🔧 Instructions:');
      print('1. Le logo sera automatiquement chargé dans les services PDF');
      print('2. Taille optimisée: 120px de largeur pour une bonne visibilité');
      print('3. Le texte "APISAVANA" sera bien lisible');
      print('4. Bordure noire ajoutée pour mettre en valeur le logo');
    } else {
      print('❌ Le fichier logo est vide');
    }
  } else {
    print('❌ Logo non trouvé: ${logoFile.path}');
    print('');
    print('🔧 Solutions:');
    print('1. Vérifiez que le fichier assets/logo/logo.jpeg existe');
    print('2. Ajoutez le logo au dossier assets/logo/');
    print('3. Vérifiez le pubspec.yaml pour l\'inclusion des assets');
  }
  
  print('');
  print('📋 Vérifications pubspec.yaml:');
  
  final pubspecFile = File('pubspec.yaml');
  if (await pubspecFile.exists()) {
    final content = await pubspecFile.readAsString();
    if (content.contains('assets/logo/')) {
      print('✅ Assets logo configurés dans pubspec.yaml');
    } else {
      print('❌ Assets logo non configurés dans pubspec.yaml');
      print('');
      print('Ajoutez ceci à votre pubspec.yaml:');
      print('flutter:');
      print('  assets:');
      print('    - assets/logo/');
    }
  } else {
    print('❌ pubspec.yaml non trouvé');
  }
}