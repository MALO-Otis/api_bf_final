import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/services/enhanced_pdf_service.dart';
import '../screens/vente/utils/apisavana_pdf_service.dart';

/// Service d'initialisation pour charger le logo APISAVANA dans tous les services PDF
class LogoInitializationService {
  static bool _isInitialized = false;
  
  /// Initialise le logo APISAVANA dans tous les services PDF
  static Future<void> initializeLogoServices() async {
    if (_isInitialized) return;
    
    print('🚀 Initialisation du logo APISAVANA...');
    
    try {
      // Charger le logo dans le service PDF principal
      await ApiSavanaPdfService.loadLogo();
      
      // Charger le logo dans le service PDF amélioré
      await EnhancedPdfService.loadLogo();
      
      _isInitialized = true;
      print('✅ Logo APISAVANA initialisé avec succès dans tous les services PDF');
      
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation du logo: $e');
      print('📋 Vérifiez que le fichier assets/logo/logo.jpeg existe');
      print('📋 Vérifiez la configuration des assets dans pubspec.yaml');
    }
  }
  
  /// Vérifie si le logo est disponible
  static Future<bool> isLogoAvailable() async {
    try {
      final byteData = await rootBundle.load('assets/logo/logo.jpeg');
      return byteData.lengthInBytes > 0;
    } catch (e) {
      return false;
    }
  }
  
  /// Fonction utilitaire à appeler dans main.dart
  static Future<void> initializeApp() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    print('📱 Initialisation de l\'application APISAVANA...');
    
    // Charger le logo dans tous les services PDF
    await initializeLogoServices();
    
    // Vérifier la disponibilité du logo
    final logoAvailable = await isLogoAvailable();
    if (logoAvailable) {
      print('✅ Logo APISAVANA prêt pour les rapports PDF');
    } else {
      print('⚠️  Logo APISAVANA non disponible - utilisation du fallback');
    }
    
    print('🎯 Application APISAVANA prête');
  }
}