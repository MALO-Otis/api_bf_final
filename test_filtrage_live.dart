#!/usr/bin/env dart

/// Script de test en temps réel pour vérifier le module filtrage
/// Compile et lance l'application pour tester la fonctionnalité

import 'dart:io';

void main() async {
  print('🧪 SCRIPT DE TEST - MODULE FILTRAGE');
  print('===================================');
  print('');

  print('📋 ÉTAPES DE TEST À SUIVRE:');
  print('');
  print('1. 🚀 L\'application va se compiler et se lancer');
  print('2. 🔐 Connectez-vous à l\'application');
  print('3. 📱 Allez dans le module Filtrage');
  print('4. 📋 Notez les produits affichés dans la liste');
  print('5. ✅ Sélectionnez un produit et effectuez un filtrage COMPLET');
  print('6. 💾 Sauvegardez le filtrage');
  print('7. 🔄 Retournez à la liste des produits');
  print('8. ✨ VÉRIFICATION: Le produit ne doit PLUS apparaître dans la liste');
  print('9. 📊 Allez dans l\'historique pour vérifier qu\'il y est bien');
  print('');

  print('🎯 CRITÈRES DE RÉUSSITE:');
  print('✅ Le produit totalement filtré disparaît de la liste');
  print('✅ Le produit apparaît dans l\'historique');
  print('✅ Les informations sont correctes dans l\'historique');
  print('');

  print('🔧 DEBUGGING:');
  print('✅ Des logs apparaîtront dans la console pour tracer les opérations');
  print('✅ Les messages debug commencent par 🔍, ✅, ou ❌');
  print('');

  print('🚀 Compilation et lancement de l\'application...');
  print('');

  // Changer vers le répertoire du projet
  const projectPath =
      r'c:\Users\Sadouanouan\Desktop\flutter stuffs\apisavana_gestion - Copy - Copy';

  try {
    // Compiler et lancer l'application
    final result = await Process.run(
      'flutter',
      ['run', '--debug'],
      workingDirectory: projectPath,
    );

    if (result.exitCode == 0) {
      print('✅ APPLICATION LANCÉE AVEC SUCCÈS');
      print('Suivez maintenant les étapes de test ci-dessus.');
    } else {
      print('❌ ERREUR DE COMPILATION:');
      print(result.stderr);
    }
  } catch (e) {
    print('❌ ERREUR: $e');
    print('');
    print('📝 SOLUTION ALTERNATIVE:');
    print('Lancez manuellement la commande: flutter run --debug');
    print('dans le répertoire: $projectPath');
  }

  print('');
  print('📞 En cas de problème, vérifiez:');
  print('1. Flutter est installé et dans le PATH');
  print('2. Le projet compile sans erreur (flutter analyze)');
  print('3. Les dépendances sont installées (flutter pub get)');
}
