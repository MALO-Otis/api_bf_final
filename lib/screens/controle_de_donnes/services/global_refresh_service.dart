// Service de notification globale pour rafraîchir les pages après mise à jour
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service singleton pour gérer les notifications de mise à jour globales
class GlobalRefreshService {
  static final GlobalRefreshService _instance =
      GlobalRefreshService._internal();
  factory GlobalRefreshService() => _instance;
  GlobalRefreshService._internal();

  // Stream controller pour notifier les changements de collectes
  final StreamController<String> _collecteUpdateController =
      StreamController<String>.broadcast();

  // Stream controller pour notifier les changements de contrôles qualité
  final StreamController<String> _qualityControlUpdateController =
      StreamController<String>.broadcast();

  // Streams publics pour écouter les changements
  Stream<String> get collecteUpdatesStream => _collecteUpdateController.stream;
  Stream<String> get qualityControlUpdatesStream =>
      _qualityControlUpdateController.stream;

  /// Notifie qu'une collecte a été mise à jour
  void notifyCollecteUpdate(String collecteId) {
    if (kDebugMode) {
      print(
          '📢 GlobalRefreshService: Notification mise à jour collecte $collecteId');
    }
    _collecteUpdateController.add(collecteId);
  }

  /// Notifie qu'un contrôle qualité a été créé/modifié
  void notifyQualityControlUpdate(String containerCode) {
    if (kDebugMode) {
      print(
          '📢 GlobalRefreshService: Notification mise à jour contrôle $containerCode');
    }
    _qualityControlUpdateController.add(containerCode);
  }

  /// Notifie une mise à jour générale (force le rafraîchissement de toutes les pages)
  void notifyGlobalUpdate() {
    if (kDebugMode) {
      print('📢 GlobalRefreshService: Notification mise à jour globale');
    }
    _collecteUpdateController.add('GLOBAL_UPDATE');
    _qualityControlUpdateController.add('GLOBAL_UPDATE');
  }

  /// MÉTHODE DE DEBUG : Force une mise à jour pour tester le système
  void debugForceRefresh() {
    if (kDebugMode) {
      print('🔧 DEBUG: Forçage d\'une mise à jour globale');
      notifyGlobalUpdate();
    }
  }

  /// Dispose les streams
  void dispose() {
    _collecteUpdateController.close();
    _qualityControlUpdateController.close();
  }
}
