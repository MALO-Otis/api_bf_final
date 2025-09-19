import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

/// Gestionnaire de fallback pour Firebase sur Windows
class FirebaseWindowsFallback {
  static bool _isInitialized = false;
  static bool _hasError = false;

  /// Initialise Firebase avec fallback pour Windows
  static Future<bool> initializeWithFallback() async {
    if (_isInitialized) return true;
    if (_hasError) return false;

    try {
      // Tentative normale
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isInitialized = true;
      print('✅ Firebase initialisé normalement');
      return true;
    } catch (e) {
      print('❌ Erreur Firebase normale: $e');

      if (Platform.isWindows) {
        return await _tryWindowsFallback();
      } else {
        _hasError = true;
        return false;
      }
    }
  }

  /// Méthode de fallback spécifique à Windows
  static Future<bool> _tryWindowsFallback() async {
    try {
      print('🔄 Tentative de fallback Windows...');

      // Attendre plus longtemps
      await Future.delayed(const Duration(milliseconds: 2000));

      // Essayer avec une configuration simplifiée
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _isInitialized = true;
      print('✅ Firebase initialisé avec fallback Windows');
      return true;
    } catch (e) {
      print('❌ Échec du fallback Windows: $e');

      // Dernière tentative avec délai plus long
      try {
        await Future.delayed(const Duration(milliseconds: 3000));
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        _isInitialized = true;
        print('✅ Firebase initialisé avec délai étendu');
        return true;
      } catch (e2) {
        print('❌ Échec définitif Firebase: $e2');
        _hasError = true;
        return false;
      }
    }
  }

  /// Vérifie si Firebase est disponible
  static bool get isAvailable => _isInitialized && !_hasError;

  /// Vérifie s'il y a eu une erreur
  static bool get hasError => _hasError;
}
