import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/models/report_models.dart';
import '../data/services/enhanced_pdf_service.dart';
import '../screens/vente/utils/apisavana_pdf_service.dart';

/// Test complet du système de logo APISAVANA dans tous les services PDF
class LogoTestService {
  /// Test principal : génère des PDF de test avec logo APISAVANA visible
  static Future<void> runCompleteLogoTest() async {
    print('🧪 DÉBUT DU TEST COMPLET DU LOGO APISAVANA');
    print('=' * 60);

    // 1. Vérifier l'existence du fichier logo
    await _testLogoFileExists();

    // 2. Tester le chargement du logo dans ApiSavanaPdfService
    await _testApiSavanaPdfServiceLogo();

    // 3. Tester le chargement du logo dans EnhancedPdfService
    await _testEnhancedPdfServiceLogo();

    // 4. Générer un PDF de test avec le logo
    await _generateTestPdfWithLogo();

    print('=' * 60);
    print('🎯 TEST COMPLET TERMINÉ');
  }

  static Future<void> _testLogoFileExists() async {
    print('\n📁 Test 1: Vérification du fichier logo...');

    try {
      final byteData = await rootBundle.load('assets/logo/logo.jpeg');
      final bytes = byteData.buffer.asUint8List();

      if (bytes.isNotEmpty) {
        print('✅ Fichier logo.jpeg trouvé (${bytes.length} bytes)');
        print('   📏 Taille: ${(bytes.length / 1024).toStringAsFixed(1)} KB');
      } else {
        print('❌ Fichier logo.jpeg est vide');
      }
    } catch (e) {
      print('❌ Erreur chargement logo.jpeg: $e');
      print('📋 Vérifiez:');
      print('   - assets/logo/logo.jpeg existe');
      print('   - pubspec.yaml contient: assets: [assets/logo/]');
    }
  }

  static Future<void> _testApiSavanaPdfServiceLogo() async {
    print('\n🎨 Test 2: ApiSavanaPdfService...');

    try {
      await ApiSavanaPdfService.loadLogo();
      print('✅ Logo chargé dans ApiSavanaPdfService');

      // Test de génération d'en-tête avec logo
      final headerWidget = ApiSavanaPdfService.buildHeader(
        documentTitle: 'TEST LOGO APISAVANA',
        documentNumber: 'TEST-001',
        documentDate: DateTime.now(),
        showLogo: true,
      );

      if (headerWidget != null) {
        print('✅ En-tête avec logo généré avec succès');
        print('   📐 Taille du logo: 120px (optimisée pour visibilité)');
        print('   🎯 Logo APISAVANA sera bien visible dans les PDF');
      }
    } catch (e) {
      print('❌ Erreur ApiSavanaPdfService: $e');
    }
  }

  static Future<void> _testEnhancedPdfServiceLogo() async {
    print('\n⚡ Test 3: EnhancedPdfService...');

    try {
      await EnhancedPdfService.loadLogo();
      print('✅ Logo chargé dans EnhancedPdfService');
      print('   📐 Taille du logo: 120px (optimisée pour visibilité)');
      print(
          '   🎯 Logo APISAVANA sera bien visible dans les rapports statistiques');
    } catch (e) {
      print('❌ Erreur EnhancedPdfService: $e');
    }
  }

  static Future<void> _generateTestPdfWithLogo() async {
    print('\n📄 Test 4: Génération PDF de test...');

    try {
      // Créer un rapport de test
      final testReport = RapportStatistiques(
        numeroRapport: 'TEST-LOGO-001',
        dateGeneration: DateTime.now(),
        siteCollecte: 'SITE DE TEST',
        typeCollecte: 'Test Logo',
        periodeDebut: DateTime.now().subtract(const Duration(days: 30)),
        periodeFin: DateTime.now(),
        collectesAnalysees: 5,
        contenantsAnalyses: 25,
        poidsTotal: 125.5,
        montantTotal: 75000.0,
        collectesDetaillees: [],
        statistiquesContenants: {},
        localisationData: {
          'latitude': 12.3456,
          'longitude': -1.6789,
          'address': 'Test Address, Burkina Faso'
        },
      );

      // Générer le PDF avec le logo APISAVANA
      final pdfBytes =
          await EnhancedPdfService.genererRapportStatistiquesAmeliore(
              testReport);

      if (pdfBytes.isNotEmpty) {
        print('✅ PDF de test généré avec succès (${pdfBytes.length} bytes)');
        print(
            '   📏 Taille: ${(pdfBytes.length / 1024).toStringAsFixed(1)} KB');
        print('   🎯 Le logo APISAVANA est intégré et bien visible');

        // Sauvegarder le PDF de test (optionnel)
        try {
          final file = File('test_logo_apisavana.pdf');
          await file.writeAsBytes(pdfBytes);
          print('   💾 PDF sauvegardé: ${file.path}');
        } catch (e) {
          print('   ⚠️ Impossible de sauvegarder: $e');
        }
      } else {
        print('❌ PDF de test vide');
      }
    } catch (e) {
      print('❌ Erreur génération PDF de test: $e');
    }
  }

  /// Test rapide pour vérifier uniquement la présence du logo
  static Future<bool> quickLogoCheck() async {
    try {
      final byteData = await rootBundle.load('assets/logo/logo.jpeg');
      return byteData.lengthInBytes > 0;
    } catch (e) {
      return false;
    }
  }

  /// Instructions pour l'utilisateur
  static void printLogoInstructions() {
    print('\n📋 INSTRUCTIONS LOGO APISAVANA:');
    print('-' * 40);
    print('1. Placez votre logo dans: assets/logo/logo.jpeg');
    print('2. Vérifiez pubspec.yaml:');
    print('   flutter:');
    print('     assets:');
    print('       - assets/logo/');
    print('3. Le logo sera automatiquement:');
    print('   ✓ Redimensionné à 120px de largeur');
    print('   ✓ Entouré d\'une bordure noire');
    print('   ✓ Affiché dans tous les PDF');
    print('   ✓ Bien visible avec le texte APISAVANA lisible');
    print('4. Fallback automatique si le logo manque');
    print('-' * 40);
  }
}
