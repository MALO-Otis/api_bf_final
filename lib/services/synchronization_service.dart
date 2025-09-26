/// Service central de synchronisation entre tous les modules
import 'package:flutter/foundation.dart';
// TODO: Fix import when service is available
// import '../screens/controle_de_donnes/services/attribution_service.dart';
import '../screens/extraction/services/attributed_products_service.dart';
import '../screens/filtrage/services/filtered_products_service.dart';
import '../screens/traitement_cire/services/cire_traitement_service.dart';

/// Service centralisé pour synchroniser tous les modules
class SynchronizationService {
  static final SynchronizationService _instance =
      SynchronizationService._internal();
  factory SynchronizationService() => _instance;
  SynchronizationService._internal();

  // Services individuels
  // TODO: Uncomment when AttributionService is available
  // final AttributionService _attributionService = AttributionService();
  final AttributedProductsService _extractionService =
      AttributedProductsService();
  final FilteredProductsService _filtrageService = FilteredProductsService();
  final CireTraitementService _cireService = CireTraitementService();

  bool _isInitialized = false;
  bool _isSyncing = false;

  /// Initialise tous les services
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kDebugMode) {
        print('🔄 SYNCHRONISATION: Initialisation des services...');
      }

      // Initialiser dans l'ordre de dépendance
      // TODO: Uncomment when AttributionService is available
      // await _attributionService.initialiserDonnees();

      // Les autres services dépendent du service d'attribution
      await Future.wait([
        _extractionService.refresh(),
        _filtrageService.refresh(),
        _cireService.refresh(),
      ]);

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ SYNCHRONISATION: Tous les services initialisés');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ SYNCHRONISATION: Erreur d\'initialisation: $e');
      }
      rethrow;
    }
  }

  /// Synchronise tous les modules après un changement
  Future<void> syncAll() async {
    if (_isSyncing) {
      if (kDebugMode) {
        print('⚠️ SYNCHRONISATION: Synchronisation déjà en cours, ignoré');
      }
      return;
    }

    _isSyncing = true;

    try {
      if (kDebugMode) {
        print('🔄 SYNCHRONISATION: Synchronisation complète en cours...');
      }

      // Rafraîchir le service d'attribution en premier
      // TODO: Uncomment when AttributionService is available
      // await _attributionService.initialiserDonnees();

      // Puis synchroniser tous les autres services
      await Future.wait([
        _extractionService.refresh(),
        _filtrageService.refresh(),
        _cireService.refresh(),
      ]);

      if (kDebugMode) {
        print('✅ SYNCHRONISATION: Synchronisation complète terminée');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ SYNCHRONISATION: Erreur de synchronisation: $e');
      }
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  /// Synchronise seulement le module d'extraction
  Future<void> syncExtraction() async {
    if (kDebugMode) {
      print('🔄 SYNCHRONISATION: Rafraîchissement extraction...');
    }
    await _extractionService.refresh();
    if (kDebugMode) {
      print('✅ SYNCHRONISATION: Extraction rafraîchie');
    }
  }

  /// Synchronise seulement le module de filtrage
  Future<void> syncFiltrage() async {
    if (kDebugMode) {
      print('🔄 SYNCHRONISATION: Rafraîchissement filtrage...');
    }
    await _filtrageService.refresh();
    if (kDebugMode) {
      print('✅ SYNCHRONISATION: Filtrage rafraîchi');
    }
  }

  /// Synchronise seulement le module de traitement cire
  Future<void> syncCire() async {
    if (kDebugMode) {
      print('🔄 SYNCHRONISATION: Rafraîchissement traitement cire...');
    }
    await _cireService.refresh();
    if (kDebugMode) {
      print('✅ SYNCHRONISATION: Traitement cire rafraîchi');
    }
  }

  /// Vérifie l'état de synchronisation de tous les modules
  Future<Map<String, dynamic>> getSystemStatus() async {
    try {
      // Obtenir les statistiques de chaque module
      final attributionStats = await _getAttributionStats();
      final extractionStats = await _getExtractionStats();
      final filtrageStats = await _getFiltrageStats();
      final cireStats = await _getCireStats();

      return {
        'last_sync': DateTime.now().toIso8601String(),
        'is_syncing': _isSyncing,
        'modules': {
          'attribution': attributionStats,
          'extraction': extractionStats,
          'filtrage': filtrageStats,
          'cire': cireStats,
        },
        'total_products': attributionStats['total'],
        'health_status': _calculateHealthStatus(
          attributionStats,
          extractionStats,
          filtrageStats,
          cireStats,
        ),
      };
    } catch (e) {
      return {
        'last_sync': DateTime.now().toIso8601String(),
        'is_syncing': _isSyncing,
        'error': e.toString(),
        'health_status': 'error',
      };
    }
  }

  /// Obtient les statistiques du module d'attribution
  Future<Map<String, dynamic>> _getAttributionStats() async {
    try {
      // TODO: Uncomment when AttributionService is available
      // final produits = _attributionService.getTousLesProduits();
      // final attributions = _attributionService.getAttributions();

      // Mock data for now
      final produits = <dynamic>[];
      final attributions = <dynamic>[];

      final produitsConformes = produits.where((p) => p.estConforme).length;
      final produitsControles = produits.where((p) => p.estControle).length;
      final produitsAttribues = produits.where((p) => p.estAttribue).length;

      return {
        'total': produits.length,
        'conformes': produitsConformes,
        'controles': produitsControles,
        'attribues': produitsAttribues,
        'disponibles': produits.length - produitsAttribues,
        'attributions_actives': attributions.length,
        'status': 'active',
      };
    } catch (e) {
      return {
        'total': 0,
        'error': e.toString(),
        'status': 'error',
      };
    }
  }

  /// Obtient les statistiques du module d'extraction
  Future<Map<String, dynamic>> _getExtractionStats() async {
    try {
      final products = await _extractionService.getAttributedProducts();
      final stats = await _extractionService.getStats();

      return {
        'total': products.length,
        'en_attente': stats.enAttente,
        'en_cours': stats.enCours,
        'termines': stats.termines,
        'poids_total': stats.poidsTotal,
        'status': 'active',
      };
    } catch (e) {
      return {
        'total': 0,
        'error': e.toString(),
        'status': 'error',
      };
    }
  }

  /// Obtient les statistiques du module de filtrage
  Future<Map<String, dynamic>> _getFiltrageStats() async {
    try {
      final products = await _filtrageService.getFilteredProducts();
      final stats = _filtrageService.getFilteringStats();

      return {
        'total': products.length,
        'en_attente': stats['enAttente'] ?? 0,
        'en_cours': stats['enCours'] ?? 0,
        'termines': stats['termines'] ?? 0,
        'poids_total': stats['poidsTotal'] ?? 0.0,
        'poids_filtre': stats['poidsFiltre'] ?? 0.0,
        'rendement_moyen': stats['rendementMoyen'] ?? 0.0,
        'status': 'active',
      };
    } catch (e) {
      return {
        'total': 0,
        'error': e.toString(),
        'status': 'error',
      };
    }
  }

  /// Obtient les statistiques du module de traitement cire
  Future<Map<String, dynamic>> _getCireStats() async {
    try {
      final stats = await _cireService.getStats();

      return {
        'total': stats['total'] ?? 0,
        'en_attente': stats['en_attente'] ?? 0,
        'en_cours': stats['en_cours'] ?? 0,
        'termines': stats['termines'] ?? 0,
        'poids_total': stats['poids_total'] ?? 0.0,
        'status': 'active',
      };
    } catch (e) {
      return {
        'total': 0,
        'error': e.toString(),
        'status': 'error',
      };
    }
  }

  /// Calcule l'état de santé général du système
  String _calculateHealthStatus(
    Map<String, dynamic> attribution,
    Map<String, dynamic> extraction,
    Map<String, dynamic> filtrage,
    Map<String, dynamic> cire,
  ) {
    final modules = [attribution, extraction, filtrage, cire];

    // Vérifier s'il y a des erreurs
    if (modules.any((m) => m['status'] == 'error')) {
      return 'error';
    }

    // Vérifier la cohérence des données
    final totalAttribution = attribution['total'] ?? 0;
    final totalExtraction = extraction['total'] ?? 0;
    final totalFiltrage = filtrage['total'] ?? 0;
    final totalCire = cire['total'] ?? 0;

    // Si aucun produit n'est attribué mais qu'il y a des produits dans les modules
    if (totalAttribution == 0 &&
        (totalExtraction > 0 || totalFiltrage > 0 || totalCire > 0)) {
      return 'warning';
    }

    // Vérifier la répartition logique
    final totalAttribues = attribution['attribues'] ?? 0;
    final totalEnProcessus = totalExtraction + totalFiltrage + totalCire;

    if (totalEnProcessus > totalAttribues) {
      return 'warning';
    }

    return 'healthy';
  }

  /// Notifie un changement d'attribution
  Future<void> notifyAttributionChange(String attributionId) async {
    if (kDebugMode) {
      print('📢 NOTIFICATION: Changement d\'attribution $attributionId');
    }
    await syncAll();
  }

  /// Notifie la fin d'un processus d'extraction
  Future<void> notifyExtractionComplete(String productId) async {
    if (kDebugMode) {
      print('📢 NOTIFICATION: Extraction terminée pour $productId');
    }
    // Synchroniser le filtrage car un nouveau produit extrait peut être disponible
    await syncFiltrage();
  }

  /// Notifie la fin d'un processus de filtrage
  Future<void> notifyFiltrageComplete(String productId) async {
    if (kDebugMode) {
      print('📢 NOTIFICATION: Filtrage terminé pour $productId');
    }
    // Pas de synchronisation nécessaire car le filtrage est le dernier processus
  }

  /// Notifie la fin d'un processus de traitement cire
  Future<void> notifyCireTraitementComplete(String productId) async {
    if (kDebugMode) {
      print('📢 NOTIFICATION: Traitement cire terminé pour $productId');
    }
    // Pas de synchronisation nécessaire car le traitement cire est autonome
  }

  /// Force une resynchronisation complète en cas de problème
  Future<void> forceResync() async {
    if (kDebugMode) {
      print('🔄 SYNCHRONISATION: Resynchronisation forcée...');
    }

    _isInitialized = false;
    _isSyncing = false;

    await initialize();

    if (kDebugMode) {
      print('✅ SYNCHRONISATION: Resynchronisation forcée terminée');
    }
  }

  /// Vérifie si le système est prêt
  bool get isReady => _isInitialized && !_isSyncing;

  /// Vérifie si une synchronisation est en cours
  bool get isSyncing => _isSyncing;
}
