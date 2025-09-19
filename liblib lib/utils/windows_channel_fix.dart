import 'dart:io';
import 'package:flutter/foundation.dart';

/// Utilitaires pour résoudre les problèmes de canal sur Windows
class WindowsChannelFix {
  /// Vérifie si on est sur Windows et applique des corrections
  static Future<void> applyWindowsFixes() async {
    if (Platform.isWindows) {
      // Attendre que l'engine soit prêt
      await Future.delayed(const Duration(milliseconds: 300));

      if (kDebugMode) {
        print('🔧 Corrections Windows appliquées');
      }
    }
  }

  /// Retry avec backoff exponentiel pour les opérations critiques
  static Future<T> retryWithBackoff<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(milliseconds: 100),
  }) async {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await operation();
      } catch (e) {
        if (attempt == maxAttempts) rethrow;

        final delay = Duration(
          milliseconds: initialDelay.inMilliseconds * attempt,
        );
        await Future.delayed(delay);
      }
    }
    throw Exception('Max attempts reached');
  }
}
