/// Service pour gérer le traitement direct de la cire
import 'package:flutter/foundation.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart';
import '../../extraction/services/attribution_service.dart';

/// Service pour gérer les produits cire attribués au traitement
class CireTraitementService {
  static final CireTraitementService _instance =
      CireTraitementService._internal();
  factory CireTraitementService() => _instance;
  CireTraitementService._internal();

  // Stockage en mémoire des produits cire attribués au traitement
  final Map<String, ProductControle> _cireProduits = {};
  final AttributionService _attributionService = AttributionService();
  bool _isInitialized = false;

  /// Initialise le service si nécessaire
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _syncWithAttributionService();
      _isInitialized = true;
    }
  }

  /// Récupère tous les produits cire attribués pour traitement
  Future<List<ProductControle>> getCireProduits({
    String? siteTraitement,
  }) async {
    // S'assurer que le service est initialisé
    await _ensureInitialized();

    var products = _cireProduits.values.toList();

    // Filtrer par site si spécifié
    if (siteTraitement != null) {
      products = products
          .where((p) => p.siteOrigine
              .toLowerCase()
              .contains(siteTraitement.toLowerCase()))
          .toList();
    }

    // Trier par date d'attribution (plus récent en premier)
    products.sort((a, b) => b.dateReception.compareTo(a.dateReception));

    if (kDebugMode) {
      print(
          '🟤 Cire: ${products.length} produits cire récupérés pour traitement');
    }

    return products;
  }

  /// Synchronise avec le service d'attribution pour les produits CIRE
  Future<void> _syncWithAttributionService() async {
    try {
      // Pour maintenant, on génère des données de test
      // TODO: Implémenter la synchronisation réelle quand les services seront disponibles
      _generateMockCireProducts();

      if (kDebugMode) {
        print(
            '✅ Synchronisation cire terminée: ${_cireProduits.length} produits');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur synchronisation cire: $e');
      }
    }
  }

  /// Génère des produits cire de test
  void _generateMockCireProducts() {
    _cireProduits.clear();

    // Simuler quelques produits cire pour les tests
    for (int i = 1; i <= 5; i++) {
      final produit = ProductControle(
        id: 'CIRE_$i',
        codeContenant: 'C_CIRE_$i',
        dateReception: DateTime.now().subtract(Duration(days: i)),
        producteur: 'Producteur $i',
        village: 'Village $i',
        commune: 'Commune $i',
        quartier: 'Quartier $i',
        nature: ProductNature.cire,
        typeContenant: 'Pot cire',
        numeroContenant: 'NUM_$i',
        poidsTotal: 10.0 + i,
        poidsMiel: 0.0, // Pas de miel dans la cire
        qualite: 'Cire standard',
        predominanceFlorale: 'Mixte',
        estConforme: true,
        dateControle: DateTime.now().subtract(Duration(days: i - 1)),
        siteOrigine: 'Site $i',
        collecteId: 'COLLECTE_$i',
        typeCollecte: 'Directe',
        dateCollecte: DateTime.now().subtract(Duration(days: i + 1)),
      );

      _cireProduits[produit.id] = produit;
    }
  }

  /// Force la synchronisation avec le module de contrôle
  Future<void> refresh() async {
    _cireProduits.clear();
    _isInitialized = false;
    await _ensureInitialized();

    if (kDebugMode) {
      print(
          '🔄 Rafraîchissement cire terminé: ${_cireProduits.length} produits cire');
    }
  }

  /// Démarre le traitement d'un produit cire
  Future<bool> demarrerTraitement(String productId) async {
    final product = _cireProduits[productId];
    if (product == null) {
      throw Exception('Produit cire non trouvé: $productId');
    }

    // Marquer comme en cours de traitement
    _cireProduits[productId] = product.copyWith(
      statutControle: 'en_traitement',
    );

    if (kDebugMode) {
      print(
          '🚀 Traitement cire démarré pour le produit ${product.codeContenant}');
    }

    return true;
  }

  /// Termine le traitement d'un produit cire
  Future<bool> terminerTraitement(
    String productId, {
    double? poidsTraite,
    String? observations,
  }) async {
    final product = _cireProduits[productId];
    if (product == null) {
      throw Exception('Produit cire non trouvé: $productId');
    }

    // Marquer comme traité
    _cireProduits[productId] = product.copyWith(
      statutControle: 'traite',
      observations: observations,
    );

    if (kDebugMode) {
      print('✅ Traitement cire terminé pour ${product.codeContenant}');
      if (poidsTraite != null) {
        print('📦 Poids traité: ${poidsTraite.toStringAsFixed(2)} kg');
      }
    }

    return true;
  }

  /// Récupère un produit par son ID
  Future<ProductControle?> getProduct(String productId) async {
    await _ensureInitialized();
    return _cireProduits[productId];
  }

  /// Récupère les statistiques des produits cire
  Future<Map<String, dynamic>> getStats() async {
    await _ensureInitialized();

    final products = _cireProduits.values.toList();
    final enAttente =
        products.where((p) => p.statutControle == 'valide').length;
    final enCours =
        products.where((p) => p.statutControle == 'en_traitement').length;
    final termines = products.where((p) => p.statutControle == 'traite').length;
    final poidsTotal = products.fold(0.0, (sum, p) => sum + p.poidsTotal);

    return {
      'total': products.length,
      'en_attente': enAttente,
      'en_cours': enCours,
      'termines': termines,
      'poids_total': poidsTotal,
    };
  }
}
