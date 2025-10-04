// Script pour remplacer automatiquement toutes les icônes monetization_on par SimpleFIcon
// Ce script doit être exécuté manuellement ou intégré dans un processus de build

import 'dart:io';

void main() {
  // Liste des fichiers à traiter
  final filesToProcess = [
    'lib/screens/commercialisation/commer_home.dart',
    'lib/screens/attribution/widgets/collecte_attribution_card_detailed.dart',
    'lib/screens/conditionnement/conditionnement_main_page.dart',
    'lib/screens/commercialisation/pages/dechets.dart',
    'lib/screens/extraction_page/extraction.dart',
    'lib/screens/controle_de_donnes/widgets/details_dialog.dart',
    'lib/screens/controle_de_donnes/widgets/collecte_card.dart',
    'lib/screens/controle_de_donnes/controle_de_donnes_advanced.dart',
    'lib/screens/conditionnement/pages/stock_conditionne_page.dart',
    'lib/screens/conditionnement/conditionnement_edit.dart',
    'lib/screens/vente/pages/vente_commercial_page.dart',
  ];

  for (final filePath in filesToProcess) {
    final file = File(filePath);
    if (file.existsSync()) {
      print('Traitement de $filePath...');

      String content = file.readAsStringSync();

      // Ajouter l'import si nécessaire
      if (!content.contains('import \'../../widgets/custom_f_icon.dart\';') &&
          !content
              .contains('import \'../../../widgets/custom_f_icon.dart\';') &&
          !content
              .contains('import \'../../../../widgets/custom_f_icon.dart\';')) {
        // Trouver la dernière ligne d'import
        final lines = content.split('\n');
        int lastImportIndex = -1;

        for (int i = 0; i < lines.length; i++) {
          if (lines[i].startsWith('import ')) {
            lastImportIndex = i;
          }
        }

        if (lastImportIndex != -1) {
          // Déterminer le bon chemin d'import basé sur la profondeur
          String importPath;
          if (filePath.contains('screens/screens/')) {
            importPath = 'import \'../../../widgets/custom_f_icon.dart\';';
          } else if (filePath.contains('screens/')) {
            importPath = 'import \'../../widgets/custom_f_icon.dart\';';
          } else {
            importPath = 'import \'../widgets/custom_f_icon.dart\';';
          }

          lines.insert(lastImportIndex + 1, importPath);
          content = lines.join('\n');
        }
      }

      // Remplacer les icônes
      content =
          content.replaceAll('Icons.monetization_on', 'const SimpleFIcon()');
      content = content.replaceAll(
          'Icon(Icons.monetization_on)', 'const SimpleFIcon()');
      content = content.replaceAll(
          'const Icon(Icons.monetization_on)', 'const SimpleFIcon()');

      file.writeAsStringSync(content);
      print('✅ $filePath traité avec succès');
    } else {
      print('❌ Fichier non trouvé: $filePath');
    }
  }

  print('\n🎉 Remplacement terminé !');
}

